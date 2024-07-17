#!/bin/bash

APPNAME="Ruby"
VERSION="2024-07-17"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

INSTALL_DIR="$HOME/ruby"
TMPDIR_LOCATION="$HOME/.tmp/ruby-$(date +%Y%m%d-%H%M%S)"
RUBY_VERSION="3.0.2"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${APPNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠸⠴⠦⠇'
    local i=0
    while ps -p $pid > /dev/null 2>&1; do
        i=$(( (i+1) % 6 ))
        printf " [%s]  " "${spinstr:$i:1}"
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}


install_ruby() {
    if [[ -f "${INSTALL_DIR}/bin/ruby" ]]; then
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} installation already present at:${STOP_COLOR} '${INSTALL_DIR}/bin/ruby'"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Installation started for Ruby${STOP_COLOR}"
    mkdir -p "$INSTALL_DIR"

    mkdir -p "$TMPDIR_LOCATION" && cd "$TMPDIR_LOCATION"
    wget "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-$RUBY_VERSION.tar.gz" -P "$TMPDIR_LOCATION" >/dev/null 2>&1
    tar -C "$TMPDIR_LOCATION" -xzf "$TMPDIR_LOCATION/ruby-$RUBY_VERSION.tar.gz" >/dev/null 2>&1

    echo -e "\n${MAGENTA}${BOLD}[STAGE-2] Compiling Ruby${STOP_COLOR}"

    if [[ -d "${TMPDIR_LOCATION}/ruby-3.0.2" ]]; then
        cd "$TMPDIR_LOCATION/ruby-$RUBY_VERSION"
        echo -e "${YELLOW}${BOLD}[INFO] Configuring Ruby...${STOP_COLOR}"
        ./configure --prefix="$INSTALL_DIR" >/dev/null 2>&1 &
        spinner $!
        wait $!

        echo -e "${YELLOW}${BOLD}[INFO] Compiling Ruby...${STOP_COLOR}"
        make >/dev/null 2>&1 &
        spinner $!
        wait $!

        echo -e "${YELLOW}${BOLD}[INFO] Installing Ruby...${STOP_COLOR}"
        make install >/dev/null 2>&1 &
        spinner $!
        wait $!

        if [[ -f "${INSTALL_DIR}/bin/ruby" ]]; then
            echo -e "${YELLOW}${BOLD}[INFO] Ruby binary present at:${STOP_COLOR} '${INSTALL_DIR}/bin/ruby'"
        else
            echo -e "${RED}${BOLD}[ERROR] ${APPNAME} binary NOT found at ${STOP_COLOR}'${INSTALL_DIR}/bin/ruby'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
            exit 1
        fi
    else
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} config NOT downloaded at Temp location${STOP_COLOR} '${TMPDIR_LOCATION}/ruby-3.0.2'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
        exit 1
    fi

    cd ${HOME}
    rm -rf "${TMPDIR_LOCATION}"
    echo 'export PATH="$HOME/ruby/bin:$PATH"' >> ~/.bashrc
    sleep 2
    echo -e "${GREEN}${BOLD}[SUCCESS] ${APPNAME} installed successfully with version${STOP_COLOR} '${RUBY_VERSION}'"
    exec "$SHELL"
}


uninstall_ruby() {
    echo -e "${YELLOW}${BOLD}[INFO] Uninstalling ${APPNAME} started ...${STOP_COLOR}"
    rm -rf "$INSTALL_DIR"
    sed -i "/export PATH=\"\$HOME\/ruby\/bin:\$PATH\"/d" "${HOME}/.bashrc"

    if [[ ! -d "$INSTALL_DIR" ]]; then
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
