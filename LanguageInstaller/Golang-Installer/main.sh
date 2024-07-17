#!/bin/bash

APPNAME="Golang"
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
TMPDIR_LOCATION="$HOME/.tmp/golang-$(date +%Y%m%d-%H%M%S)"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${APPNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_golang() {
    if [[ -f "${INSTALL_DIR}/bin/go" ]]; then
        echo -e "${RED}${BOLD}[ERROR] Golang installation already present at:${STOP_COLOR} '${HOME}/go/bin/go'"
        exit 1
    fi

    echo -e "\n${MAGENTA}${BOLD}[STAGE-1] Version selection${STOP_COLOR}"

    echo -e "${BLUE}${BOLD}[LIST] Select the Golang version from the below list.${STOP_COLOR}"
    echo "1) go-1.21.6"
    echo "2) go-1.20.5"
    echo "3) go-1.19.10"
    echo "4) go-1.18.10"
    echo -e "5) go-1.17.13\n"

    while true; do
        read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your ${APPNAME} version choice${STOP_COLOR} '[1-5]'${BLUE}${BOLD}: ${STOP_COLOR}" GO_VERSION
        case $GO_VERSION in
            1)
                GO_VERSION="1.21.6"
                break
            ;;
            2)
                GO_VERSION="1.20.5"
                break
            ;;
            3)
                GO_VERSION="1.19.10"
                break
            ;;
            4)
                GO_VERSION="1.18.10"
                break
            ;;
            5)
                GO_VERSION="1.17.13"
                break
            ;;
            *)
                echo -e "${RED}{BOLD}[ERROR] Invalid choice. Please enter a number between 1 and 3.${STOP_COLOR}"
            ;;
        esac
    done

    echo -e "\n${MAGENTA}${BOLD}[STAGE-2] Download binary and configure${STOP_COLOR}"
    echo -e "\n${YELLOW}${BOLD}[INFO] Installation started with version ${GO_VERSION} .....${STOP_COLOR}\n"

    GO_DOWNLOAD_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"

    mkdir -p "$TMPDIR_LOCATION"

    wget "$GO_DOWNLOAD_URL" -P "$TMPDIR_LOCATION" >/dev/null 2>&1
    tar -C "$TMPDIR_LOCATION" -xzf "$TMPDIR_LOCATION/go$GO_VERSION.linux-amd64.tar.gz" >/dev/null 2>&1

    if [[ -d "${TMPDIR_LOCATION}/go" ]]; then
        mv "${TMPDIR_LOCATION}/go" "${HOME}/go"
        if [[ -f "${HOME}/go/bin/go" ]]; then
            echo -e "${YELLOW}${BOLD}[INFO] Golang binary present at:${STOP_COLOR} '${HOME}/go/bin/go'"
        else
            echo -e "${RED}${BOLD}[ERROR] ${APPNAME} binary NOT found at ${STOP_COLOR}'${HOME}/go/bin/go'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
            exit 1
        fi
    else
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} config NOT downloaded at Temp location${STOP_COLOR} '${TMPDIR_LOCATION}/go'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
        exit 1
    fi

    echo -e "\nexport GOROOT=$INSTALL_DIR" >> "$HOME/.bashrc"
    echo "export GOPATH=$HOME/go_projects" >> "$HOME/.bashrc"
    echo "export PATH=\$PATH:\$GOROOT/bin:\$GOPATH/bin" >> "$HOME/.bashrc"

    source "$HOME/.bashrc"
    source "$HOME/.profile"

    rm -rf "${TMPDIR_LOCATION}"

    echo -e "\n${GREEN}${BOLD}[SUCCESS] ${APPNAME} installation completed with ${GO_VERSION}${STOP_COLOR}"
    sleep 2
    exec "$SHELL"

}


uninstall_golang() {
    echo -e "${YELLOW}${BOLD}[INFO] Uninstalling Golang started ...${STOP_COLOR}"
    sed -i '/export GOROOT=.*\/go/d' "$HOME/.bashrc"
    sed -i '/export GOPATH=.*\/go_projects/d' "$HOME/.bashrc"
    sed -i '/export PATH=\$PATH:\$GOROOT\/bin:\$GOPATH\/bin/d' "$HOME/.bashrc"
    rm -rf "$INSTALL_DIR"
    if [[ ! -d "$INSTALL_DIR" ]]; then
        echo -e "\n${GREEN}${BOLD}[SUCCESS] ${APPNAME} has been uninstalled completely.${NORMAL}\n"
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
