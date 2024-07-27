import os
import requests
from subprocess import check_output, TimeoutExpired
from datetime import datetime
import configparser
import logging
import sys
import subprocess

class TrafficMonitor:

    def __init__(self):
        self.path = os.getcwd()
        self.base_dir = os.path.join(self.path, 'scripts', 'Ultra-Traffic-Monitor')
        self.Discord_WebHook_File = os.path.join(self.base_dir, 'discord.txt')
        self.traffic_file = os.path.join(self.base_dir, 'warning.txt')
        self.config_file = os.path.join(self.base_dir, 'conf.ini')
        self.now = datetime.now()
        self.current_time = self.now.strftime("%H:%M:%S")
        logging.basicConfig(filename=os.path.join(self.path, "logfilename.log"), level=logging.WARNING)

    def get_traffic_percent(self):
        try:
            process = subprocess.Popen(["app-traffic", "info"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            try:
                output, error = process.communicate(timeout=10)
                if process.returncode == 0:
                    traffic_percent = float(output.decode("utf-8").split()[18].replace("%", ""))
                    return traffic_percent
                else:
                    logging.error(f"Command 'app-traffic info' failed with return code {process.returncode}. Error: {error.decode()}")
                    return None
            except subprocess.TimeoutExpired:
                logging.error("Command execution timed out. Terminating process.")
                process.terminate()
                process.wait()
                return None
        except Exception as e:
            logging.error(f"Error in get_traffic_percent: {str(e)}")
            return None


        

    def check_traffic(self, traffic_percent, threshold):
        return traffic_percent <= threshold

    def check_installed_torrent_clients(self):
        installed_torrent_clients = ['qBittorrent', 'rtorrent', 'deluge', 'transmission-daemon']
        torrent_clients = [client for client in installed_torrent_clients if os.path.exists(f"{self.path}/.config/{client}")]
        
        for client in torrent_clients:
            try:
                process = subprocess.Popen([f"app-{client}", "stop"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                try:
                    output, error = process.communicate(timeout=10)
                    if process.returncode != 0:
                        logging.error(f"Failed to stop torrent client {client}. Error: {error.decode()}")
                except subprocess.TimeoutExpired:
                    logging.error(f"Timeout expired while stopping torrent client {client}. Terminating process.")
                    process.terminate()
                    process.wait()
                    process.kill(9)
            except Exception as e:
                logging.error(f"Error in check_installed_torrent_clients: {str(e)}")

        return True


    def discord_notifications_accepter(self):
        while True:
            web_url = input("Please enter your Discord Web Hook URL here:")
            response = requests.get(web_url)
            if response.status_code == 200:
                with open(self.Discord_WebHook_File, 'w') as f:
                    f.write(web_url)
                break
            else:
                print("Wrong Web Hook URL. Please enter the correct one.")

    def discord_webhook_reader(self):
        with open(self.Discord_WebHook_File, 'r') as f:
            return f.read()

    def discord_notification(self, webhook):
        data = {
            "content": '**You have hit your traffic limit** :)'
        }
        response = requests.post(webhook, json=data)

    def create_config_file(self, threshold, opt):
        config = configparser.ConfigParser()
        config.add_section('threshold')
        config.set('threshold', 'value', threshold)
        config.add_section('option')
        config.set('option', 'stop_torrentclient', opt)
        config.add_section('discord')
        config.set('discord', 'discord_notification', "True")
        with open(self.config_file, 'w') as configfile:
            config.write(configfile)

    def update_discord_value(self, value):
        config = configparser.ConfigParser()
        config.read(self.config_file)
        config.set('discord', 'discord_notification', value)
        with open(self.config_file, 'w') as configfile:
            config.write(configfile)

    def read_config_file(self):
        config = configparser.ConfigParser()
        config.read(self.config_file)
        try:
            threshold = float(config.get('threshold', 'value'))
            val = config.get('option', 'stop_torrentclient')
            discord = config.get('discord', 'discord_notification')
            return threshold, val, discord
        except (configparser.NoSectionError, configparser.NoOptionError) as e:
            error_msg = f"Error reading config file: {e}"
            logging.error(error_msg)
            sys.exit(1)

    def create_logs(self):
        logging.basicConfig(filename=os.path.join(self.path, "logfilename.log"), level=logging.INFO)
        logging.warning(f"TIME {self.current_time}: You have hit your traffic limit")

if __name__ == '__main__':
    traffic = TrafficMonitor()
    check = os.path.exists(traffic.config_file)

    if not check:
        print("Please select the desired option from below\n")
        print("1. If you need notification on Discord when you hit the traffic limit")
        print("2. If you need notification in a text file at ~/scripts/Ultra-Traffic-Monitor/")
        
        choice = input("Please enter your choice: ")
        
        if choice == "1":
            traffic.discord_notifications_accepter()
        elif choice == "2":
            pass

        threshold = input("Please enter the percentage at which you want a notification (e.g., 20.0 or 35.0): ")
        option = input("Do you want to stop torrent clients if the traffic threshold is hit? (yes/no): ")
        
        traffic.create_config_file(threshold, option)
    else:
        status = os.path.exists(traffic.Discord_WebHook_File)

        if status:
            traffic_percent = traffic.get_traffic_percent()
            threshold, C, discord = traffic.read_config_file()
            
            val = traffic.check_traffic(traffic_percent, threshold)

            if val:
                if discord == "True":
                    webhook = traffic.discord_webhook_reader()
                    traffic.discord_notification(webhook)
                    traffic.update_discord_value("False")

                    if C == "yes":
                        traffic.check_installed_torrent_clients()
            else:
                traffic.update_discord_value("True")
        else:
            traffic_percent = traffic.get_traffic_percent()
            threshold, C = traffic.read_config_file()
            val = traffic.check_traffic(traffic_percent, threshold)

            if val:
                traffic.create_logs()

                if C == "yes":
                    traffic.check_installed_torrent_clients()
