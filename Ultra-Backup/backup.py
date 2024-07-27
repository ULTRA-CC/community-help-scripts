import os
import time
import shutil
import logging as l
from datetime import datetime
import logging
import sys
import subprocess

"""
Variables declarated below
"""

homedir = os.getcwd()
script_dir = os.path.join(homedir,'scripts/Ultra-Backup')
backupdirectory = os.path.join(homedir, 'BackUpFolder')
backupdestination = os.path.join(homedir, 'BackUpFolder/Config')
Session_directory = os.path.join(homedir, 'BackUpFolder/Session_dir')
desination_dir = "UltraBackupDir"
now = datetime.now()
current_date = str(now.date())
Upload_BackupFolder = os.path.join(homedir, "Ultra-Backup-" + current_date)
remote_mount_file = os.path.join(script_dir,'config.txt')
log_file = os.path.join(homedir,'scripts/Ultra-Backup/backup_log.txt') # Specify the log file name and path
# Configure logging to write to the log file
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S', handlers=[logging.FileHandler(log_file)])

"""
Paths are declared as a list to make them as iterable item

"""

conifg_list = ['.apps/bazarr/db/bazarr.db', '.apps/bazarr/config/config.ini', '.apps/lidarr/lidarr.db', '.apps/lidarr/config.xml', '.apps/ombi/Ombi.db',
               '.apps/ombi/OmbiSettings.db', '.apps/jackett/Jackett/ServerConfig.json', '.apps/radarr/config.xml', '.apps/radarr/radarr.db',
               '.apps/mylar3/mylar/config.ini', '.apps/mylar3/mylar/mylar.db', '.apps/ubooquity/preferences.json', '.apps/ubooquity/ubooquity-5.mv.db',
               '.apps/jellyfin/data/data/jellyfin.db', '.apps/jellyfin/data/data/library.db', '.apps/overseerr/db/db.sqlite3', '.apps/overseerr/settings.json',
               '.apps/sonarr/config.xml', '.apps/sonarr/sonarr.db', '.apps/emby/data/library.db',
               '.apps/sabnzbd/sabnzbd.ini', '.apps/syncthing/config.xml', '.apps/syncthing/index-v0.14.0.db', '.apps/nzbget/nzbget.conf',
               '.apps/readarr/config.xml', '.apps/readarr/readarr.db', '.apps/tautulli/config.ini', '.apps/tautulli/tautulli.db',
               '.apps/nzbhydra2/database/nzbhydra.mv.db', '.apps/nzbhydra2/nzbhydra.yml', '.apps/prowlarr/config.xml', '.apps/prowlarr/prowlarr.db',
               '.apps/autobrr/autobrr.db', '.apps/autobrr/config.toml', '.config/rtorrent/rtorrent.rc', '.config/transmission-daemon/settings.json',
               '.config/qBittorrent/qBittorrent.conf',
               '.config/deluge/core.conf', '.config/deluge/web.conf', '.config/deluge/execute.conf', '.autodl/autodl.cfg'
               ]

plex_list = ['.config/plex/Library/Application\ Support/Plex\ Media\ Server/Preferences.xml', '.config/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.blobs.db',
             '.config/plex/Library/Application\ Support/Plex\ Media\ Server/Plug-in\ Support/Databases/com.plexapp.plugins.library.db']

session_state = ['.config/deluge/state/', '.config/transmission-daemon/torrents/',
                 '.config/rtorrent/session/', '.local/share/qBittorrent/BT_backup/']

jacket_list = '.apps/jackett/Jackett/Indexers'

deluge_path = '.config/deluge'

"""
Supportive functions

create_backup_dir: Create backup directory and sub directory
get_app_name : Get app name from path purpose to create sub directory
get_session_app_name: Get app name from session purpose to create sub directory
remote_mount_name: Create a file where it will store remote mount name
read_remote_mount_name : read mount name from file
"""

def create_backup_dir():
    if not os.path.exists(backupdirectory):
        os.mkdir(backupdirectory, mode=0o755)
    if not os.path.exists(backupdestination):
        os.mkdir(backupdestination, mode=0o755)
    if not os.path.exists(Session_directory):
        os.mkdir(Session_directory, mode=0o755)


def get_app_name(path):
    return path.split('/')[4]

def get_session_app_name(path):
    if "rtorrent" in path:
        return "rtorrent"
    if "deluge" in path:
        return "deluge"
    if "transmission-daemon" in path:
        return "transmission-daemon"
    if "qBittorrent" in path:
        return "qBittorrent"
    
def remote_mount_name(file_path):
    remote_list = os.popen("rclone listremotes | wc -l").read()
    if "0" in remote_list:
        pass
    else:
        remote_lists = os.popen("rclone listremotes").read()
    print("List of your remote mounts:")
    print(remote_lists)
    name = input("Please enter your rclone remote name [Example - gdrive]:")
    if ":" in name:
        name = name.replace(":", "")
    with open(file_path, 'w') as f:
        f.write(name)

