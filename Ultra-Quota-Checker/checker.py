import os
import requests
import configparser
from datetime import datetime
import logging
import sys
import subprocess

THRESHOLD = 90
# quota exits 1 once any limit is exceeded, and still prints the usage table
quota_over_limit_exit = 1
kib_per_unit = {'K': 1, 'M': 1024, 'G': 1024 ** 2, 'T': 1024 ** 3}


def to_kib(size):
    # quota -s sizes look like "512M", with a trailing "*" once over the soft limit
    size = size.rstrip('*')
    return int(size[:-1]) * kib_per_unit[size[-1]]


class QuotaCheck:
    def __init__(self):
        self.config = configparser.ConfigParser()
    
    def get_torrent_clients(self, path):
        torrent_clients = []
        remove_apps = ['backup', 'nginx']
        all_apps = os.listdir(path)
        installed_apps = list(set(all_apps).difference(remove_apps))
        docker_apps = list(set(all_apps).intersection(installed_apps))
        remove_config = ['systemd']
        all_configs = os.listdir(path)
        all_torrent_clients = list(set(all_configs).difference(remove_config))
        if "rtorrent" in all_torrent_clients:
            torrent_clients.append('rtorrent')
        if "deluge" in all_torrent_clients:
            torrent_clients.append('deluge')
        if "qbittorrent-nox" in all_torrent_clients:
            torrent_clients.append('qbittorrent')
        if "transmission-daemon" in all_torrent_clients:
            torrent_clients.append('transmission')
        if "nzbget" in docker_apps:
            torrent_clients.append('nzbget')
        if "sabnzbd" in docker_apps:
            torrent_clients.append('sabnzbd')
        return torrent_clients
    
    def get_quota_value(self):
        try:
            process = subprocess.Popen(["quota", "-s"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                output, error = process.communicate(timeout=10)  # Set a timeout value in seconds
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()
                logging.error("Timeout expired while executing 'quota' command.")
                return None, None

            if process.returncode in (0, quota_over_limit_exit):
                # two header lines, then "/dev/sdb1  512M  4000G  4100G ..." (used, soft limit, hard limit)
                quota = output.decode().split()
                if len(quota) < 20:
                    logging.error(f"Unexpected 'quota -s' output (exit {process.returncode}): {output.decode()!r} {error.decode()!r}")
                    return None, None
                return to_kib(quota[17]), to_kib(quota[19])
            else:
                logging.error(f"Failed to execute 'quota' command. Error: {error.decode()}")
                return None, None
        except Exception as e:
            logging.error(f"Error in get_quota_value: {str(e)}")
            return None, None

    
    def quota_percentage(self, used_kib, limit_kib):
        return round(used_kib / limit_kib * 100, 1)
    
    def compare_quota(self, threshold, quota_percent):
        return threshold < quota_percent
    
    def update_discord_value(self, value):
        self.config.read(config_file)
        self.config.set('option', 'discord_notification', value)
        with open(config_file, 'w') as configfile:
            self.config.write(configfile)
    
    def discord_notifications_accepter(self):
        while True:
            web_url = input("Please enter your Discord Web Hook URL Here:")
            response = requests.get(web_url)
            if response.ok:
                return web_url
            else:
                print("Wrong Web Hook URL. Please enter the correct one.")
        
    def discord_notification(self, webhook, alert, discord, choice):
        if alert and discord == "True":
            if choice.lower() in ["yes", "y"]:
                content = "```You are going to hit your disk quota. Please delete some data or upgrade your service to a larger plan. The disk is almost full. Commands to stop torrent clients and Usenet downloaders executed. :)```"
            else:
                content = "```You are going to hit your disk quota. Please delete some data or upgrade your service to a larger plan.```"
            
            data = {
                "content": content
            }
            
            response = requests.post(webhook, json=data)
            if response.ok:
                self.update_discord_value("False")
                return True
            else:
                print("Failed to send Discord notification.")
        return False
    
    def stop_torrent_clients(self, torrent_clients):
        if torrent_clients:
            for client in torrent_clients:
                try:
                    subprocess.run(["app-{}".format(client), "stop"], capture_output=True, text=True, timeout=10, check=True)
                except subprocess.CalledProcessError as e:
                    logging.error(f"Failed to stop torrent client {client}. Error: {e.stderr}")
                except subprocess.TimeoutExpired:
                    logging.error(f"Timeout expired while stopping torrent client {client}.")
                except Exception as e:
                    logging.error(f"Error in stop_torrent_clients: {str(e)}")
    
    def torrent_stopping_opt(self):
        opt = input("Do you wish to stop torrent clients on hitting the disk limit? (yes/no): ")
        return opt.lower()
    
    def create_config_file(self, url, opt):
        self.config.add_section('Webhook')
        self.config.set('Webhook', 'value', url)
        self.config.add_section('option')
        self.config.set('option', 'stop_torrentclient', opt)
        self.config.set('option', 'Discord_notification', "True")
        with open(config_file, 'w') as configfile:
            self.config.write(configfile)
    
    def read_config_file(self):
        try:
            self.config.read(config_file)
            if not self.config.has_section('Webhook'):
                error_msg = "Webhook section not found in config file."
                logging.error(error_msg)
                sys.exit(1)
            url = self.config.get('Webhook', 'value')
            value = self.config.get('option', 'stop_torrentclient')
            discord = self.config.get('option', 'Discord_notification')
            return url, value, discord
        except configparser.NoOptionError as e:
            error_msg = f"Option not found in section: {e.section} - {e.option}"
            logging.error(error_msg)
        except Exception as e:
            error_msg = str(e)
            logging.error(error_msg)


if __name__ == '__main__':
    work_dir = os.path.expanduser("~")
    config_path = os.path.join(work_dir, 'bin')
    config_file = os.path.join(work_dir, 'scripts', 'Ultra-Quota-Checker', 'config.ini')
    log_file = os.path.join(work_dir, 'scripts', 'Ultra-Quota-Checker', 'quota.log')
    base_directory = os.path.dirname(os.path.abspath(__file__))
    logging.basicConfig(filename=os.path.join(base_directory, "logfilename.log"), level=logging.WARNING)

    checker = QuotaCheck()
    check = os.path.exists(config_file)
    if not check:
        url = checker.discord_notifications_accepter()
        opt = checker.torrent_stopping_opt()
        checker.create_config_file(url, opt)
    else:
        url, value, discord = checker.read_config_file()
        used_kib, limit_kib = checker.get_quota_value()
        if used_kib is None:
            sys.exit(1)
        quota_percent = checker.quota_percentage(used_kib, limit_kib)
        alert = checker.compare_quota(THRESHOLD, quota_percent)
        if not alert:
            checker.update_discord_value("True")
        checker.discord_notification(url, alert, discord, value)
        if alert and value.lower() == "yes":
            torrent_clients = checker.get_torrent_clients(config_path)
            checker.stop_torrent_clients(torrent_clients)
