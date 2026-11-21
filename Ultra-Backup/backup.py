import os
import time
import shutil
import logging as l
from datetime import datetime
import logging
import sys
import subprocess
import glob

"""
Variables declarated below
"""

homedir = os.getcwd()
script_dir = os.path.join(homedir,'scripts/Ultra-Backup')
backupdirectory = os.path.join(homedir, 'BackUpFolder')
backupdestination = os.path.join(homedir, 'BackUpFolder/Config')
Session_directory = os.path.join(homedir, 'BackUpFolder/Session_dir')
desination_dir = "UltraBackupDir"
upload_timeout_seconds = 6 * 60 * 60
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

plex_dir = '.config/plex/Library/Application Support/Plex Media Server'
plex_list = [plex_dir + '/Preferences.xml', plex_dir + '/Plug-in Support/Databases/com.plexapp.plugins.library.blobs.db',
             plex_dir + '/Plug-in Support/Databases/com.plexapp.plugins.library.db']

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
    
def list_remotes():
    # rclone listremotes prints one "gdrive:" per line
    return subprocess.run(['rclone', 'listremotes'], stdout=subprocess.PIPE, text=True, check=True).stdout.splitlines()

def remote_mount_name(file_path):
    print("List of your remote mounts:")
    print("\n".join(list_remotes()))
    name = input("Please enter your rclone remote name [Example - gdrive]:")
    if ":" in name:
        name = name.replace(":", "")
    with open(file_path, 'w') as f:
        f.write(name)

def read_remote_mount_name(file_path):
    if os.path.exists(file_path) and os.path.getsize(file_path) > 0:
        with open(file_path, 'r') as f:
            return f.read().strip()
    else:
        logging.error("The rclone remote name file {} is empty or missing.".format(file_path))
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
    # rm -rf removes what it can and names every entry it cannot on stderr, which cron appends to ultra_backup.log
    if subprocess.run(['rm', '-rf', '--', path]).returncode != 0:
        logging.error("Could not fully remove {}".format(path))

def copy_into(source, dest_dir):
    # one unreadable or vanished file is logged and skipped, the rest of the backup still runs
    os.makedirs(dest_dir, mode=0o755, exist_ok=True)
    try:
        if os.path.isdir(source):
            shutil.copytree(source, os.path.join(dest_dir, os.path.basename(source.rstrip('/'))), dirs_exist_ok=True)
        else:
            shutil.copy(source, dest_dir)
    except OSError as error:
        logging.warning("Could not copy {}: {}".format(source, error))
    

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
        if os.path.isfile(paths):
            copy_into(paths, os.path.join(backupdestination, get_app_name(paths)))
        else:
            print(paths, " not exist")
    return True


def session_exit(session_state):
    for paths in session_state:
        paths = os.path.join(homedir, paths)
        if os.path.isdir(paths):
            copy_into(paths, os.path.join(Session_directory, get_session_app_name(paths)))
        else:
            print(paths, " not exist")
    return True


def Jacket_list(path):
    paths = os.path.join(homedir, path)
    if not os.path.isdir(paths):
        print(paths, " not exist")
        return False
    for index_file in glob.glob(os.path.join(paths, '*.json')):
        copy_into(index_file, os.path.join(backupdestination, 'jackett'))
    return True


def Deluge(path):
    paths = os.path.join(homedir, path)
    if not os.path.isdir(paths):
        print(paths, " not exist")
        return False
    for config_file in glob.glob(os.path.join(paths, '*.conf')) + glob.glob(os.path.join(paths, '*.bak')):
        copy_into(config_file, os.path.join(backupdestination, 'deluge'))
    return True


def zip_backup_directory(source, destination):
    try:
        # no timeout: a killed zip leaves its ziXXXXXX temp file behind in home
        subprocess.run(['zip', '-0rq', destination, source], check=True)
    except subprocess.CalledProcessError as error:
        logging.error("zip failed with exit code {}.".format(error.returncode))
        return False
    if os.path.isfile(destination + '.zip'):
        logging.info("Zip command succeeded.")
        return True
    logging.warning("Zip command succeeded, but the zip file was not created.")
    return False

def rclone_copy_command(zip_file_path, mount_name, destination_dir):
    try:
        subprocess.run(['rclone', 'copy', zip_file_path, f'{mount_name}:{destination_dir}'], check=True, timeout=upload_timeout_seconds, capture_output=True, text=True)
    except subprocess.TimeoutExpired:
        # run() has already killed rclone by the time this is raised
        logging.error("Rclone upload did not finish within {} seconds.".format(upload_timeout_seconds))
        return False
    except subprocess.CalledProcessError as error:
        logging.error("Rclone upload failed with exit code {}: {}".format(error.returncode, error.stderr.strip()))
        return False
    logging.info("Rclone transfer successful.")
    return True


if __name__ == '__main__':
    check_remote_file = check_file_dir_exists(remote_mount_file,'f')
    if not check_remote_file:
        remote_mount_name(remote_mount_file)
    if not list_remotes():
        logging.error("A remote mount has not been configured; you must establish one before proceeding.")
        sys.exit(0)
    mount_name = read_remote_mount_name(remote_mount_file)
    # Create BackUp directory
    create_backup_dir()
    check_dir = check_file_dir_exists(backupdirectory,'d')
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
    uploaded = zip_backup_directory(backupdirectory, Upload_BackupFolder) and rclone_copy_command(Upload_BackupFolder + '.zip', mount_name, desination_dir)
    # remove the local copies even after a failed upload, or every week leaves another zip in home
    Clean_up(backupdirectory)
    Clean_up(Upload_BackupFolder + '.zip')
    if not uploaded:
        sys.exit(1)
