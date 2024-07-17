#!/bin/bash

APPNAME="Python"
VERSION="2024-07-17"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

INSTALL_DIR="$HOME/.pyenv"
TMPDIR_LOCATION="$HOME/.tmp/rust-$(date +%Y%m%d-%H%M%S)"


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


install_python() {
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${RED}${BOLD}[ERROR] ${APPNAME} installation using pyenv already present at:${STOP_COLOR} '${INSTALL_DIR}'"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Installing pyenv${STOP_COLOR}"
    sleep 1
    curl https://pyenv.run 2>/dev/null | bash >/dev/null 2>&1 &
    spinner $!
    wait $!

    grep -qxF 'export PYENV_ROOT="$HOME/.pyenv"' "${HOME}/.profile" || echo 'export PYENV_ROOT="$HOME/.pyenv"' >>"${HOME}/.profile"
    grep -qxF 'export PATH="$PYENV_ROOT/bin:$PATH"' "${HOME}/.profile" || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >>"${HOME}/.profile"
    grep -qxF 'eval "$(pyenv init --path)"' "${HOME}/.profile" || echo 'eval "$(pyenv init --path)"' >>"${HOME}/.profile"
    source "${HOME}/.profile"

    git clone https://github.com/momo-lab/xxenv-latest.git "$(pyenv root)"/plugins/pyenv-latest >/dev/null 2>&1 &
    spinner $!
    wait $!

    echo -e "\n${MAGENTA}${BOLD}[STAGE-2] Python version selection${STOP_COLOR}"
    echo -e "\n${BLUE}${BOLD}[LIST] Python versions available for install:${STOP_COLOR}"
    echo "1) Python 3.8"
    echo "2) Python 3.9"
    echo "3) Python 3.10"
    echo "4) Latest Python 3 release"
    echo "5) Python 2.7"
    echo -e "${YELLOW}[INFO] We recommend Python 3.8 to select as default version.\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your version choice${STOP_COLOR} '[1-5]'${BLUE}${BOLD}: ${STOP_COLOR}" SELECTED_PYTHON_VERSION

    case "$SELECTED_PYTHON_VERSION" in
        1)
            "$HOME"/.pyenv/bin/pyenv install 3.8 >/dev/null 2>&1 &
            spinner $!
            wait $!
            pyenv global 3.8
            ;;
        2)
            "$HOME"/.pyenv/bin/pyenv install 3.9 >/dev/null 2>&1 &
            spinner $!
            wait $!
            pyenv global 3.9
            ;;
        3)
            "$HOME"/.pyenv/bin/pyenv install 3.10 >/dev/null 2>&1 &
            spinner $!
            wait $!
            pyenv global 3.10
            ;;
        4)
            latest_version=$(pyenv install --list | awk '$1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ {latest=$1} END {print latest}')
            "$HOME"/.pyenv/bin/pyenv install $latest_version >/dev/null 2>&1 &
            spinner $!
            wait $!
            pyenv global $latest_version
            ;;
        5)
            "$HOME"/.pyenv/bin/pyenv install 2.7 >/dev/null 2>&1 &
            spinner $!
            wait $!
            break
            ;;
        *)
            echo -e "${RED}{BOLD}[ERROR] Invalid choice. Please enter a number between 1 and 3.${STOP_COLOR}"
            exit 1
            ;;
    esac


    INSTALLED_PYTHON_PATH=$(pyenv which python 2>&1)
    INSTALLED_VERSION=$(${INSTALLED_PYTHON_PATH} -V 2>&1)
    INSTALLED_PIP_VERSION=$(${INSTALLED_PYTHON_PATH} -m pip -V)

    if [[ -f ${INSTALLED_PYTHON_PATH} ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Installed Python version:${STOP_COLOR} '${INSTALLED_VERSION}'"
    else
        echo -e "${RED}${BOLD}[ERROR] Unable to install ${APPNAME} using pyenv at:${STOP_COLOR} '${INSTALLED_PYTHON_PATH}'"
        exit 1
    fi

    echo -e "\n${MAGENTA}${BOLD}[STAGE-3] Update pip packages${STOP_COLOR}"
    pip install --upgrade pip >/dev/null 2>&1
    pip install pip-review --auto >/dev/null 2>&1
    pip-review --auto >/dev/null 2>&1
    pip list --format=freeze | cut -d'=' -f1 | xargs -n1 pip install --upgrade >/dev/null 2>&1

    echo -e "${YELLOW}${BOLD}[INFO] Installed pip version:${STOP_COLOR}\n${INSTALLED_PIP_VERSION}"

    echo -e "\n${GREEN}${BOLD}[SUCCESS] ${APPNAME} installation using pyenv has been completed.${STOP_COLOR}"
}


uninstall_python() {
    echo -e "${YELLOW}${BOLD}[INFO] Uninstalling ${APPNAME} started ...${STOP_COLOR}"

    sed -i '/export PYENV_ROOT="\$HOME\/.pyenv"/d; /export PATH="\$PYENV_ROOT\/bin:\$PATH"/d; /eval "\$(pyenv init --path)"/d' "${HOME}/.profile"

    rm -rf "${INSTALL_DIR}"

    if [[ ! -d "${INSTALL_DIR}" ]]; then
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
