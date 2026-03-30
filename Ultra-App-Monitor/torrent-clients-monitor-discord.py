import os
import time
import datetime
import os 
import sys
import logging 
from discord_webhook import DiscordWebhook, DiscordEmbed
"""
Data and time to store restart time of application
"""

now = datetime.datetime.now()
current_time = now.strftime("%Y-%m-%d %H:%M:%S")

work_dir = os.getcwd()
log_file = '{}/scripts/Ultra-App-Monitor/apps-monitor-local.log'.format(work_dir)
torrent_client_list = ['deluge', 'transmission', 'qbittorrent', 'rtorrent']
apps_path = work_dir + '/.apps'
config_path = work_dir + '/bin'
systemd_path = work_dir + '/.config/systemd/user/'
Discord_WebHook_File = '{}/scripts/Ultra-App-Monitor/discord.txt'.format(work_dir)
torrent_client = []
wehook = ""

class app_monitor():
    
    def discord_notfication(self,webhook,appname,status,color,fail=False):
        webhook = DiscordWebhook(url=webhook, username="App monitor")
        embed = DiscordEmbed(title='Application Name - Status',description="Talk about what app monitor did restart or upgrade the app and mention if it failed", color=color)
        embed.set_author(name='OptimusPrime', icon_url='https://i.pinimg.com/564x/2c/b7/c1/2cb7c1890090030f4b59c12f4b3880f5--optimus-prime-wallpaper-transformers-prime-optimus.jpg')
        embed.set_timestamp()
        embed.add_embed_field(name="Application Name:", value=appname)
        embed.add_embed_field(name="Application Status:", value=status,inline=False)
        if fail:
            embed.add_embed_field(name="Script unable to restart application {}".format(appname), value="https://my.ultraseedbox.com/supporttickets.php",inline=False)
        webhook.add_embed(embed)
        response = webhook.execute()
    
    def Discord_Notifications_Accepter(self):
        Web_Url = input("Please enter your Discord Web Hook Url Here:")
        with open(Discord_WebHook_File, '+w') as f:
            f.write(Web_Url)
        f.close()

    def Discord_WebHook_Reader(self):
        log_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logfile.log")
        logging.basicConfig(filename=log_file_path, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
        if os.path.exists(Discord_WebHook_File) and os.path.getsize(Discord_WebHook_File) > 0:
            with open(Discord_WebHook_File, 'r') as f:
                return f.read()
        else:
            logging.warning("The Discord WebHook file is empty or doesn't exist.")
            sys.exit(1)
    
    def get_torrent_clients(self, path):
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

    def Monitor_Webserver(self):
        status = os.popen("ps aux | grep -i nginx |grep -v grep")
        count = len(status.readlines())
        if count <= 0:
            os.system("app-nginx restart")
            
    def torrent_client_fixing(self, apps,webhook):
        for i in apps:
            status = os.popen("ps aux | grep -i {}".format(i)).read()
            count = len(status.splitlines())
            if count <= 2:
                os.system("app-{} restart".format(i))
                self.discord_notfication(webhook,i,"App Restarted","50C878")
            else:
                pass
            time.sleep(2)
            status = os.popen("ps aux | grep -i {}".format(i)).read()
            count = len(status.splitlines())
            if count <= 2:
                os.system("app-{} repair".format(i))
                self.discord_notfication(webhook,i,"App Repaired","50C878")
            time.sleep(2)
            status = os.popen("ps aux | grep -i {}".format(i)).read()
            count = len(status.splitlines())
            if count <= 2:
               self.discord_notfication(webhook,i,"Failed","C70039",True)


monitor = app_monitor()
if __name__ == '__main__':
    check = os.path.exists(Discord_WebHook_File)
    if check:
        webhook = monitor.Discord_WebHook_Reader()
    # check webserver is running or not
        monitor.Monitor_Webserver()
        monitor.get_torrent_clients(config_path)
    # monitor torrent client
        monitor.torrent_client_fixing(torrent_client,webhook)
    else:
        monitor.Discord_Notifications_Accepter()
