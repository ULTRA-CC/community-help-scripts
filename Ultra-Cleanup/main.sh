#!/bin/bash

SCRIPTNAME="Ultra-Cleanup"
VERSION="2024-07-25"

BOLD=$(tput bold)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
YELLOW=$(tput setaf 3)
MAGENTA=$(tput setaf 5)
GREEN=$(tput setaf 2)
STOP_COLOR=$(tput sgr0)

path=$(pwd)
apps_path="$path/.apps"
config_path="$path/.config"
files_path="$path/files"
downloads_path="$path/downloads"
music_path="$path/media/Music"
movie_path="$path/media/Movies"
tv_path="$path/media/TV Shows"
book_path="$path/media/Books"
backup_path="$path/.apps/backup/*"
rutorrent_plugin="$path/www/rutorrent"
bin_path="$path/bin"
systemd_app="$config_path/systemd/user/"
media="$path/media"
watch="$path/watch"

print_welcome_message() {
    term_width=$(tput cols)
    welcome_message="[[ Welcome to the unofficial ${SCRIPTNAME} script ]]"
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

unmount_rclone_ultra-cleanup() {
    grep_path=$(mount | grep $USER)
    if [ -z "$grep_path" ]; then
        echo -e "${YELLOW}[INFO] No rclone found here!${STOP_COLOR}"
    else
        rclone_path=$(echo $grep_path | awk '{print $3}')
        systemctl --user stop rclone-vfs
        systemctl --user stop mergerfs
        echo -e "${YELLOW}[INFO] All rclone services have been stopped.${STOP_COLOR}"
        fusermount -zu "$rclone_path"
        killall rclone
        echo -e "${GREEN}${BOLD}[SUCCESS] Rclone mounts has been removed successfully.${STOP_COLOR}"
    fi
}

remove_extra_directory_ultra-cleanup() {
    local path="$1"
    local remove_dir=("media" "files" "downloads" ".bashrc" ".bash_history" ".bash_logout" "watch" ".wget-hsts" ".config" ".profile" "www" "bin" ".apps" ".ssh")
    local main_dir=()
    local final_dir=()
    local second_round_dir=()

    echo -e "${YELLOW}${BOLD}${SCRIPTNAME} will NOT remove these files/directories:${STOP_COLOR} '[${remove_dir[*]}]'\n"

    for dir in "$path"/*; do
        main_dir+=("$(basename "$dir")")
    done

    for dir in "${main_dir[@]}"; do
        if [[ ! " ${remove_dir[*]} " =~ " $dir " ]]; then
            final_dir+=("$dir")
        fi
    done

    for dir in "${final_dir[@]}"; do
        rm -rf "$path/$dir"
    done

    main_dir=()
    for dir in "$path"/*; do
        main_dir+=("$(basename "$dir")")
    done

    for dir in "${main_dir[@]}"; do
        if [[ ! " ${remove_dir[*]} " =~ " $dir " ]]; then
            second_round_dir+=("$dir")
        fi
    done

    for dir in "${second_round_dir[@]}"; do
        rm -rf "$path/$dir"
    done

    echo -e "${GREEN}${BOLD}[SUCCESS] All extra directories and files have been deleted.${STOP_COLOR}"
}

uninstall_apps_directory_ultra-cleanup() {
    local path="$1"
    local remove_apps=("backup" "nginx")
    local all_apps=()
    local delete_apps=()
    local apps_path="$path"

    for app in "$path"/*; do
        all_apps+=("$(basename "$app")")
    done

    for app in "${all_apps[@]}"; do
        if [[ ! " ${remove_apps[*]} " =~ " $app " ]]; then
            delete_apps+=("$app")
        fi
    done

    for app in "${delete_apps[@]}"; do
        rm -rf "$apps_path/$app"
    done

    for app in "${delete_apps[@]}"; do
        echo -e " [+] Uninstallation of $app has been started ..."
        app-"$app" uninstall >/dev/null 2>&1
        echo -e "  [+] $app successfully uninstalled!"
    done
    echo -e "${GREEN}${BOLD}[SUCCESS] Applications present in '$HOME/.apps' has been completed.${STOP_COLOR}"
}

delete_config_ultra-cleanup() {
    local path="$1"
    local remove_config=("systemd")
    local all_configs=()
    local delete_config=()
    local config_path="$path"

    for config in "$path"/*; do
        all_configs+=("$(basename "$config")")
    done

    for config in "${all_configs[@]}"; do
        if [[ ! " ${remove_config[*]} " =~ " $config " ]]; then
            delete_config+=("$config")
        fi
    done

    app-rtorrent uninstall --full-delete
    app-deluge uninstall --full-delete
    app-transmission uninstall --full-delete
    app-qbittorrent uninstall --full-delete

    rm -rf www/rutorrent
    rm -rf "$rutorrent_plugin"

    for config in "${delete_config[@]}"; do
        rm -rf "$config_path/$config"
    done
    echo -e "${GREEN}${BOLD}[SUCCESS] All torrent clients have been uninstalled and config files have been deleted${STOP_COLOR}"
}

delete_data_from_maindirectory_ultra-cleanup() {
    local path1="$1"
    local path2="$2"
    local path3="$3"
    local path4="$4"
    local files_path="$5"
    local downloads_path="$6"
    local watch="$7"

    if [ -d "$path1" ]; then
        echo " [+]media/Movie directory cleanup started ..."
        rm -rf "$path1"/*
        echo "  [+]media/Movie directory cleanup done!"
    fi

    if [ -d "$path2" ]; then
        echo " [+]media/Tv Show directory cleanup started ..."
        rm -rf "$path2"/*
        echo "  [+]media/Tv Show directory cleanup done!"
    fi

    if [ -d "$path3" ]; then
        echo " [+]media/Music directory cleanup started ..."
        rm -rf "$path3"/*
        echo "  [+]media/Music directory cleanup done!"
    fi

    if [ -d "$path4" ]; then
        echo " [+]media/Books directory cleanup started ..."
        rm -rf "$path4"/*
        echo "  [+]media/Books directory cleanup done!"
    fi

    if [ -d "$files_path" ]; then
        echo " [+]Files directory cleanup started ..."
        rm -rf "$files_path"/*
        echo "  [+]Files directory cleanup done!"
    fi

    if [ -d "$downloads_path" ]; then
        echo " [+]Downloads directory cleanup started ..."
        rm -rf "$downloads_path"/*
        echo "  [+]Downloads directory cleanup done!"
    fi

    if [ -d "$watch" ]; then
        echo " [+]Watch directory cleanup started ..."
        rm -rf "$watch"/*
        echo "  [+]Watch directory cleanup done!"
    fi
    echo -e "${GREEN}${BOLD}[SUCCESS] Main directories data deletion have been completed.${STOP_COLOR}"
}

clear_bin_ultra-cleanup() {
    local files_path="$1"
    local avoid=("nginx")
    local all_bin_dir=()
    local delete_bin_dir=()

    for item in "$files_path"/*; do
        all_bin_dir+=("$(basename "$item")")
    done

    for item in "${all_bin_dir[@]}"; do
        if [[ ! " ${avoid[*]} " =~ " $item " ]]; then
            delete_bin_dir+=("$item")
        fi
    done

    for item in "${delete_bin_dir[@]}"; do
        rm -rf "$files_path/$item"
    done
    echo -e "${GREEN}${BOLD}[SUCCESS] Cleanup of '~/bin' directory has been completed.${STOP_COLOR}"
}

stop_systemd_app_ultra-cleanup() {
    local path="$1"
    local not_remove_systemd_app=("default.target.wants" "nginx.service")
    local dir_list=()
    local final_list=()

    for item in "$path"/*; do
        dir_list+=("$(basename "$item")")
    done

    for item in "${dir_list[@]}"; do
        if [[ ! " ${not_remove_systemd_app[*]} " =~ " $item " ]]; then
            final_list+=("$item")
        fi
    done

    if [ ${#final_list[@]} -ne 0 ]; then
        for service in "${final_list[@]}"; do
            systemctl --user stop "$service"
            rm -rf "$path/$service"
            echo " [+] $service service has been stopped and removed"
        done
    fi

    systemctl --user daemon-reload
    systemctl --user reset-failed
    echo -e "${GREEN}${BOLD}[SUCCESS] Removal of systemd services has been completed.${STOP_COLOR}"
}

finalfix_ultra-cleanup() {
    echo -e "\n${YELLOW}${BOLD}[INFO] Reinstalling Webserver (Nginx) ...${STOP_COLOR}"
    app-nginx uninstall
    app-nginx install >/dev/null 2>&1 &
    spinner $!
    wait $!
    echo -e "${GREEN}${BOLD}[SUCCESS] Webserver (Nginx) has been reinstalled."
}

fresh_bash_install_ultra-cleanup() {
    rm -rf .bashrc
    rm -rf .profile
    cp /etc/skel/.profile ~/
    cp /etc/skel/.bashrc ~/
    source .bashrc
    source .profile
    echo -e "${GREEN}${BOLD}[SUCCESS] Fresh .profile and .bashrc have been installed and loaded${STOP_COLOR}"
}

clear_crontab_ultra-cleanup() {
    crontab -r
    echo -e "${GREEN}${BOLD}[SUCCESS] Crontab cleanup has been completed.${STOP_COLOR}"
}

delete_custom_media_files_ultra-cleanup() {
    local path="$1"
    local impt_dir=("TV Shows" "Movies" "Music" "Books")
    local dir_list=()
    local delete_dir=()

    for item in "$path"/*; do
        dir_list+=("$(basename "$item")")
    done

    for item in "${dir_list[@]}"; do
        if [[ ! " ${impt_dir[*]} " =~ " $item " ]]; then
            delete_dir+=("$item")
        fi
    done

    for item in "${delete_dir[@]}"; do
        rm -rf "$path/$item"
    done
    echo -e "${GREEN}${BOLD}[SUCCESS] '~/media' directory cleanup has been completed.${STOP_COLOR}"
}

main_fn() {
    clear
    print_welcome_message
    echo -e "${YELLOW}${BOLD}[WARNING] Disclaimer: This is an unofficial script and is not supported by Ultra.cc staff. Please proceed only if you're aware of the functionality of this script.${STOP_COLOR}\n"

    echo -e "${BLUE}${BOLD}[LIST] Operations available for ${SCRIPTNAME}:${STOP_COLOR}"
    echo "1) Complete reset - delete all data and config."
    echo "2) Delete all extra folders and files."
    echo "3) Uninstall all applications and their config but don't delete data."
    echo -e "4) Delete data from default directories\n"

    read -rp "${BLUE}${BOLD}[INPUT REQUIRED] Enter your operation choice${STOP_COLOR} '[1-4]'${BLUE}${BOLD}: ${STOP_COLOR}" OPERATION_CHOICE
    echo

    case "$OPERATION_CHOICE" in
        1)
            unmount_rclone_ultra-cleanup
            remove_extra_directory_ultra-cleanup "$path"
            uninstall_apps_directory_ultra-cleanup "$apps_path"
            delete_config_ultra-cleanup "$config_path"
            delete_data_from_maindirectory_ultra-cleanup "$movie_path" "$tv_path" "$music_path" "$book_path" "$files_path" "$downloads_path"
            delete_custom_media_files_ultra-cleanup "$media"
            clear_bin_ultra-cleanup "$bin_path"
            stop_systemd_app_ultra-cleanup "$systemd_app"
            fresh_bash_install_ultra-cleanup
            clear_crontab_ultra-cleanup
            finalfix_ultra-cleanup
            ;;
        2)
            remove_extra_directory_ultra-cleanup "$path"
            finalfix_ultra-cleanup
            ;;
        3)
            uninstall_apps_directory_ultra-cleanup "$apps_path"
            delete_config_ultra-cleanup "$config_path"
            stop_systemd_app_ultra-cleanup "$systemd_app"
            clear_bin_ultra-cleanup "$bin_path"
            fresh_bash_install_ultra-cleanup
            clear_crontab_ultra-cleanup
            finalfix_ultra-cleanup
            ;;
        4)
            delete_data_from_maindirectory_ultra-cleanup "$movie_path" "$tv_path" "$music_path" "$book_path" "$files_path" "$downloads_path"
            delete_custom_media_files_ultra-cleanup "$media"
            finalfix_ultra-cleanup
            ;;
        *)
            echo -e "${RED}${BOLD}[ERROR] Invalid option. Please enter a number 1 to 4.${STOP_COLOR}"
            ;;
    esac
}

# Call the main function
main_fn
