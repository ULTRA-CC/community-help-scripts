import os
import requests
import re
import configparser
from datetime import datetime
import logging

work_dir = os.getcwd()
config_path = work_dir + '/bin'
#base variable
config = configparser.ConfigParser()
config_file = '{}/scripts/quota_check/config.ini'.format(work_dir)
log_file = '{}/scripts/quota_check/config.ini'.format(work_dir)
threshold = 90
logs_file = '{}/scripts/quota_check/quota.log'.format(work_dir)
all_apps = ['nzbget','sabnzbd']
now = datetime.now()
current_time = now.strftime("%H:%M:%S")
class Quota_check():
    """
    Get all torrent client installed on service
    """
    
    def get_torrent_clients(self, path):
        torrent_client = []
        remove_apps = ['backup', 'nginx']
        all_apps = os.listdir(path)
        installed_apps = list(set(all_apps).difference(remove_apps))
        docker_app = list(set(all_apps).intersection(installed_apps))
        remove_config = ['systemd']
        all_configs = os.listdir(path)
        all_torrent_clients = list(set(all_configs).difference(remove_config))
        if "rtorrent" in all_torrent_clients:
            torrent_client.append('rtorrent')
        if "deluge" in all_torrent_clients:
            torrent_client.append('deluge')
        if "qbittorrent-nox" in all_torrent_clients:
            torrent_client.append('qbittorrent')
        if "transmission-daemon" in all_torrent_clients:
            torrent_client.append('transmission')
        if "nzbget" in docker_app:
            torrent_client.append('nzbget')
        if "sabnzbd" in docker_app:
            torrent_client.append('sabnzbd')
        return torrent_client
    
    def get_quota_value(self):
       Quota = os.popen("quota -s 2>/dev/null").read().split() # example 133M
       Used_Quota_Value = re.sub("[^0-9]", "", Quota[17]) # output 133
       Used_Quota_metric = re.sub("[^A-Z]", "", Quota[17]) # M
       Quota_Limit = re.sub("[^0-9]", "", Quota[19]) # quota limit value
       return Used_Quota_metric, Used_Quota_Value, Quota_Limit
    
    def quota_percentage(self,Used_Quota_metric,Used_Quota_Value,Quota_Limit):
        Used_Quota_Value = float(Used_Quota_Value)
        Quota_Limit = float(Quota_Limit)
        if Used_Quota_metric == "G":
            quota_percent = (Used_Quota_Value / Quota_Limit) * 100
        if Used_Quota_metric == "M":
            Used_Quota_Value = Used_Quota_Value * 0.1027
            quota_percent = (Used_Quota_Value/Quota_Limit) * 100
        else:
            pass
        return round(quota_percent,1)
    
    def compare_quota(self,threshold,quota_percent):
        if threshold < quota_percent:
            return True
        else:
            return False


    """
    Discord functions are below
    """
    def update_Discord_value(self,value):
        config.read(config_file)
        config.set('option', 'discord_notification', value)
        with open(config_file, 'w') as configfile:
            config.write(configfile)
    
    def Discord_Notifications_Accepter(self):
        while True:
            Web_Url = input("Please enter your Discord Web Hook Url Here:")
            response = requests.get(Web_Url)
            if response.status_code == 200:
                return Web_Url
            else :
                print("Wrong Web Hook Url please Enter correct one..")
        
    def Discord_notification_(self,webhook,alert,discord,choice):
        if alert:
            if discord == "True":
                if choice == "yes" or choice == "Yes" or choice == "YES":
                    data = {
                    "content" : "```You are going to hit your disk quota please delete some data or upgrade your service to larger plan, disk is almost filled. Commands to stop torrent clients and usenet downloaders executed. :)```"}
                   
                else:
                    data = {
                    "content" : "```You are going to hit your disk quota please delete some data or upgrade your service to larger plan :)```",
                        }
                                                  
                response = requests.post(webhook, json=data)
                # with open(logs_file,"+w") as f:
                #     f.write("\nTIME:"+current_time+"\n")
                #     f.write("\nDiscord response: {}\n".format(response.raise_for_status()))
                self.update_Discord_value("False")
        else:
            pass
            
    def stop_torrent_client(self,torrent_client):
        if len(torrent_client) != 0:
            for i in torrent_client:
                os.system("app-{} stop".format(i))
        else:
            pass
    
    
        
    def torrent_stopping_opt(self):
        opt = input("Do you wish to stop torrent client on hitting disk limit ? (yes/no): ")
        return opt
        
    def create_config_file(self, url,opt):
        config.add_section('Webhook')
        config.set('Webhook', 'value', url)
        config.add_section('option')
        config.set('option', 'stop_torrentclient', opt)
        config.set('option', 'Discord_notification', "True")
        with open(config_file, '+w') as configfile:
            config.write(configfile)
    
    def read_config_file(self):
        config.read(config_file)
        url = config["Webhook"]["value"]
        val = config["option"]["stop_torrentclient"]
        discord = config["option"]["Discord_notification"]
        return url, val , discord

checker = Quota_check()
if __name__ == '__main__':
    check = os.path.exists(config_file)
    if check == False:
        url = checker.Discord_Notifications_Accepter()
        opt = checker.torrent_stopping_opt()
        checker.create_config_file(url,opt)
    else:
        url,value , discord = checker.read_config_file()
        Used_Quota_metric, Used_Quota_Value, Quota_Limit = checker.get_quota_value()
        quota_percent = checker.quota_percentage(Used_Quota_metric, Used_Quota_Value, Quota_Limit)
        alert = checker.compare_quota(threshold,quota_percent)
        checker.Discord_notification_(url, alert,discord,value)
        if not alert:
            checker.update_Discord_value("True")
        torrent_client = checker.get_torrent_clients(config_path)
        if value == "yes" or value == "Yes" or value == "YES":
            if alert:
                if discord == "True":
                    checker.stop_torrent_client(torrent_client)
        else:
            pass