def read_remote_mount_name(file_path):
    log_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logfile.log")
    logging.basicConfig(filename=log_file_path, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
        with open(file_path, 'r') as f:
            return f.read()
    else:
        logging.warning("The Discord WebHook file is empty or doesn't exist.")
        sys.exit(1)
    
def check_file_dir_exists(file_path,mode):
    if mode == 'f':
        result = os.popen('[ -f {} ] && echo -n 1'.format(file_path )).read()
    else:
         result = os.popen('[ -d {} ] && echo -n 1'.format(file_path)).read()
    if result == '1':
        return True
    else:
        return False
    
def Clean_up(path):
    result = os.popen('rm -rf {}'.format(path)).read()
    

"""
Main Functions
config_exist: Copy all important min essential config,db etc to Backup/config directory
plex_check: Copy all plex db to BackUp/Config directory
session_exit:  Copy session directory to Backup/session directory
zip_backup_directory: Zip the BackUp  folder will be easy to upload to google drive
rclone_copy_command : Rclone copy command will upload backup directory to google drive
"""

def config_exist(conifg_list):
    for paths in conifg_list:
        paths = os.path.join(homedir,paths)
        result = os.popen('[ -f {} ] && echo -n 1'.format(paths)).read()
        if result == '1':
            app_name = get_app_name(paths)
            if app_name in paths:
                app_paths = os.path.join(backupdestination, app_name)
                app_path_dest = app_paths + '/'
                time.sleep(1)
                if not os.path.exists(app_paths):
                    os.mkdir(app_paths, mode=0o755)
                    shutil.copy(r"{}".format(paths), app_path_dest)
                if os.path.exists(app_paths):
                    shutil.copy(r"{}".format(paths), app_path_dest)
    return True


def plex_check(plex_list):
    for paths in plex_list:
        paths = os.path.join(homedir, paths)
        result = os.popen('[ -f {} ] && echo -n 1'.format(paths)).read()
        
        if result == '1':
            app_name = get_app_name(paths)
            
            if app_name in paths:
                app_paths = os.path.join(backupdestination, app_name)
                app_path_dest = app_paths + '/'
                time.sleep(1)
                
                if not os.path.exists(app_paths):
                    os.mkdir(app_paths, mode=0o755)
                
                try:
                    # Use subprocess.run to execute the 'cp' command
                    subprocess.run(['cp', '-rf', paths, app_path_dest], check=True, timeout=10)
                
                except subprocess.TimeoutExpired:
                    # Kill the 'cp' process if it exceeds the timeout
                    cp_process = subprocess.Popen(['cp', '-rf', paths, app_path_dest], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    cp_process.terminate()
                    time.sleep(1)  # Wait for termination to take effect
                    cp_process.kill()

                    logging.warning("Timeout expired for Plex copy process. Killed.")
                    return False

        else:
            print(paths, " not exist")
    
    return True    


def session_exit(session_state):
    for paths in session_state:
        paths = os.path.join(homedir, paths)
        result = os.popen('[ -d {} ] && echo -n 1'.format(paths)).read()
        
        if result == '1':
            app_name = get_session_app_name(paths)
            
            if app_name in paths:
                app_paths = os.path.join(Session_directory, app_name)
                destination_session = app_paths + "/"
                
                if not os.path.exists(app_paths):
                    os.mkdir(app_paths, mode=0o755)
                
                try:
                    # Use subprocess.run to execute the 'cp' command
                    subprocess.run(['cp', '-rf', paths, destination_session], check=True, timeout=10)
                
                except subprocess.TimeoutExpired:
                    # Kill the 'cp' process if it exceeds the timeout
                    cp_process = subprocess.Popen(['cp', '-rf', paths, destination_session], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                    cp_process.terminate()
                    time.sleep(1)  # Wait for termination to take effect
                    cp_process.kill()

                    logging.warning("Timeout expired for session exit copy process. Killed.")
                    return False

        else:
            print(paths, " not exist")
    
    return True


def Jacket_list(path):
    paths = os.path.join(homedir, path)
    result = os.popen('[ -d {} ] && echo -n 1'.format(paths)).read()
    
    if result == '1':
        app_name = 'jackett'
        
        if app_name in paths:
            app_paths = os.path.join(backupdestination, app_name)
            destination_session = app_paths + "/"
            index_path = paths + "/*.json"
            
            if not os.path.exists(app_paths):
                os.mkdir(app_paths, mode=0o755)
                
            try:
                # Use subprocess.run to execute the 'cp' command
                subprocess.run(['cp', '-rf', index_path, destination_session], check=True, timeout=10)
            
            except subprocess.TimeoutExpired:
                # Kill the 'cp' process if it exceeds the timeout
                cp_index_process = subprocess.Popen(['cp', '-rf', index_path, destination_session], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                cp_index_process.terminate()
                time.sleep(1)  # Wait for termination to take effect
                cp_index_process.kill()

                logging.warning("Timeout expired for Jackett copy process. Killed.")
                return False

        return True
    else:
        print(paths, " not exist")
        return False


def Deluge(path):
    paths = os.path.join(homedir, path)
    result = os.popen('[ -d {} ] && echo -n 1'.format(paths)).read()
    
    if result == '1':
        app_name = 'deluge'
        
        if app_name in paths:
            app_paths = os.path.join(backupdestination, app_name)
            destination_session = app_paths + "/"
            conf_path = paths + "/*.conf"
            back_path = paths + "/*.bak"
            
            if not os.path.exists(app_paths):
                os.mkdir(app_paths, mode=0o755)
                
            try:
                # Use subprocess.run to execute the 'cp' commands
                subprocess.run(['cp', '-rf', conf_path, destination_session], check=True, timeout=10)
                subprocess.run(['cp', '-rf', back_path, destination_session], check=True, timeout=10)

            except subprocess.TimeoutExpired:
                # Kill the 'cp' processes if they exceed the timeout
                cp_conf_process = subprocess.Popen(['cp', '-rf', conf_path, destination_session], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                cp_back_process = subprocess.Popen(['cp', '-rf', back_path, destination_session], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
                
                cp_conf_process.terminate()
                cp_back_process.terminate()
                
                time.sleep(1)  # Wait for termination to take effect
                
                cp_conf_process.kill()
                cp_back_process.kill()

                logging.warning("Timeout expired for Deluge copy process. Killed.")
                return False

        return True
    else:
        print(paths, " not exist")
        return False



import subprocess

def zip_backup_directory(source, destination):
    try:
        # Use subprocess.run to execute the zip command
        subprocess.run(['zip', '-0rq', destination, source], check=True, timeout=120)
        
        # Check if the zip file was created
        if os.path.isfile(destination + '.zip'):
            logging.info("Zip command succeeded.")
            return True
        else:
            logging.warning("Zip command succeeded, but the zip file was not created.")
            return False

    except subprocess.TimeoutExpired:
        # Kill the zip process if it exceeds the timeout
        zip_process = subprocess.Popen(['zip', '-0rq', destination, source], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        zip_process.terminate()
        time.sleep(1)  # Wait for termination to take effect
        zip_process.kill()
        logging.warning("Timeout expired for zip command process. Killed.")
        return False

def rclone_copy_command(zip_file_path, mount_name, destination_dir):
    try:
        # Use subprocess.run to execute the rclone copy command
        result = subprocess.run(['rclone', '-P', 'copy', zip_file_path, f'{mount_name}:{destination_dir}', '--create-empty-src-dirs'], check=True, timeout=10, capture_output=True, text=True)

        if "100%" in result.stdout:
            logging.info("Rclone transfer successful.")
            return True
        else:
            logging.error("Rclone transfer failed.")
            return False

    except subprocess.TimeoutExpired:
        # Kill the rclone process if it exceeds the timeout
        rclone_process = subprocess.Popen(['rclone', '-P', 'copy', zip_file_path, f'{mount_name}:{destination_dir}', '--create-empty-src-dirs'], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        rclone_process.terminate()
        time.sleep(1)  # Wait for termination to take effect
        rclone_process.kill()
        logging.warning("Timeout expired for rclone transfer process. Killed.")
        return False




if __name__ == '__main__':
    # Create BackUp directory
    check_remote_file = check_file_dir_exists(remote_mount_file,'f')
    if not check_remote_file:
        remote_mount_name(remote_mount_file)
    create_backup_dir()
    check_dir = check_file_dir_exists(backupdirectory,'d')
    remote_list = os.popen("rclone listremotes | wc -l").read()
    if "0" in remote_list:
        logging.error("A remote mount has not been configured; you must establish one before proceeding.")
        sys.exit(0)
    if check_dir:
        # Copy all important files like DB,XML.Config etc to Back Up folder and create directory with app name
        config_exist(conifg_list)
        # Copy plex important files to back up folder
        plex_check(plex_list)
        # back up torrent session to backup folder
        session_exit(session_state)
        # check if jacket indexer exist
        Jacket_list(jacket_list)
        # backup deluge .conf and .bak file
        Deluge(deluge_path)
    # create a zip file of BackUp folder
    output = zip_backup_directory(backupdirectory, Upload_BackupFolder)
    # # return True if zip file is created and exist
    if output:
    #     # read mount name from file
        mount_name = read_remote_mount_name(remote_mount_file)
    #     # use rclone copy command and upload .zip file to google drive
        upload_check = rclone_copy_command(Upload_BackupFolder + '.zip',mount_name)
    #     # If upload is successful, return True
        if upload_check:
            # delete BackupDirectory
            Clean_up(backupdirectory)
            # delete backup directory .zip
            Clean_up(Upload_BackupFolder + '.zip')
        else: 
            upload_check = rclone_copy_command(Upload_BackupFolder + '.zip',mount_name)
    else:
        output = zip_backup_directory(backupdirectory, Upload_BackupFolder)
        if output:
            # read mount name from file
            mount_name = read_remote_mount_name(remote_mount_file)
            # use rclone copy command and upload .zip file to google drive
            upload_check = rclone_copy_command(Upload_BackupFolder + '.zip',mount_name)
            # If upload is successful, return True
            if upload_check:
                # delete BackupDirectory
                Clean_up(backupdirectory)
                # delete backup directory .zip
                Clean_up(Upload_BackupFolder + '.zip')
       
 
