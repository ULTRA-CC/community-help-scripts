#!/bin/bash

APPNAME="Rust"
VERSION="2024-07-17"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

INSTALL_DIR="$HOME/rust"
TMPDIR_LOCATION="$HOME/.tmp/rust-$(date +%Y%m%d-%H%M%S)"
RUST_VERSION="1.75.0"
RUST_TAR_URL="https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${APPNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


install_rust() {
    if [[ -d "$INSTALL_DIR/rustc" ]] || [[ -d "$INSTALL_DIR/cargo" ]]; then
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} installation already present at:${STOP_COLOR} '${INSTALL_DIR}/rustc' & '$INSTALL_DIR/cargo'"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Installation started for ${APPNAME}${STOP_COLOR}"
    mkdir -p "$INSTALL_DIR"

    mkdir -p "$TMPDIR_LOCATION"

    wget "${RUST_TAR_URL}" -O "${TMPDIR_LOCATION}/rust.tar.gz" >/dev/null 2>&1
    tar -xzf "${TMPDIR_LOCATION}/rust.tar.gz" -C "${TMPDIR_LOCATION}" >/dev/null 2>&1

    mv "${TMPDIR_LOCATION}/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu"/* "${INSTALL_DIR}"
    rm -rf "${TMPDIR_LOCATION}"

    if [[ -d "$INSTALL_DIR/rustc" ]] || [[ -d "$INSTALL_DIR/cargo" ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] ${APPNAME} binary present at:${STOP_COLOR} '${INSTALL_DIR}'"
    else
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} binary NOT found at ${STOP_COLOR}'${INSTALL_DIR}'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
        exit 1
    fi

    echo 'export PATH="$PATH:'"$HOME/rust/rustc/bin"'"' >> "$HOME/.bashrc"
    echo 'export PATH="$PATH:'"$HOME/rust/cargo/bin"'"' >> "$HOME/.bashrc"

    echo -e "${GREEN}${BOLD}[SUCCESS] ${APPNAME} installed successfully with version${STOP_COLOR} '${RUST_VERSION}'"
    exec "$SHELL"
}


uninstall_rust() {
    echo -e "${YELLOW}${BOLD}[INFO] Uninstalling ${APPNAME} started ...${STOP_COLOR}"
    rm -rf "$INSTALL_DIR"
    sed -i '/export PATH="\$PATH:\/home\/[^\/]*\/rust\/rustc\/bin"/d' "${HOME}/.bashrc"
    sed -i '/export PATH="\$PATH:\/home\/[^\/]*\/rust\/cargo\/bin"/d' "${HOME}/.bashrc"

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
