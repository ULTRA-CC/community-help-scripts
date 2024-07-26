from __future__ import division
import time
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import subprocess  # not required
import paramiko
import time
from paramiko import SSHClient
import paramiko
import os
from queue import Queue  # will use in future
import threading  # will use in future
import sys
import ftplib
from tqdm import tqdm

home_dir = os.getcwd()
# username,password and directory
SyncDir = home_dir + "/Ultra-Sync"
destination_username = ">user<"
destination_hostname = ">host<"
port = ">port<"
destination_password = ">pass<"


rsa_command = "ssh-keygen -b 4096 -q -t rsa -N '' -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1"
key_path = home_dir + "/.ssh/id_rsa.pub"


def rsa_key_generate():
    checker = os.path.exists(key_path)
    if not checker:
        key_result = subprocess.Popen(
            rsa_command, shell=True, executable='/bin/bash')
        subprocess.Popen("chmod -R go= ~/.ssh", shell=True,
                         executable='/bin/bash')
    time.sleep(1)
    with open(key_path, 'r') as f:
        key = f.read()
        key = key.replace("\n", "")
        return key


def send_key_to_host(key):
    # first do a paramiko login
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(destination_hostname, port,
                destination_username, destination_password)
    # FTP login to create dir
    host = destination_username + "." + destination_hostname
    ftps = ftplib.FTP_TLS(host)
    ftps.login(destination_username, destination_password)
    ftps.prot_p()
    filelist = []  # to store all files
    check_result = "no"
    destination_dir = "no"
    ftps.retrlines('LIST', filelist.append)
    for f in filelist:
        if f.split()[-1] == ".ssh":
            check_result = "yes"
    if check_result == "no":
        ftps.mkd(".ssh")
    for f in filelist:
        if f.split()[-1] == "Ultra-Sync-Target":
            destination_dir = "yes"
    if destination_dir == "no":
        ftps.mkd("Ultra-Sync-Target")
    time.sleep(1)
    ssh.exec_command("echo {} >> ~/.ssh/authorized_keys".format(key))
    ssh.exec_command("chmod -R go= ~/.ssh")


if __name__ == "__main__":
    key = rsa_key_generate()
    send_key_to_host(key)
