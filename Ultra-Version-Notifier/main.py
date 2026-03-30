import requests
from datetime import datetime, timedelta
from discord_webhook import DiscordWebhook, DiscordEmbed
import json
import time
import os
import logging
import sys
import argparse

work_dir = os.getcwd()
linuxserver_Repo = [["linuxserver", "docker-jackett"], ["linuxserver", "docker-medusa"], ["linuxserver", "docker-ombi"], ["linuxserver", "docker-radarr"], ["linuxserver", "docker-resilio-sync"], ["linuxserver", "docker-mylar3"], ["linuxserver", "docker-pyload-ng"],
        ["linuxserver", "docker-ubooquity"], ["linuxserver", "docker-overseerr"],["linuxserver", "docker-znc"], ["linuxserver", "docker-bazarr"], ["linuxserver", "docker-emby"], ["linuxserver", "docker-lazylibrarian"], ["linuxserver","docker-plex"], ["linuxserver", "docker-sabnzbd"], ["linuxserver", "docker-syncthing"], ["linuxserver", "docker-lidarr"],["linuxserver", "docker-tautulli"], ["linuxserver", "docker-mariadb"], ["linuxserver", "docker-nzbhydra2"],
        ["linuxserver", "docker-prowlarr"], ["linuxserver", "docker-sickchill"], ["linuxserver", "docker-wireguard"], ["linuxserver", "docker-doplarr"],["linuxserver","docker-jellyfin"]]



official_Repo = ["filebrowser/filebrowser","FlareSolverr/FlareSolverr","autobrr/autobrr"]
apps_path = work_dir + '/.apps'

readarr_Repo = "linuxserver/readarr"


Discord_WebHook_File = '{}/scripts/Ultra-Version-Notifier/discord.txt'.format(work_dir)


#discord notification function
def discord_notification(webhook, repo_owner, app_name, color, version, publish_date):
    webhook = DiscordWebhook(url=webhook,username="UltraMan")
    embed = DiscordEmbed(title='Latest Version Update',description="Apply this release using 'Upgrade & Repair' from UCP OR run 'app-{app_name} upgrade' via SSH.".format(app_name=app_name),  color=color)
    embed.set_author(name='Ultra-Robcop',
                     icon_url='https://pbs.twimg.com/profile_images/1333520282154266624/8Hiizm4w_400x400.jpg')
    embed.set_timestamp()
    embed.add_embed_field(name="Repo Owner:", value=f"{repo_owner}")
    embed.add_embed_field(name="Application Name:", value=f"{app_name}")
    embed.add_embed_field(name="Published on:", value=publish_date)
    embed.add_embed_field(name="Latest version:", value=version)
    webhook.add_embed(embed)
    # embed.set_footer(text="Latest release found: {app_name} {version}; Run app-{app_name} upgrade to apply it.".format(app_name=app_name,version=version))
    response = webhook.execute()
    
    
# Get installed apps of linuxer Repo
def installed_application__linuxserver_Repo(arr1, arr2):
    result = []
    for item in arr2:
        for repo in arr1:
            if item in repo[1]:
                result.append(repo)
                break  
    return result

# Get installed apps of official Repo

def installed_application_OfficialRepo(arr2, official_Repo):
    matched_values = []
    
    for s2 in arr2:
        for repo in official_Repo:
            if s2 in repo.lower():
                matched_values.append(repo)
                break
    
    return matched_values
    
def Discord_Notifications_Accepter():
        Web_Url = input("\033[0;32mPlease enter your Discord Webhook URL here: \033[0m")
        with open(Discord_WebHook_File, '+w') as f:
            f.write(Web_Url)
        f.close()

