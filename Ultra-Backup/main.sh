#!/bin/bash

SCRIPTNAME="Ultra-Backup"
VERSION="2024-07-27"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)


CONFIG_DIR="$HOME/scripts/Ultra-Backup"
BIN_DIR="$HOME/bin"
TMPDIR_LOCATION="$HOME/.tmp/ultra-backup-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_ultra-backup() {
    if [ ! -d "${CONFIG_DIR}" ]; then
        mkdir -p "${CONFIG_DIR}"
        /usr/bin/python3 -m venv "${CONFIG_DIR}"
    fi

    mkdir -p ${TMPDIR_LOCATION}

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Created Python environment and installed depnedencies at config location:${STOP_COLOR} '${CONFIG_DIR}'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to create Python environment at${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Download and execute mandatory python script${STOP_COLOR}"
    wget -qO ${TMPDIR_LOCATION}/backup.py https://scripts.usbx.me/util-v2/Ultra-Backup/backup.py >/dev/null 2>&1

    mv ${TMPDIR_LOCATION}/backup.py "${CONFIG_DIR}"/

    if [[ -f "${CONFIG_DIR}"/backup.py ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Downloaded mandatory python scrtip at config location:${STOP_COLOR} '${CONFIG_DIR}/backup.py'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to download mandatory python script in ${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Setup ${SCRIPTNAME} script with Rclone${STOP_COLOR}"
    if [ $(rclone listremotes 2>/dev/null | wc -l) -eq 0 ]; then
        echo -e "${RED}${BOLD}[ERROR] No Rclone remotes are configured. Please configure one first to proceed with the script. Terminating the script ... Bye!"
        exit 1
    fi

    "$HOME"/scripts/Ultra-Backup/bin/python "$HOME"/scripts/Ultra-Backup/backup.py

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Setup cronjob${STOP_COLOR}"
    croncmd="$HOME/scripts/Ultra-Backup/bin/python $HOME/scripts/Ultra-Backup/backup.py >> $HOME/scripts/Ultra-Backup/ultra_backup.log 2>&1"
    cronjob="0 0 * * 0 $croncmd"
    (
        crontab -l 2>/dev/null | grep -v -F "$croncmd" || :
        echo "$cronjob"
    ) | crontab -

    if crontab -l | grep Ultra-Backup; then
        echo -e "${YELLOW}${BOLD}[INFO] Cronjob created for script to run at 00:00 on Sunday!${STOP_COLOR}\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Unable to create cronjob. Terminating the script ... Bye"
        exit 1
    fi

    rm -rf ${TMPDIR_LOCATION}

    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been installed successfully."
}


uninstall_ultra-backup() {
    rm -rf "${CONFIG_DIR}"
    crontab -l | grep -v Ultra-Backup | crontab - >/dev/null 2>&1

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
