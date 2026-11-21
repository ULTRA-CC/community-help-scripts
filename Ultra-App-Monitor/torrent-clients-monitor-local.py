import os
import time
import datetime
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

torrent_client = []
# kernel process names (cut to 15 chars); rtorrent 0.16 renames itself rtorrent-main
process_names = {
    'deluge': 'deluged',
    'transmission': 'transmission-da',
    'qbittorrent': 'qbittorrent-nox',
    'rtorrent': 'rtorrent|rtorrent-main',
}


class app_monitor():
    
    
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
            
    def is_running(self, app):
        # exact name match, so the *_pub wrapper units no longer count as the client
        return os.system("pgrep -u {} -x '{}' > /dev/null".format(os.getuid(), process_names[app])) == 0

    def torrent_client_fixing(self, apps):
        for i in apps:
            if not self.is_running(i):
                os.system("app-{} restart".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been RESTARTED'.format(i) + "\n")
                    os.system("clear")
            else:
                pass
            time.sleep(2)
            if not self.is_running(i):
                os.system("app-{} repair".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been repair'.format(i) + "\n")
                    os.system("clear")
            time.sleep(2)
            if not self.is_running(i):
                with open(log_file, "a") as f:
                    f.write(
                        "\nScript is unable to FIX your {} so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n".format(i))


monitor = app_monitor()
if __name__ == '__main__':
    # check webserver is running or not
    monitor.Monitor_Webserver()
    monitor.get_torrent_clients(config_path)
    # monitor torrent client
    monitor.torrent_client_fixing(torrent_client)
