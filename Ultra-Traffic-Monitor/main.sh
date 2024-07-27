#!/bin/bash

SCRIPTNAME="Ultra-Traffic-Monitor"
VERSION="2024-07-28"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)


CONFIG_DIR="$HOME/scripts/Ultra-Traffic-Monitor"
BIN_DIR="$HOME/bin"
TMPDIR_LOCATION="$HOME/.tmp/ultra-traffic-monitor-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_ultra-traffic-monitor() {
    if [ ! -d "${CONFIG_DIR}" ]; then
        mkdir -p "${CONFIG_DIR}"
        /usr/bin/python3 -m venv "${CONFIG_DIR}"
        echo -e "\n${YELLOW}${BOLD}[INFO] Please enter the time interval in which you want the script to check your traffic(in minutes)."
        echo -e "For example, enter 5 for the script to run a check every 5 minutes.${STOP_COLOR}"
        read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter time interval [in minutes]:${STOP_COLOR} " time
    else
        echo -e "${RED}${BOLD}[ERROR] ${CONFIG_DIR} already present. Terminating the script ... Bye!"
        exit 1
    fi

    "$CONFIG_DIR"/bin/pip3 --no-cache-dir install requests >/dev/null 2>&1

    mkdir -p ${TMPDIR_LOCATION}

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Download and execute mandatory python script${STOP_COLOR}"
    wget -qO ${TMPDIR_LOCATION}/monitor.py https://scripts.usbx.me/util-v2/Ultra-Traffic-Monitor/monitor.py >/dev/null 2>&1

    mv ${TMPDIR_LOCATION}/monitor.py "${CONFIG_DIR}"/

    if [[ -f "${CONFIG_DIR}"/monitor.py ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Downloaded mandatory python script at config location:${STOP_COLOR} '${CONFIG_DIR}/monitor.py'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to download mandatory python script in ${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    "${CONFIG_DIR}"/bin/python3 "${CONFIG_DIR}"/monitor.py


    echo -e "${MAGENTA}${BOLD}[STAGE-2] Setup cronjob${STOP_COLOR}"
    croncmd="${CONFIG_DIR}/bin/python3 ${CONFIG_DIR}/monitor.py > /dev/null 2>&1"
    cronjob="*/${time} * * * * $croncmd"
    (
        crontab -l 2>/dev/null | grep -v -F "$croncmd" || :
        echo "$cronjob"
    ) | crontab -

    if crontab -l | grep Ultra-Traffic-Monitor; then
        echo -e "${YELLOW}${BOLD}[INFO] Cronjob created for scrip to run at every ${time} minute!${STOP_COLOR}\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Unable to create cronjob. Terminating the script ... Bye"
        exit 1
    fi

    rm -rf ${TMPDIR_LOCATION}

    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been installed successfully."
}


uninstall_ultra-traffic-monitor() {
    rm -rf "${CONFIG_DIR}"
    crontab -l | grep -v Ultra-Traffic-Monitor | crontab - >/dev/null 2>&1

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
