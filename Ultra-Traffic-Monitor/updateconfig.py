import os 
from subprocess import check_output, check_call
import requests
from datetime import datetime
import configparser
import logging

#base variable
config = configparser.ConfigParser()
logging.basicConfig(filename="logfilename.log", level=logging.INFO)

#path
path = os.getcwd()
base_dir = '{}/scripts/Ultra-Traffic-Monitor'.format(path)
Discord_WebHook_File = '{}/scripts/Ultra-Traffic-Monitor/discord.txt'.format(path)
traffic_file = '{}/scripts/Ultra-Traffic-Monitor/warning.txt'.format(path)
config_file = '{}/scripts/Ultra-Traffic-Monitor/conf.ini'.format(path)
now = datetime.now()
current_time = now.strftime("%H:%M:%S")

class traffic_monitor():
    def update_thre_val(self,val):
        config.read(config_file)
        config.set('threshold', 'value', val)
        with open(config_file, 'w') as configfile:
            config.write(configfile)

    def update_torrent_val(self,val):
        config.read(config_file)
        config.set('option', 'stop_torrentclient', val)
        with open(config_file, 'w') as configfile:
            config.write(configfile)

traffic = traffic_monitor()
if __name__ == '__main__':
    print("Choose below given option if you want to update config values")
    print("1. Update your traffic threshold value")
    print("2. Change torrent client stop option (yes/no")
    choice = input("Please enter your choice: ")
    if choice == "1":
        threshold = input("Please enter the threshold value(example 50.0): ")
        traffic.update_thre_val(threshold)
    if choice == "2":
        opt = input("Please enter yes if you want to stop torrent client and no if you don't want (yes/no):")
        traffic.update_torrent_val(opt)
