#!/bin/bash

SCRIPTNAME="Ultra-Version-Notifier"
VERSION="2025-04-24"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

CONFIG_DIR="$HOME/scripts/Ultra-Version-Notifier"
TMPDIR_LOCATION="$HOME/.tmp/ultra-version-notifier-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


yes_no_prompt() {
    local prompt="$1"
    local answer
    while true; do
        read -rp "${GREEN}${BOLD}${prompt} (Yes/No): ${STOP_COLOR}" answer
        case "$answer" in
            [Yy]* ) return 0 ;;
            [Nn]* ) echo "Operation cancelled."; exit 0 ;;
            * ) echo -e "${RED}Invalid response. Please answer Yes or No.${STOP_COLOR}" ;;
        esac
    done
}


install_ultra-version-notifier() {
    echo -e "${MAGENTA}${BOLD}[STAGE-1] Creating environment...${STOP_COLOR}"

    mkdir -p "${CONFIG_DIR}" "${TMPDIR_LOCATION}"
    /usr/bin/python3 -m venv "${CONFIG_DIR}"

    "${CONFIG_DIR}/bin/pip3" install --no-cache-dir --upgrade pip wheel >/dev/null 2>&1
    "${CONFIG_DIR}/bin/pip3" install --no-cache-dir requests discord-webhook >/dev/null 2>&1

    echo -e "${YELLOW}${BOLD}[INFO] Python environment ready at:${STOP_COLOR} '${CONFIG_DIR}'\n"

    echo -e "${MAGENTA}${BOLD}[STAGE-2] Downloading monitoring script...${STOP_COLOR}"
    wget -qO "${CONFIG_DIR}/main.py" https://scripts.usbx.me/util-v2/Ultra-Version-Notifier/main.py

    echo -e "${MAGENTA}${BOLD}[STAGE-3] Initializing setup...${STOP_COLOR}"
    "${CONFIG_DIR}/bin/python3" "${CONFIG_DIR}/main.py" webhook-input
    echo
    "${CONFIG_DIR}/bin/python3" "${CONFIG_DIR}/main.py" success-alert

    echo -e "${MAGENTA}${BOLD}[STAGE-4] Setting up cronjob...${STOP_COLOR}"
    croncmd="${CONFIG_DIR}/bin/python3 ${CONFIG_DIR}/main.py latest-versions > /dev/null 2>&1"
    cronjob="0 13 * * * $croncmd"

    (
        crontab -l 2>/dev/null | grep -v -F "$croncmd" || :
        echo "$cronjob"
    ) | crontab -

    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} installed and cronjob scheduled at 13:00 daily.${STOP_COLOR}"
    rm -rf "${TMPDIR_LOCATION}"
}


uninstall_ultra-version-notifier() {
    rm -rf "${CONFIG_DIR}"
    crontab -l | grep -v "${SCRIPTNAME}" | crontab - >/dev/null 2>&1

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo -e "${RED}${BOLD}[ERROR] Failed to fully uninstall ${SCRIPTNAME}.${STOP_COLOR}"
    else
        echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been uninstalled completely.${STOP_COLOR}"
    fi
}


upgrade_ultra-version-notifier() {
    uninstall_ultra-version-notifier
    install_ultra-version-notifier
    echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been upgraded successfully!${STOP_COLOR}"
}


main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script. Ultra.cc staff will not support issues related to it.${STOP_COLOR}\n"

    echo -e "${BLUE}${BOLD}[LIST] Available operations for ${SCRIPTNAME}:${STOP_COLOR}"
    echo "1) Install"
    echo "2) Uninstall"
    echo -e "3) Upgrade\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Please select an option [1-3]: ${STOP_COLOR}" CHOICE
    echo

    case "$CHOICE" in
        1)
            if [[ -d "${CONFIG_DIR}" ]]; then
                yes_no_prompt "The script appears to already be installed. Do you want to upgrade it?"
                upgrade_ultra-version-notifier
            else
                install_ultra-version-notifier
            fi
            ;;
        2)
            yes_no_prompt "Are you sure you want to uninstall the script?"
            uninstall_ultra-version-notifier
            ;;
        3)
            yes_no_prompt "Are you sure you want to upgrade the script?"
            upgrade_ultra-version-notifier
            ;;
        *)
            echo -e "${RED}${BOLD}[ERROR] Invalid input. Please select 1, 2 or 3.${STOP_COLOR}"
            exit 1
            ;;
    esac
}


# Call main function
main_fn
