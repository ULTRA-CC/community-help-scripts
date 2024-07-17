#!/bin/bash

APPNAME="Node"
VERSION="2024-07-17"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

INSTALL_DIR="$HOME/go"
TMPDIR_LOCATION="$HOME/.tmp/node-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${APPNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_node() {
    if command -v nvm &>/dev/null; then
        echo -e "${YELLOW}${BOLD}[INFO] Node.js is already installed. Terminating the script ... Bye!${STOP_COLOR}"
    else
        echo -e "${MAGENTA}${BOLD}[STAGE-1] Installation started for Node.js and npm.${STOP_COLOR}"

        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh 2>/dev/null | bash >/dev/null 2>&1

        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

        echo -e "\n${YELLOW}${BOLD}[INFO] Installing latest LTS version of Node.js${STOP_COLOR}"
        nvm install --lts

        nvm alias default $(nvm current)

        node_version=$(node -v)
        npm_version=$(npm -v)
        if [[ ${node_version} && ${npm_version} ]]; then
            echo -e "\n${YELLOW}${BOLD}[INFO] Installed Node.js version: $node_version"
            echo -e "${YELLOW}${BOLD}[INFO] Installed npm version: $npm_version ${STOP_COLOR}"
        else
            echo -e "${RED}${BOLD}[ERROR] ${APPNAME} NOT installed, re-run the script.. Terminating the script ... Bye!${STOP_COLOR}"
            exit 1
        fi

        echo -e "\n${GREEN}${BOLD}[SUCCESS] ${APPNAME} installation completed.${STOP_COLOR}"
        source ~/.profile
        source ~/.bashrc
        sleep 2
        exec "$SHELL"
    fi
    sleep 1
}


uninstall_node() {
    echo -e "${YELLOW}${BOLD}[INFO] Uninstalling ${APPNAME} started ...${STOP_COLOR}"

    sed -i '/export NVM_DIR="\$HOME\/.nvm"/d; /\[ -s "\$NVM_DIR\/nvm.sh" \] && \\. "\$NVM_DIR\/nvm.sh"/d; /\[ -s "\$NVM_DIR\/bash_completion" \] && \\. "\$NVM_DIR\/bash_completion"/d' "$HOME/.bashrc"

    rm -rf "$HOME/.nvm"
    rm -rf "$HOME/.npm"
    if [[ ! -d "$HOME/.nvm" ]] || [[ ! -d "$HOME/.npm" ]]; then
        echo -e "\n${GREEN}${BOLD}[SUCCESS] ${APPNAME} has been uninstalled completely.${NORMAL}\n"
        exec "$SHELL"
    else
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} could not be fully uninstalled."
    fi
}


main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script and is not supported by Ultra.cc staff. Please proceed only if you are experienced with managing such custom installs on your own.${STOP_COLOR}\n"

    echo -e "${BLUE}${BOLD}[LIST] Operations available for ${APPNAME}:${STOP_COLOR}"
    echo "1) Install"
    echo -e "2) Uninstall\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your operation choice${STOP_COLOR} '[1-2]'${BLUE}${BOLD}: ${STOP_COLOR}" OPERATION_CHOICE
    echo

    # Check user choice and execute function
    case "$OPERATION_CHOICE" in
        1)
            install_${APPNAME,,}
            ;;
        2)
            uninstall_${APPNAME,,}
            ;;
        *)
            echo -e "${RED}{BOLD}[ERROR] Invalid choice. Please enter a number 1 or 2.${STOP_COLOR}"
            exit 1
            ;;
    esac
}


# Call the main function
main_fn
