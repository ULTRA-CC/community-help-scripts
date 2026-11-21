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
from tqdm import tqdm

home_dir = os.getcwd()
# username,password and directory
SyncDir = home_dir + "/Ultra-Sync"
destination_username = os.environ["ULTRA_SYNC_USER"]
destination_hostname = os.environ["ULTRA_SYNC_HOST"]
port = int(os.environ["ULTRA_SYNC_PORT"])
destination_password = os.environ["ULTRA_SYNC_PASSWORD"]


ssh_dir = home_dir + "/.ssh"
private_key_path = ssh_dir + "/id_rsa"
key_path = private_key_path + ".pub"


def rsa_key_generate():
    os.makedirs(ssh_dir, mode=0o700, exist_ok=True)
    # never replace an existing private key, other hosts may already trust it
    if not os.path.exists(private_key_path):
        subprocess.run(["ssh-keygen", "-b", "4096", "-q", "-t", "rsa", "-N", "", "-f", private_key_path], check=True)
    elif not os.path.exists(key_path):
        # write the .pub only once ssh-keygen succeeds, the next run trusts whatever file is there
        public_key = subprocess.run(["ssh-keygen", "-y", "-f", private_key_path], stdout=subprocess.PIPE, text=True, check=True).stdout
        with open(key_path, "w") as f:
            f.write(public_key)
    os.chmod(ssh_dir, 0o700)
    with open(key_path, 'r') as f:
        key = f.read()
        key = key.replace("\n", "")
        return key


def run_remote(ssh, command):
    # exec_command returns at once, so wait for the exit status or the script can exit first
    stdin, stdout, stderr = ssh.exec_command(command)
    if stdout.channel.recv_exit_status() != 0:
        sys.exit("Remote command failed on {}: {}\n{}".format(destination_hostname, command, stderr.read().decode().strip()))


def send_key_to_host(key):
    ssh = paramiko.SSHClient()
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    ssh.connect(destination_hostname, port,
                destination_username, destination_password)
    # the cron job rsyncs into ~/Ultra-Sync-target
    run_remote(ssh, "mkdir -p ~/.ssh ~/Ultra-Sync-target")
    run_remote(ssh, "grep -qxF '{0}' ~/.ssh/authorized_keys 2>/dev/null || echo '{0}' >> ~/.ssh/authorized_keys".format(key))
    run_remote(ssh, "chmod -R go= ~/.ssh")
    ssh.close()


if __name__ == "__main__":
    key = rsa_key_generate()
    send_key_to_host(key)
