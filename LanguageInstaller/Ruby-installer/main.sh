#!/bin/bash

#colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)


INSTALL_DIR="$HOME/ruby"

# Set the desired Ruby version (update as needed)
RUBY_VERSION="3.0.2"

# Function to install Ruby
install_ruby() {
    echo "Installing Ruby $RUBY_VERSION..."
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    wget "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-$RUBY_VERSION.tar.gz"
    tar -xzvf "ruby-$RUBY_VERSION.tar.gz"
    cd "ruby-$RUBY_VERSION"
    ./configure --prefix="$INSTALL_DIR"
    make
    make install
    echo 'export PATH="$HOME/ruby/bin:$PATH"' >> ~/.bashrc
    source ~/.bashrc
    source ~/.profile
    clear
    sleep 2
    echo "Ruby installed successfully. Version:"
    ruby --version
    exec "$SHELL"
}

# Function to uninstall Ruby
uninstall_ruby() {
    echo "Uninstalling Ruby $RUBY_VERSION..."
    rm -rf "$INSTALL_DIR"
    sed -i "/export PATH=\"\$HOME\/ruby\/bin:\$PATH\"/d" ~/.bashrc
    source ~/.bashrc
    echo "Ruby uninstalled successfully."
}


color_read() {
    local prompt="$1"
    local color1="$2"
    local color2="$3"

    echo -e "${color1}${prompt}${color2}"
}

printf "${RED}Welcome to the Ruby 3.0.2 Installation Script.\n"
printf "Disclaimer: This installer is unofficial and Ultra.cc staff will not support any issues with it.${NORMAL}\n\n"

#read -r -p "Type 'install' to install or 'uninstall' to uninstall the script: " input
echo "Please select the action you wish to perform:\n"
echo "   - Type 1 to proceed with the installation."
echo "   - Type 2 to remove the script from your system."

read -r -p "$(color_read 'Enter your choice: ' ${GREEN} ${NORMAL})" choice


# Perform action based on the choice
case $choice in
    1) install_ruby ;;
    2) uninstall_ruby ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
esac