def Discord_WebHook_Reader():
    log_file_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "logfile.log")
    logging.basicConfig(filename=log_file_path, level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    if os.path.exists(Discord_WebHook_File) and os.path.getsize(Discord_WebHook_File) > 0:
        with open(Discord_WebHook_File, 'r') as f:
            return f.read()
    else:
        logging.warning("The Discord WebHook file is empty or doesn't exist.")
        sys.exit(1)


### Get installed apps
def install_apps_directory( path):
    remove_apps = ['backup', 'nginx']
    all_apps = os.listdir(path)
    upgrade_apps = list(set(all_apps).difference(remove_apps))
    return upgrade_apps
    
# function for linuxServer repo
def Linuxserver_new_release(linuxserver_Repo,webhook):
    headers = {"Accept": "application/vnd.github.v3+json"}
    current_date = datetime.now()

    for repo_name in linuxserver_Repo:
        time.sleep(3)
        url = "https://api.github.com/repos/{owner}/{app_names}/releases/latest".format(owner=repo_name[0], app_names=repo_name[1])
        response = requests.get(url, headers=headers)

        if response.status_code == 200:
            try:
                latest_release = response.json()
                latest_version = latest_release.get("tag_name")
                published_date = datetime.strptime(latest_release.get("published_at"), "%Y-%m-%dT%H:%M:%SZ")
                days_since_release = (current_date - published_date).days

                if days_since_release < 1:
                    publish_date_str = published_date.strftime(
                        "%Y-%m-%d %H:%M:%S")
                    print("Latest release found: {APP}, {version}; Run 'app-{APP} upgrade' to apply it.".format(APP=repo_name[1].replace("docker-",""),version=latest_version))
                    discord_notification(
                        webhook, repo_name[0], repo_name[1].replace("docker-",""), "14b89f", latest_version, publish_date_str)
                else:
                    pass
            except Exception as e:
                pass
        elif response.status_code == 404:
            discord_notification(
                        webhook, repo_name[0], repo_name[1], "14b89f","Repository not found" ,"Null")
        else:
             discord_notification(
                        webhook, repo_name[0], repo_name[1], "14b89f","Error code: {}".format(response.status_code) ,"Error code:{}".format(response.status_code))
           

def official_latest_versions(repo_urls,webhook):
    def get_latest_version_and_date(url):
        response = requests.get("https://api.github.com/repos/{url}/releases".format(url=url))
        repo_name,appname = url.split('/')
        if response.status_code == 200:
            releases = response.json()
            if len(releases) > 0:
                latest_release = releases[0]
                version = latest_release["tag_name"]
                date = latest_release["created_at"]
                return version, date ,repo_name,appname
        return None, None

    for url in repo_urls:
        latest_version, latest_date,repo_name,appname = get_latest_version_and_date(url)
        if latest_version and latest_date:
            latest_date = datetime.strptime(latest_date, "%Y-%m-%dT%H:%M:%SZ")
            current_date = datetime.utcnow()
            difference = current_date - latest_date
            if difference <= timedelta(days=1):
                print("Latest release found: {app_name} {version}; Run 'app-{app_name} upgrade' to apply it.".format(app_name=appname,version=latest_version))
                discord_notification(
                            webhook, repo_name,appname, "14b89f", latest_version, latest_date.strftime("%Y-%m-%d %H:%M:%S"))
            else:
                pass
            
def sonarrV4_latest_version(webhook,installed_apps):
    if "sonarr" in installed_apps:
        api_url = "https://api.github.com/repos/linuxserver/docker-sonarr/releases"
        response = requests.get(api_url)
        if response.status_code == 200:
            releases = response.json()
            for release in releases:
                if release["target_commitish"] == "develop":
                    publish_time = datetime.strptime(release["published_at"], "%Y-%m-%dT%H:%M:%SZ")
                    current_time = datetime.utcnow()
                    time_difference = current_time - publish_time
            if time_difference.days <= 1:
                print("Latest release found: {app_name} {version}; Run 'app-{app_name} upgrade' to apply it.".format(app_name="Sonarr-V4",version=release["tag_name"]))
                discord_notification(
                            webhook, "linuxserver", "Sonarr-V4", "14b89f", release["tag_name"], publish_time.strftime("%Y-%m-%d %H:%M:%S"))
            else:
                pass
        else:
            discord_notification(webhook, "linuxserver", "Sonarr-V4", "14b89f", response.status_code, response.status_code)
   

def readarr_latest_version(repository,webhook,installed_apps):
    if "readarr" in installed_apps:
        api_url = "https://hub.docker.com/v2/repositories/{repository}/tags".format(repository=repository)
        response = requests.get(api_url)

        if response.status_code == 200:
            data = json.loads(response.text)
            if data.get("count") > 0:
                # Iterate over each version and find the latest version released within the last 1 day
                for result in data["results"]:
                    version = result["name"]
                    last_updated = result["last_updated"]
                    last_updated_datetime = datetime.strptime(last_updated, "%Y-%m-%dT%H:%M:%S.%fZ")
                
                    # Check if the version was released within the last 1 day
                if datetime.now() - last_updated_datetime <= timedelta(days=1):
                    print("Latest release found: {app_name} {version}; Run 'app-{app_name} upgrade' to apply it.".format(app_name="readarr",version=version))
                    discord_notification(webhook, "Linuxserver","readarr", "14b89f", version, last_updated_datetime.strftime("%Y-%m-%d %H:%M:%S"))
                else:
                    pass
                
        else:
            pass

        return None


def send_success_alert():
    webhook_check = os.path.exists(Discord_WebHook_File)
    if webhook_check:
        webhook_url = Discord_WebHook_Reader()
        webhook = DiscordWebhook(url=webhook_url, username="UltraMan")
        embed = DiscordEmbed(
            title='Latest Version Update Script',
            description=f"Message: Script installation successful! Alerts will be sent when applications update are available.",
            color='228B22'
        )
        embed.set_author(
            name='Ultra-Robcop',
            icon_url='https://pbs.twimg.com/profile_images/1333520282154266624/8Hiizm4w_400x400.jpg'
        )
        embed.set_timestamp()
        webhook.add_embed(embed)
        response = webhook.execute()
        result = "\033[0;32m[SUCCESS]:\033[0m Alert sent via webhook, please check your discord."
        print(result)
    else:
        result = "\033[0;31m[ERROR]:\033[0m Unable to get Discord Webhook, re-run the script OR check its file at {}".format(Discord_WebHook_File)
        print(result)


if __name__ == "__main__":
    cmdparser = argparse.ArgumentParser(description="Script to check for new releases for supported apps")
    cmdparser.add_argument("action", choices=["latest-versions", "success-alert", "webhook-input"], help="Action to perform")

    args = cmdparser.parse_args()

    if args.action == "latest-versions":
        check = os.path.exists(Discord_WebHook_File)
        if check:
            webhook =Discord_WebHook_Reader()
            installed_apps = install_apps_directory(apps_path)
            Linuxserver_installed_apps = installed_application__linuxserver_Repo(linuxserver_Repo, installed_apps)
            Official_installed_apps = installed_application_OfficialRepo(installed_apps, official_Repo)
            Linuxserver_new_release(Linuxserver_installed_apps,webhook)
            official_latest_versions(Official_installed_apps,webhook)
            sonarrV4_latest_version(webhook,installed_apps)
            readarr_latest_version(readarr_Repo,webhook,installed_apps)
    elif args.action == "success-alert":
        send_success_alert()
    elif args.action == "webhook-input":
        Discord_Notifications_Accepter()
    else:
        print("Invalid action. Please choose 'latest-versions' or 'success-alert' or 'webhook-input'.")
