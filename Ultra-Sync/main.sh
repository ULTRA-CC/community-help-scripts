#!/bin/bash

SCRIPTNAME="Ultra-Sync"
VERSION="2024-07-26"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)


DATA_DIR="$HOME/Ultra-Sync"
CONFIG_DIR="$HOME/scripts/UltraSync"
BIN_DIR="$HOME/bin"
TMPDIR_LOCATION="$HOME/.tmp/ultra-sync-$(date +%Y%m%d-%H%M%S)"
SCREEN_NAME="UltraSync"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_ultra-sync() {
    if [ ! -d "${CONFIG_DIR}" ]; then
        mkdir -p "${CONFIG_DIR}"
        /usr/bin/python3 -m venv "${CONFIG_DIR}"
    fi

    if [ ! -d "${DATA_DIR}" ]; then
        mkdir -p "${DATA_DIR}"
    fi

    mkdir -p ${TMPDIR_LOCATION}

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Install Python Dependencies${STOP_COLOR}"
    "${CONFIG_DIR}"/bin/pip3 install --ignore-installed --no-cache-dir pip >/dev/null 2>&1
    "${CONFIG_DIR}"/bin/pip3 install -U pip >/dev/null 2>&1
    "${CONFIG_DIR}"/bin/pip3 list --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 "${CONFIG_DIR}"/bin/pip install -U >/dev/null 2>&1
    "${CONFIG_DIR}"/bin/pip3 install --no-cache-dir wheel --upgrade >/dev/null 2>&1
    #install external packages
    "${CONFIG_DIR}"/bin/pip3 --no-cache-dir install paramiko >/dev/null 2>&1
    "${CONFIG_DIR}"/bin/pip3 --no-cache-dir install watchdog >/dev/null 2>&1
    "${CONFIG_DIR}"/bin/pip3 --no-cache-dir install tqdm >/dev/null 2>&1

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Created Python environment and installed depnedencies at config location:${STOP_COLOR} '${CONFIG_DIR}'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to create Python environment at${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-2] Download and make mandatory python scripts executable${STOP_COLOR}"
    wget -qO ${TMPDIR_LOCATION}/remote_sync_setup.py https://scripts.usbx.me/util-v2/Ultra-Sync/remote_sync_setup.py >/dev/null 2>&1

    mv ${TMPDIR_LOCATION}/remote_sync_setup.py "${CONFIG_DIR}"/

    if [[ -f "${CONFIG_DIR}"/remote_sync_setup.py ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Downloaded mandatory python script at config location:${STOP_COLOR} '${CONFIG_DIR}/create_remote_dir.py'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to download mandatory python script in ${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Enter the destination host details${STOP_COLOR}"
    read -rp "${BLUE}[INPUT REQUIRED] Enter your destination hostname: ${STOP_COLOR}" hostname
    read -rp "${BLUE}[INPUT REQUIRED] Enter your destination host's username: ${STOP_COLOR}" username
    read -rp "${BLUE}[INPUT REQUIRED] Enter your destination host's password: ${STOP_COLOR}" password
    read -rp "${BLUE}[INPUT REQUIRED] Enter your destination host's SSH port: ${STOP_COLOR}" port

    sed -i "s/>pass</${password}/g" "${CONFIG_DIR}"/remote_sync_setup.py
    sed -i "s/>user</${username}/g" "${CONFIG_DIR}"/remote_sync_setup.py
    sed -i "s/>host</${hostname}/g" "${CONFIG_DIR}"/remote_sync_setup.py
    sed -i "s/>choice</${choice}/g" "${CONFIG_DIR}"/remote_sync_setup.py
    sed -i "s/>port</${port}/g" "${CONFIG_DIR}"/remote_sync_setup.py
    echo

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Setup cronjob${STOP_COLOR}"
    "${CONFIG_DIR}"/bin/python3 "${CONFIG_DIR}"/remote_sync_setup.py

    croncmd="rsync -aHAXxv ${DATA_DIR}/* --numeric-ids --info=progress2 --bwlimit=40000 --no-i-r -e 'ssh -p $port -i $HOME/.ssh/id_rsa -T -c aes256-ctr -o Compression=no -x' $username@$hostname:~/Ultra-Sync-target/"
    cronjob="0 */4 * * * $croncmd"
    (
        crontab -l 2>/dev/null | grep -v -F "$croncmd" || :
        echo "$cronjob"
    ) | crontab -

    if crontab -l | grep Ultra-Sync; then
        echo -e "${YELLOW}${BOLD}[INFO] Cronjob created for script to run at every 4TH Hour.${STOP_COLOR}\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Unable to create cronjob. Terminating the script ... Bye"
        exit 1
    fi

    rm -rf ${TMPDIR_LOCATION}

    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been installed successfully."
}


uninstall_ultra-sync() {
    rm -rf "${CONFIG_DIR}"
    crontab -l | grep -v Ultra-Sync | crontab - >/dev/null 2>&1

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo -e "${RED}${BOLD}[ERROR] ${SCRIPTNAME} could not be fully uninstalled."
    else
        echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been uninstalled completely."
    fi
}



main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script and is not supported by Ultra.cc staff. Please proceed only if you're aware about the functionality of this script.${STOP_COLOR}\n"

    echo -e "${BLUE}${BOLD}[LIST] Operations available for ${SCRIPTNAME}:${STOP_COLOR}"
    echo "1) Install"
    echo -e "2) Uninstall\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your operation choice${STOP_COLOR} '[1-2]'${BLUE}${BOLD}: ${STOP_COLOR}" OPERATION_CHOICE
    echo

    # Check user choice and execute function
    case "$OPERATION_CHOICE" in
        1)
            install_${SCRIPTNAME,,}
            ;;
        2)
            uninstall_${SCRIPTNAME,,}
            ;;
        *)
            echo -e "${RED}{BOLD}[ERROR] Invalid choice. Please enter a number 1 or 2.${STOP_COLOR}"
            exit 1
            ;;
    esac
}


# Call the main function
main_fn
