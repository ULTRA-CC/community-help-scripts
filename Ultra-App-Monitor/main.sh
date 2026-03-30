#!/bin/bash

SCRIPTNAME="Ultra-App-Monitor"
VERSION="2025-04-24"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

CONFIG_DIR="$HOME/scripts/${SCRIPTNAME}"
TMPDIR_LOCATION="$HOME/.tmp/${SCRIPTNAME,,}-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_app-monitor-local() {
    echo -e "${MAGENTA}${BOLD}[STAGE-1] Preparing environment...${STOP_COLOR}"

    mkdir -p "${CONFIG_DIR}" "${TMPDIR_LOCATION}"
    /usr/bin/python3 -m venv "${CONFIG_DIR}"

    "${CONFIG_DIR}/bin/pip3" install --no-cache-dir --upgrade pip wheel >/dev/null 2>&1
    "${CONFIG_DIR}/bin/pip3" install --no-cache-dir requests >/dev/null 2>&1

    echo -e "${YELLOW}${BOLD}[INFO] Virtual environment setup complete at:${STOP_COLOR} ${CONFIG_DIR}\n"

    echo -e "${MAGENTA}${BOLD}[STAGE-2] Downloading monitor scripts...${STOP_COLOR}"
    wget -qO "${CONFIG_DIR}/apps-monitor-local.py" https://scripts.usbx.me/util-v2/Ultra-App-Monitor/apps-monitor-local.py
    wget -qO "${CONFIG_DIR}/torrent-clients-monitor-local.py" https://scripts.usbx.me/util-v2/Ultra-App-Monitor/torrent-clients-monitor-local.py

    echo -e "${YELLOW}${BOLD}[INFO] Python scripts downloaded to config directory.${STOP_COLOR}\n"

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Running once for test...${STOP_COLOR}"
    "${CONFIG_DIR}/bin/python3" "${CONFIG_DIR}/apps-monitor-local.py"

    echo -e "${MAGENTA}${BOLD}[STAGE-4] Creating cronjobs...${STOP_COLOR}"
    croncmd="${CONFIG_DIR}/bin/python3 ${CONFIG_DIR}/apps-monitor-local.py >> ${CONFIG_DIR}/apps-monitor-local.log 2>&1"
    cronjob="*/30 * * * * $croncmd"

    croncmd2="${CONFIG_DIR}/bin/python3 ${CONFIG_DIR}/torrent-clients-monitor-local.py >> ${CONFIG_DIR}/apps-monitor-local.log 2>&1"
    cronjob2="*/5 * * * * $croncmd2"

    (
        crontab -l 2>/dev/null | grep -v -F "${croncmd}" | grep -v -F "${croncmd2}" || :
        echo "$cronjob"
        echo "$cronjob2"
    ) | crontab -

    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} installed and scheduled via cron.${STOP_COLOR}"
    rm -rf "${TMPDIR_LOCATION}"
}


install_app-monitor-discord() {
    echo -e "${MAGENTA}${BOLD}[STAGE-1] Preparing environment for Discord mode...${STOP_COLOR}"

    mkdir -p "${CONFIG_DIR}" "${TMPDIR_LOCATION}"
    /usr/bin/python3 -m venv "${CONFIG_DIR}"

    "${CONFIG_DIR}/bin/pip3" install --no-cache-dir --upgrade pip wheel >/dev/null 2>&1
    "${CONFIG_DIR}/bin/pip3" install --no-cache-dir requests discord-webhook >/dev/null 2>&1

    echo -e "${YELLOW}${BOLD}[INFO] Environment ready at:${STOP_COLOR} ${CONFIG_DIR}\n"

    echo -e "${MAGENTA}${BOLD}[STAGE-2] Downloading Discord monitoring scripts...${STOP_COLOR}"
    wget -qO "${CONFIG_DIR}/apps-monitor-discord.py" https://scripts.usbx.me/util-v2/Ultra-App-Monitor/apps-monitor-discord.py
    wget -qO "${CONFIG_DIR}/torrent-clients-monitor-discord.py" https://scripts.usbx.me/util-v2/Ultra-App-Monitor/torrent-clients-monitor-discord.py

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Running once to verify...${STOP_COLOR}"
    "${CONFIG_DIR}/bin/python3" "${CONFIG_DIR}/apps-monitor-discord.py"

    echo -e "${MAGENTA}${BOLD}[STAGE-4] Creating Discord cronjobs...${STOP_COLOR}"
    croncmd="${CONFIG_DIR}/bin/python3 ${CONFIG_DIR}/apps-monitor-discord.py > /dev/null 2>&1"
    cronjob="*/30 * * * * $croncmd"

    croncmd2="${CONFIG_DIR}/bin/python3 ${CONFIG_DIR}/torrent-clients-monitor-discord.py > /dev/null 2>&1"
    cronjob2="*/5 * * * * $croncmd2"

    (
        crontab -l 2>/dev/null | grep -v -F "${croncmd}" | grep -v -F "${croncmd2}" || :
        echo "$cronjob"
        echo "$cronjob2"
    ) | crontab -

    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} (Discord mode) installed and scheduled via cron.${STOP_COLOR}"
    rm -rf "${TMPDIR_LOCATION}"
}


update_discord_webhook() {
    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter new Discord webhook URL: ${STOP_COLOR}" webhook_url

    if [ -z "${webhook_url}" ]; then
        echo -e "${RED}${BOLD}[ERROR] Webhook URL cannot be empty!${STOP_COLOR}"
        update_discord_webhook
    else
        echo "${webhook_url}" > "${CONFIG_DIR}/discord.txt"
        echo -e "${GREEN}${BOLD}[SUCCESS] Discord webhook updated successfully.${STOP_COLOR}"
    fi
}


uninstall_app-monitor() {
    rm -rf "${CONFIG_DIR}"
    crontab -l | grep -v "${SCRIPTNAME}" | crontab - >/dev/null 2>&1

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo -e "${RED}${BOLD}[ERROR] ${SCRIPTNAME} could not be fully uninstalled.${STOP_COLOR}"
    else
        echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been uninstalled completely.${STOP_COLOR}"
    fi
}


main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script and is not supported by Ultra.cc staff.${STOP_COLOR}\n"

    echo -e "${BLUE}${BOLD}[LIST] Available operations for ${SCRIPTNAME}:${STOP_COLOR}"
    echo "1) Install - Log to local file"
    echo "2) Install - Send alerts to Discord"
    echo "3) Uninstall"
    echo -e "4) Update Discord Webhook\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Select option [1-4]: ${STOP_COLOR}" CHOICE
    echo

    case "${CHOICE}" in
        1) install_app-monitor-local ;;
        2) install_app-monitor-discord ;;
        3) uninstall_app-monitor ;;
        4) update_discord_webhook ;;
        *) echo -e "${RED}${BOLD}[ERROR] Invalid option! Exiting...${STOP_COLOR}" && exit 1 ;;
    esac
}


# Start it all
main_fn
