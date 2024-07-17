#!/bin/bash

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

# Specify the installation directory
INSTALL_DIR="$HOME/gcc"

# Set the desired GCC version (update as needed)
GCC_VERSION="11.2.0"

# Function to install GCC
install_gcc() {
    echo "Installing GCC $GCC_VERSION..."
    mkdir -p "$INSTALL_DIR"
    wget "ftp://ftp.gnu.org/gnu/gcc/gcc-$GCC_VERSION/gcc-$GCC_VERSION.tar.gz"
    tar -xf "gcc-$GCC_VERSION.tar.gz"
    cd "gcc-$GCC_VERSION"
    ./configure --prefix="$INSTALL_DIR" --disable-multilib
    make -j$(nproc)
    make install
    cd ..
    rm -rf "gcc-$GCC_VERSION"
    rm "gcc-$GCC_VERSION.tar.gz"
    source .bashrc
    source .profile
    clear
    sleep 2
    echo "Installation completed. Add $INSTALL_DIR/bin to your PATH."
}

# Function to uninstall GCC
uninstall_gcc() {
    echo "Uninstalling GCC $GCC_VERSION..."
    rm -rf "$INSTALL_DIR"
    sed -i "/export PATH=\$HOME\/gcc\/bin:\$PATH/d" "$HOME/.bashrc"
    source "$HOME/.bashrc"
    echo "GCC $GCC_VERSION uninstalled successfully."
}

# Function to read input with colors
color_read() {
    local prompt="$1"
    local color1="$2"
    local color2="$3"
    echo -n -e "${color1}${prompt}${color2}"
}

echo "${RED}Welcome to the GCC $GCC_VERSION Installation Script."
echo "Disclaimer: This installer is unofficial and may not cover all cases.${NORMAL}"

echo -e "\nPlease select the action you wish to perform:\n"
echo "   - Type 1 to proceed with the installation."
echo "   - Type 2 to remove the GCC $GCC_VERSION installation from your system."

read -p "$(color_read 'Enter your choice: ' $GREEN $NORMAL)" choice

# Perform action based on the choice
case $choice in
    1) install_gcc ;;
    2) uninstall_gcc ;;
    *) echo "Invalid choice. Please enter 1 or 2." ;;
esac
