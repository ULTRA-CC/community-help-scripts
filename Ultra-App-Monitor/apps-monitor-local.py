import os
import time
import datetime
import requests
import socket
"""
Data and time to store restart time of application
"""

now = datetime.datetime.now()
current_time = now.strftime("%Y-%m-%d %H:%M:%S")
"""
Variable for location log files
"""
work_dir = os.getcwd()
log_file = '{}/scripts/Ultra-App-Monitor/apps-monitor-local.log'.format(work_dir)
torrent_client_list = ['deluge', 'transmission', 'qbittorrent', 'rtorrent']
apps_path = work_dir + '/.apps'
config_path = work_dir + '/bin'
systemd_path = work_dir + '/.config/systemd/user/'


"""
List of apps installed on user's service
"""

docker_app = []
torrent_client = []
mysql_apps = []
arr_apps = []
second_verify_app = []


"""
List of all application provide by us
"""
all_apps = ['airsonic', 'couchpotato', 'jackett', 'medusa', 'ombi', 'pydio', 'radarr', 'resilio', 'transmission', 'deluge',
            'jdownloader2','mylar3','pyload', 'rapidleech', 'rtorrent', 'ubooquity', 'autodl', 'deluge',
            'jellyfin', 'nextcloud', 'overseerr', 'sonarr', 'znc', 'bazarr', 'emby', 'lazylibrarian', 'plex', 'rapidleech',
            'sabnzbd', 'syncthing', 'btsync', 'filebot', 'lidarr', 'nzbget', 'readarr', 'sickbeard', 'tautulli',
            'filebrowser', 'mariadb', 'nzbhydra2', 'prowlarr', 'qbittorrent', 'requestrr', 'sickchill','autobrr','jellyseerr' ]

sql_apps = ['mariadb', 'filebrowser', 'nextcloud', 'thelounge']

second_instance = ['radarr2', 'sonarr2', 'lidarr2', 'prowlarr2',
                   'whisparr2', 'bazarr2', 'readarr2', 'autobrr', 'navidrome']

second_instance_service = ['autobrr.service', 'navidrome.service', 'prowlarr.service', 'rclone-vfs.service', 'xteve.service',
                           'lidarr.service', 'radarr.service','bazarr.service', 'whisparr.service', 'sonarr.service', 'rclone-normal.service', 'mergerfs.service', 'proftpd.service']

arr_apps_list = ['readarr', 'prowlarr', 'radarr', 'sonarr', 'bazarr', 'lidarr']

"""
Class app_monitor is decalared below with all its functions

"""
try:
    username = os.getlogin()
except:
    username = "Unknown"

# hostname = socket.gethostname()
hostname = socket.getfqdn()

