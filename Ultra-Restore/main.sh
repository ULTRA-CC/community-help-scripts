#!/bin/bash

SCRIPTNAME="Ultra-Restoration"
VERSION="2024-07-25"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

CONFIG_DIR="$HOME"
BIN_DIR="$HOME/bin"
TMPDIR_LOCATION="$HOME/.tmp/restoration-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}

functionality_list() {
    echo -e "${BLUE}${BOLD}[LIST] Operations list that will be performed:${STOP_COLOR}"
    echo "${YELLOW}[1.] Restore default shell configuration files${STOP_COLOR} - '${HOME}/.bashrc' ${YELLOW}and${STOP_COLOR} '${HOME}/.profile'"
    echo "${YELLOW}[2.] Recreate default directories${STOP_COLOR} - '${HOME}/bin', '${HOME}/downloads', '${HOME}/media' ${YELLOW}and${STOP_COLOR} '${HOME}/www'"
    echo "${YELLOW}[3.] Recreate symlink of${STOP_COLOR} '${HOME}/downloads' ${YELLOW}in${STOP_COLOR} '${HOME}/www'"
    echo -e "${YELLOW}[4.] Reinstall Webserver (Nginx).${STOP_COLOR}\n"

    echo -e "\n${YELLOW}${BOLD}[WARNING] Please read the above list of operations carefully before proceeding with the script further.\n${STOP_COLOR}"
}

confirm_options() {
    echo -e "${BLUE}${BOLD}[LIST] Choose one of the following options:${STOP_COLOR}"
    echo "1) Yes, proceed with listed operations."
    echo -e "2) No, termintate script.\n"
    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your option choice${STOP_COLOR} '[1-2]'${BLUE}${BOLD}: ${STOP_COLOR}" OPTION_CHOICE
    echo

    case "$OPTION_CHOICE" in
        1)
            start_${SCRIPTNAME,,}
            ;;
        2)
            echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} script has been terminated."
            exit 1
            ;;
        *)
            echo -e "${RED}${BOLD}[ERROR] Invalid choice. Please enter a number 1 or 2.${STOP_COLOR}"
            exit 1
            ;;
    esac

}

start_ultra-restoration() {
    echo -e "${MAGENTA}${BOLD}[STAGE-1] Restoring bash configuration files${STOP_COLOR}"
    cp /etc/skel/.{profile,bashrc} ~/
    echo -e "${YELLOW}${BOLD}[INFO] Bash configuration files restored${STOP_COLOR}"

    echo -e "\n${MAGENTA}${BOLD}[STAGE-2] Creating basic directories${STOP_COLOR}"
    mkdir -p ~/downloads ~/media ~/www
    ln -s ~/downloads ~/www > /dev/null 2>&1
    echo -e "${YELLOW}${BOLD}[INFO] Basic directories and symbolic link created${STOP_COLOR}"

    echo -e "\n${MAGENTA}${BOLD}[STAGE-3] Re-installing Nginx${STOP_COLOR}"
    app-nginx uninstall && app-nginx install > /dev/null 2>&1

    if systemctl is-active --quiet nginx.service; then
        echo -e "${YELLOW}${BOLD}[INFO] Nginx re-installed and active${STOP_COLOR}"
    else
        echo -e "${RED}${BOLD}[ERROR] Nginx installation failed or service is not active${STOP_COLOR}. Terminating the script ... Bye!"
        exit 1
    fi

    echo -e "\n${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} script process completed.${STOP_COLOR}"
}

main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script and is not supported by Ultra.cc staff. Please proceed only if you're aware about the functionality of this script.${STOP_COLOR}\n"
    sleep 1
    functionality_list
    sleep 2
    confirm_options
}

# Call the main function
main_fn
