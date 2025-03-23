#!/bin/bash

SCRIPTNAME="Ultra-API"
VERSION="2024-07-27"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

CONFIG_DIR="$HOME/scripts/Ultra-API"
BIN_DIR="$HOME/bin"
TMPDIR_LOCATION="$HOME/.tmp/ultra-api-$(date +%Y%m%d-%H%M%S)"
SCREEN_NAME="Ultra-API"
NGINX_FILE="${HOME}/.apps/nginx/proxy.d/ultra-api.conf"


print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script ]]"
    padding=$(printf '%*s' $(((term_width-${#welcome_message}) / 2)) '')
    echo -e "\n${CYAN}${BOLD}${padding}${welcome_message}${STOP_COLOR}\n"
}


nginx_conf_install_ultra-api() {
    hostname=$HOSTNAME

    cat <<EOF | tee "${NGINX_FILE}" >/dev/null
location /ultra-api {
    rewrite /ultra-api(/.*) \$1 break;
    proxy_pass http://${hostname}-direct.usbx.me:${port};

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header X-Forwarded-Host \$host;
    proxy_set_header Range \$http_range;
    proxy_set_header If-Range \$http_if_range;

    # Allow websockets
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
}

EOF

    app-nginx restart

    if [[ -f "${NGINX_FILE}" ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] ${SCRIPTNAME} Nginx file has been created at ${STOP_COLOR}'${NGINX_FILE}'"
    else
        echo -e "${RED}${BOLD}[ERROR] ${SCRIPTNAME} Nginx file NOT found at ${STOP_COLOR}'${NGINX_FILE}'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
        exit 1
    fi
}


create_auth_token_database_ultra-api() {
    local db_file="$CONFIG_DIR/auth_tokens.db"

    # Check if SQLite3 is installed
    if ! command -v sqlite3 &> /dev/null; then
        echo "SQLite3 is not installed. Please install SQLite3."
        return 1
    fi

    # Create SQLite3 database and table
    sqlite3 "$db_file" <<EOF
CREATE TABLE IF NOT EXISTS tokens (
    id INTEGER PRIMARY KEY,
    auth_token TEXT
);
EOF

    # Generate a random alphanumeric token of 24 characters
    generate_token() {
        tr -dc 'A-Za-z0-9' </dev/urandom | head -c 24
    }

    # Insert a randomly generated token into the table
    local auth_token=$(generate_token)
    sqlite3 "$db_file" "INSERT INTO tokens (auth_token) VALUES ('$auth_token');"

    if [[ -f "${CONFIG_DIR}/auth_tokens.db" ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] ${SCRIPTNAME} Auth DB created at ${STOP_COLOR}'${CONFIG_DIR}/auth_tokens.db' ${YELLOW}${BOLD}with token:${STOP_COLOR} '${auth_token}'"
    else
        echo -e "${RED}${BOLD}[ERROR] ${SCRIPTNAME} Auth DB file NOT found at ${STOP_COLOR}'${CONFIG_DIR}/auth_tokens.db'${RED}${BOLD}. Terminating the script ... Bye!${STOP_COLOR}"
        exit 1
    fi
}


get_api_token_ultra-api() {
    auth_token=$(sqlite3 "$CONFIG_DIR/auth_tokens.db" "SELECT auth_token FROM tokens;")

    if [ -z "$auth_token" ]; then
        echo "${RED}${BOLD}[ERROR] Unable to retrieve the auth token from the database."
    else
        echo -e "${YELLOW}${BOLD}[INFO] Your ${SCRIPTNAME} Auth token:${STOP_COLOR} '$auth_token'"
    fi
}


install_ultra-api() {
    #condition to check if auth token is already present
    if [[ -f "$CONFIG_DIR/auth_tokens.db" ]]; then
        auth_token=$(sqlite3 "$CONFIG_DIR/auth_tokens.db" "SELECT auth_token FROM tokens LIMIT 1;")
        if [ -n "$auth_token" ]; then
            echo -e "${YELLOW}${BOLD}[INFO] Script is already installed with API token:${STOP_COLOR} '${auth_token}'${YELLOW}${BOLD}. Please check directory:${STOP_COLOR} '${CONFIG_DIR}'${YELLOW}${BOLD} OR reinstall it.${STOP_COLOR}"
            return 0
        fi
    fi

    mkdir -p "$CONFIG_DIR"
    /usr/bin/python3 -m venv "$CONFIG_DIR"

    mkdir -p ${TMPDIR_LOCATION}

    echo -e "${MAGENTA}${BOLD}[STAGE-1] Install Python Dependencies${STOP_COLOR}"
    "$CONFIG_DIR"/bin/python3 -m pip install --upgrade pip >/dev/null 2>&1
    "$CONFIG_DIR"/bin/pip3 install --ignore-installed --no-cache-dir pip >/dev/null 2>&1
    "$CONFIG_DIR"/bin/pip list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 "$CONFIG_DIR"/bin/pip install -U >/dev/null 2>&1
    "$CONFIG_DIR"/bin/pip install --no-cache-dir wheel --upgrade >/dev/null 2>&1
    "$CONFIG_DIR"/bin/pip3 --no-cache-dir install flask requests Flask-Limiter >/dev/null 2>&1

    if [[ -d "${CONFIG_DIR}" ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Created Python environment and installed depnedencies at config location:${STOP_COLOR} '${CONFIG_DIR}'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to create Python environment at${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    echo -e "${MAGENTA}${BOLD}[STAGE-2] Download mandatory python script & Port selection${STOP_COLOR}"
    wget -qO ${TMPDIR_LOCATION}/stats_request.py https://scripts.usbx.me/util-v2/Ultra-API/stats_request.py >/dev/null 2>&1

    mv ${TMPDIR_LOCATION}/stats_request.py "${CONFIG_DIR}"/

    if [[ -f "${CONFIG_DIR}"/stats_request.py ]]; then
        echo -e "${YELLOW}${BOLD}[INFO] Downloaded mandatory python script at config location:${STOP_COLOR} '${CONFIG_DIR}/stats_request.py'\n"
    else
        echo -e "${RED}${BOLD}[ERROR] Failed to download mandatory python script in ${STOP_COLOR} '${CONFIG_DIR}'${RED}${BOLD}. Terminating the script ... Bye!"
        exit 1
    fi

    # Call port_picker function
    wget -qO ${TMPDIR_LOCATION}/port-selector.sh https://scripts.usbx.me/main-v2/BaseFunctions/port-selector/main.sh
    source ${TMPDIR_LOCATION}/port-selector.sh

    port="${SELECTED_PORT}"

    # Sed command to update values in file
    sed -i "s/>port</${port}/g" "${CONFIG_DIR}/stats_request.py"

    #configure Nginx
    echo -e "\n${MAGENTA}${BOLD}[STAGE-3] Configure Nginx for ${SCRIPTNAME}${STOP_COLOR}"
    nginx_conf_install_ultra-api


    # Variables for endpoints
    host=$HOSTNAME
    username=$USER
    complete_stats_endpont="https://${username}.${host}.usbx.me/ultra-api/total-stats"
    storage_endpoints="https://${username}.${host}.usbx.me/ultra-api/get-diskquota"
    traffic_endpoints="https://${username}.${host}.usbx.me/ultra-api/get-traffic"

    echo -e "\n${MAGENTA}${BOLD}[STAGE-4] Configure Auth DB for ${SCRIPTNAME}${STOP_COLOR}"
    create_auth_token_database_ultra-api

    echo -e "\n${MAGENTA}${BOLD}[STAGE-5] Run ${SCRIPTNAME} script in screen${STOP_COLOR}"
    screen -dmS $SCREEN_NAME "$CONFIG_DIR/bin/python3" "$CONFIG_DIR/stats_request.py"

    if screen -list | grep -q "\.$SCREEN_NAME"; then
        echo -e "${YELLOW}${BOLD}[INFO] Screen session $SCREEN_NAME is running.${STOP_COLOR}"
    else
        echo -e "${RED}${BOLD}[ERROR] Screen session $SCREEN_NAME failed to start.${STOP_COLOR}"
        exit 1
    fi

    echo -e "${GREEN}${BOLD}[SUCCESS] Ultra service API Endpoints to get your service stats:${STOP_COLOR}"
    echo -e "  ■ Complete stats.......:  \e]8;;$complete_stats_endpont\a$complete_stats_endpont\e]8;;\a"
    echo -e "  ■ Storage Stats........:  \e]8;;$storage_endpoints\a$storage_endpoints\e]8;;\a"
    echo -e "  ■ Traffic Stats........:  \e]8;;$traffic_endpoints\a$traffic_endpoints\e]8;;\a"
}


uninstall_ultra-api() {
    screen -X -S $SCREEN_NAME kill
    rm -rf "$CONFIG_DIR"
    rm -rf  "${HOME}/.apps/nginx/proxy.d/ultra-api.conf"
    app-nginx restart

    if [[ -d "$CONFIG_DIR" ]]; then
        echo -e "${RED}${BOLD}[ERROR] ${SCRIPTNAME} could not be fully uninstalled."
    else
        echo -e "${GREEN}${BOLD}[SUCCESS] ${SCRIPTNAME} has been uninstalled completely."
    fi
}


restart_ultra-api() {
    # Kill old screen first
    screen -X -S $SCREEN_NAME kill

    # Create new screen and rerun script
    screen -dmS $SCREEN_NAME "$CONFIG_DIR/bin/python3" "$CONFIG_DIR/stats_request.py"
}


main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script and is not supported by Ultra.cc staff. Please proceed only if you're aware of the functionality of this script.${STOP_COLOR}\n"

    echo -e "${BLUE}${BOLD}[LIST] Operations available for ${SCRIPTNAME}:${STOP_COLOR}"
    echo "1) Install"
    echo "2) Uninstall"
    echo "3) Restart"
    echo -e "4) Get API Token\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your operation choice${STOP_COLOR} '[1-4]'${BLUE}${BOLD}: ${STOP_COLOR}" OPERATION_CHOICE
    echo

    case "$OPERATION_CHOICE" in
        1)
            install_${SCRIPTNAME,,}
            ;;
        2)
            uninstall_${SCRIPTNAME,,}
            ;;
        3)
            restart_${SCRIPTNAME,,}
            ;;
        4)
            get_api_token_${SCRIPTNAME,,}
            ;;
        *)
            echo -e "${RED}${BOLD}[ERROR] Invalid option. Please enter a number 1 to 4.${STOP_COLOR}"
            ;;
    esac
}

# Call the main function
main_fn