class app_monitor():

    """
    SystemD verification and monitor

    """

    def system_check(self, apps):
        status1 = os.popen("systemctl --user status | grep 'State:'").read()
        status1 = status1.split(":")[1].replace(' ', '').replace("\n","")
        if status1 == "running":
            pass
        if status1 == "degraded":
            os.system("systemctl --user reset-failed")
        else:
            os.system("systemctl --user reset-failed")
        if apps in second_verify_app:
            status = os.popen(
                "systemctl --user is-failed {}.service".format(apps)).read()
            staus = status.replace("\n", "")
            if staus == "inactive":
                return False
            if staus == "active":
                return True
            else:
                pass

    def systemD_verify_list(self):
        second_arr_apps = []
        all_systemd_files = os.listdir(systemd_path)
        for i in all_systemd_files:
            second_verify_app.append(i.split(".")[0])

    def system_monitor(self):
        all_systemd_files = os.listdir(systemd_path)
        for i in all_systemd_files:
            if i in second_instance_service:
                status = os.popen(
                    "systemctl --user is-failed {}".format(i)).read()
                staus = status.replace("\n", "")
                if staus == "inactive":
                    os.system("systemctl --user restart {}".format(i))
                if staus == "active":
                    pass
            else:
                pass

    """
    ##################################################################
    #These below given function will get all apps intalled on service#
    ##################################################################
    """

    def get_docker_apps(self, path):
        docker_app = []
        special_app = []
        remove_apps = ['backup', 'nginx']
        all_apps = os.listdir(path)
        installed_apps = list(set(all_apps).difference(remove_apps))
        docker_app = list(set(all_apps).intersection(installed_apps))
        for s in sql_apps:
            if s in docker_app:
                docker_app.remove(s)
            else:
                pass
        for j in second_instance:
            if j in docker_app:
                docker_app.remove(j)
            else:
                pass
        for w in arr_apps_list:
            if w in docker_app:
                docker_app.remove(w)
            else:
                pass
        if "wireguard" in all_apps:
            docker_app.remove("wireguard")
        if "overseerr" in all_apps:
            docker_app.remove("overseerr")
            special_app.append("overseerr")
        if "jdownloader2" in all_apps:
            docker_app.remove("jdownloader2")
            special_app.append("jdownloader2")
        if "syncthing" in all_apps:
            docker_app.remove("syncthing")
            special_app.append("syncthing")
        if "resilio" in all_apps:
            docker_app.remove("resilio")
            special_app.append("resilio")
        if "jellyseerr" in all_apps:
            docker_app.remove("jellyseerr")
            special_app.append("jellyseerr")
        if "seerr" in all_apps:
            docker_app.remove("seerr")
            special_app.append("seerr")
        if "flaresolverr" in all_apps:
            docker_app.remove("flaresolverr")
        return docker_app,special_app

    def sql_based_apps(self, path):
        remove_apps = ['backup', 'nginx']
        all_apps = os.listdir(path)
        installed_apps = list(set(all_apps).difference(remove_apps))
        for i in sql_apps:
            if i in installed_apps:
                mysql_apps.append(i)

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

    def get_arr_apps(self, path):
        remove_apps = ['backup', 'nginx']
        all_apps = os.listdir(path)
        installed_apps = list(set(all_apps).difference(remove_apps))
        for i in arr_apps_list:
            if i in installed_apps:
                arr_apps.append(i)

    """
    
    ############################################
    #Below given function will monitor the apps#
    ############################################
    
    """

    def Monitor_Webserver(self):
        status = os.popen("ps aux | grep -i nginx |grep -v grep")
        count = len(status.readlines())
        if count <= 0:
            os.system("app-nginx restart")

    def dockerized_app(self, apps):
        for i in apps:
            status = os.popen("ps aux | grep -i {}| grep -v grep".format(i)).read()
            count = len(status.splitlines())
            if count == 0:
                os.system("app-{} restart".format(i))
                print("{} app restart".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been RESTARTED'.format(i)+"\n")
                    os.system("clear")

                time.sleep(120)
                status = os.popen(
                    "ps aux | grep -i {} | grep -v grep".format(i)).read()
                count = len(status.splitlines())
                if count == 0:
                    os.system("app-{} restart".format(i))
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write(
                            '{} was down and has been RESTARTED(2nd attempt)'.format(i)+"\n")
                    os.system("clear")
                    time.sleep(60)
                    status = os.popen("ps aux | grep -i {} | grep -v grep".format(i)).read()
                    count = len(status.splitlines())
                    if count <= 0:
                        with open(log_file, "a") as f:
                            f.write(
                            "\nScript is unable to FIX your {} so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n".format(i))
                else:
                    pass            
            else:
                pass

    def torrent_client_fixing(self, apps):
        for i in apps:
            status = os.popen("ps aux | grep -i {}".format(i)).read()
            count = len(status.splitlines())
            if count <= 2:
                os.system("app-{} restart".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been RESTARTED'.format(i) + "\n")
                    os.system("clear")
            else:
                pass
            time.sleep(2)
            status = os.popen("ps aux | grep -i {}".format(i)).read()
            count = len(status.splitlines())
            if count <= 2:
                os.system("app-{} repair".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been repair'.format(i) + "\n")
                    os.system("clear")
            time.sleep(2)
            status = os.popen("ps aux | grep -i {}".format(i)).read()
            count = len(status.splitlines())
            if count <= 2:
                with open(log_file, "a") as f:
                    f.write(
                        "\nScript is unable to FIX your {} so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n".format(i))

    def sql_app_monitor(self, apps):
        for i in apps:
            if i == "nextlcoud":
                status = os.popen("ps aux | grep -i '/usr/local/bin/supercronic /etc/crontabs/abc' | grep -v grep".format(i)).read()
                count = len(status.splitlines())    
            else:
                status = os.popen("ps aux | grep -i {} | grep -v grep".format(i)).read()
                count = len(status.splitlines())
            if count <= 0:
                os.system("app-{} restart".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been RESTARTED'.format(i) + "\n")
                    os.system("clear")

                time.sleep(30)
                if i == "nextlcoud":
                    status = os.popen("ps aux | grep -i '/usr/local/bin/supercronic /etc/crontabs/abc' | grep -v grep".format(i)).read()
                    count = len(status.splitlines())    
                else:
                    status = os.popen("ps aux | grep -i {} | grep -v grep".format(i)).read()
                    count = len(status.splitlines())
                if count <= 0:
                    with open(log_file, "a") as f:
                        f.write(
                            "\nScript is unable to FIX your {} so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n".format(i))

            else:
                pass

    def monitor_arr_apps(self):
        all_systemd_files = os.listdir(systemd_path)
        for i in arr_apps:
            status = os.popen(
                "ps aux | grep -i {}| grep -v grep".format(i)).read()
            count = len(status.splitlines())
            checker = self.system_check(i)
            if checker:
                thres = 1
            else:
                thres = 0
            if count <= thres:
                os.system("app-{} restart".format(i))
                print("{} app restart".format(i))
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('{} was down and has been RESTARTED'.format(i)+"\n")
                os.system("clear")

                time.sleep(180)
                status = os.popen(
                    "ps aux | grep -i {} | grep -v grep".format(i)).read()
                count = len(status.splitlines())
                if count <= thres:
                    os.system("app-{} restart".format(i))
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write(
                            '{} was down and has been RESTARTED(2nd attempt)'.format(i)+"\n")
                    os.system("clear")
                    time.sleep(50)
                    status = os.popen("ps aux | grep -i {} | grep -v grep".format(i)).read()
                    count = len(status.splitlines())
                    if count <= thres:
                        with open(log_file, "a") as f:
                            f.write(
                            "\nScript is unable to FIX your {} so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n".format(i))
                else:
                    pass
            else:
                pass

    """
    Bazarr monitor function:
    : it have 2 process by default
    """

    def bazarr_monitor(self):
        checker = self.system_check("bazarr")
        if checker:
            thres = 2
        else:
            thres = 0
        if "bazarr" in arr_apps:
            all_systemd_files = os.listdir(systemd_path)
            if "bazarr.service" in all_systemd_files:
                status = os.popen(
                    "ps aux | grep -i bazarr| grep -v grep").read()
                count = len(status.splitlines())
                if count <= thres:
                    os.system("app-bazarr restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('bazarr was down and has been RESTARTED'+"\n")
                    os.system("clear")

                    time.sleep(180)
                    status = os.popen(
                        "ps aux | grep -i bazarr | grep -v grep").read()
                    count = len(status.splitlines())
                    if count <= thres:
                        os.system("app-bazarr restart")
                        with open(log_file, "a") as f:
                            f.write("\nTIME: "+current_time+"\n")
                            f.write(
                                'bazarr was down and has been RESTARTED(2nd attempt)'+"\n")
                            os.system("clear")
                        time.sleep(50)
                        status = os.popen(
                        "ps aux | grep -i bazarr | grep -v grep").read()
                        count = len(status.splitlines())
                        if count <= thres:
                            with open(log_file, "a") as f:
                                f.write(
                                "\nScript is unable to FIX your bazarr so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n")
                    else:
                        pass
                else:
                    pass
        else:
            pass
    """
    Syncthing function
    :Seprate function because it have 2 process by default
    
    """

    def monitor_syncthing(self, apps):
        if "syncthing" in apps:
            status = os.popen(
                "ps aux | grep -i syncthing | grep -v grep").read()
            count = len(status.splitlines())
            if count <= 0:
                os.system("app-syncthing restart")
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('syncthing was down and has been RESTARTED'+"\n")
                os.system("clear")

                time.sleep(180)
                status = os.popen(
                    "ps aux | grep -i syncthing | grep -v grep").read()
                count = len(status.splitlines())
                if count <= 0:
                    os.system("app-syncthing restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write(
                            'syncthing was down and has been RESTARTED(2nd attempt)'+"\n")
                os.system("clear")

                time.sleep(50)
                status = os.popen(
                    "ps aux | grep -i syncthing | grep -v grep").read()
                count = len(status.splitlines())
                if count <= 1:
                    with open(log_file, "a") as f:
                        f.write(
                            "\nScript is unable to FIX your syncthing so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n")
            else:
                pass
        else:
            pass

        """
        Jdownloader2 monitor function 
        : To grep unique process of jdownloader2
        """

    def monitor_jdownloader(self, apps):
        if "jdownloader2" in apps:
            status = os.popen(
                "ps aux | grep -E '/(usr|opt/base)/bin/openbox' | grep -v grep ").read()
            count = len(status.splitlines())
            if count == 0:
                os.system("app-jdownloader2 restart")
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('Jdownloader2 was down and has been RESTARTED'+"\n")
                os.system("clear")
                time.sleep(180)
                status = os.popen(
                    "ps aux | grep -E '/(usr|opt/base)/bin/openbox' | grep -v grep ").read()
                count = len(status.splitlines())
                if count <= 0:
                    os.system("app-jdownloader2 restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write(
                            'jdownloader2 was down and has been RESTARTED(2nd attempt)'+"\n")
                    os.system("clear")
                    time.sleep(50)
                    status = os.popen(
                        "ps aux | grep -E '/(usr|opt/base)/bin/openbox' | grep -v grep ").read()
                    count = len(status.splitlines())
                    if count <= 0:
                        with open(log_file, "a") as f:
                            f.write(
                                "\nScript is unable to FIX your jdownloader2 so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n")
                else:
                    pass
            else:
                pass
        else:
            pass
        
    def monitor_resilio(self, apps):
        if "resilio" in apps:
            status = os.popen("ps aux | grep 'rslsync --nodaemon --config /config/sync.conf' | grep -v grep ").read()
            count = len(status.splitlines())
            if count == 0:
                os.system("app-resilio restart")
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('resilio was down and has been RESTARTED'+"\n")
                os.system("clear")
                time.sleep(180)
                status = os.popen(
                    "ps aux | grep 'rslsync --nodaemon --config /config/sync.conf'| grep -v grep ").read()
                count = len(status.splitlines())
                if count <= 0:
                    os.system("app-resilio restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write(
                            'resilio was down and has been RESTARTED(2nd attempt)'+"\n")
                    os.system("clear")
                    time.sleep(50)
                    status = os.popen(
                        "ps aux | grep 'rslsync --nodaemon --config /config/sync.conf'| grep -v grep ").read()
                    count = len(status.splitlines())
                    if count <= 0:
                        with open(log_file, "a") as f:
                            f.write(
                                "\nScript is unable to FIX your resilio so please open a support ticket from here - https://my.ultraseedbox.com/submitticket.php\n")
                else:
                    pass           
            else:
                pass
        else:
            pass
        
    
    def monitor_autobrr(self,apps):
        if "autobrr" in apps:
            status = os.popen("ps aux | grep autobrr | grep -v grep").read()
            count = len(status.splitlines())
            if count == 0 :
                os.system("app-autobrr restart")
                with open(log_file, "a") as f:
                    f.write("\nTIME: "+current_time+"\n")
                    f.write('Autobrr was down and has been RESTARTED'+"\n")
                os.system("clear")
                time.sleep(60)
                status = os.popen("ps aux | grep autobrr | grep -v grep").read()
                count = len(status.splitlines())
                if count == 0 :
                    os.system("app-autobrr restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Autobrr was down and has been RESTARTED on 2nd attempt'+"\n")
                os.system("clear")
                
        else:
            pass

    """
    Overseerr monitor function
    
    """

    def monitor_overserr(self, apps):
        if "overseerr" in apps:
            url = "https://{username}.{hostname}/overseerr".format(username=username,hostname=hostname)
            try:
                response = requests.get(url)
             
                if response.ok:
                    pass
                else:
                    os.system("app-overseerr restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Autobrr was down and has been RESTARTED '+"\n")
                    time.sleep(180)
                response = requests.get(url)
                if response.ok:
                    pass
                else:
                    os.system("app-overseerr restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Autobrr was down and has been RESTARTED on 2nd attempt'+"\n")
                    time.sleep(50)
                
                
            except requests.exceptions.RequestException as e:
                with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Please open a ticket'+"\n")
            
        else:
            pass
        
    """
    jellyseerr monitor function
    
    """

    def monitor_overserr(self, apps):
        if "jellyseerr" in apps:
            url = "https://{username}.{hostname}/jellyseerr".format(username=username,hostname=hostname)
            try:
                response = requests.get(url)
             
                if response.ok:
                    pass
                else:
                    os.system("app-jellyseerr restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Autobrr was down and has been RESTARTED '+"\n")
                    time.sleep(180)
                response = requests.get(url)
                if response.ok:
                    pass
                else:
                    os.system("app-jellyseerr restart")
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Autobrr was down and has been RESTARTED on 2nd attempt'+"\n")
                    time.sleep(50)
                
                
            except requests.exceptions.RequestException as e:
                with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('Please open a ticket'+"\n")
            
        else:
            pass    
    def Monitor_FlareSolver(self,apps):
        if "flaresolverr" in apps:
            output = os.popen('app-ports show').read()
            port_of_flaresolverr = next((line.split()[0] for line in output.strip().split('\n') if "Flaresolverr" in line), None)
            url = "http://172.17.0.1:{}".format(port_of_flaresolverr)
            try:
                response = requests.get(url)
                if response.status_code == 200:
                    pass
                else:
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('flaresolverr was down and has been RESTARTED'+"\n")
                    os.system("app-flaresolverr restart")
         
            except requests.RequestException as e:
                    with open(log_file, "a") as f:
                        f.write("\nTIME: "+current_time+"\n")
                        f.write('flaresolverr was down and has been RESTARTED'+"\n")
                    os.system("app-flaresolverr restart")

    def Monitor_Seerr(self,apps):
        if "seerr" not in apps:
            return
        output = os.popen('app-ports show').read()
        # [1:2] not [1]: the header and blank rows have no second field
        port_of_seerr = next((line.split()[0] for line in output.strip().split('\n') if line.split()[1:2] == ["Seerr"]), None)
        if port_of_seerr is None:
            return  # no port row, a restart would not fix that
        url = "http://172.17.0.1:{}/api/v1/status".format(port_of_seerr)
        try:
            alive = requests.get(url, timeout=30).status_code == 200
        except requests.RequestException:
            alive = False
        if not alive:
            with open(log_file, "a") as f:
                f.write("\nTIME: "+current_time+"\n")
                f.write('seerr was down and has been RESTARTED'+"\n")
            os.system("app-seerr restart")


monitor = app_monitor()
if __name__ == '__main__':
    # check webserver is running or not
    monitor.Monitor_Webserver()
    # Function call will get alls systems installed on service and monitor them
    monitor.systemD_verify_list()
    monitor.system_monitor()
    # get all docker apps and insatalled apps on service
    apps ,apps2 = monitor.get_docker_apps(apps_path)
    monitor.get_arr_apps(apps_path)
    monitor.sql_based_apps(apps_path)
    # monitor torrent client
    monitor.dockerized_app(apps)
    monitor.monitor_arr_apps()
    monitor.sql_app_monitor(mysql_apps)
    monitor.monitor_overserr(apps2)
    monitor.monitor_syncthing(apps2)
    monitor.monitor_jdownloader(apps2)
    # monitor.monitor_autobrr(apps2)
    monitor.bazarr_monitor()
    monitor.monitor_resilio(apps2)
    monitor.Monitor_FlareSolver(apps2)
    monitor.Monitor_Seerr(apps2)
