#!/bin/bash

# Colors
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
NORMAL=$(tput sgr0)

color_read() {
    local prompt="$1"
    local color1="$2"
    local color2="$3"

    echo -e "${color1}${prompt}${color2}"
}

printf "${RED}Welcome to the Rust Installation Script.\n"
printf "Disclaimer: This installer is unofficial and not officially supported.${NORMAL}\n\n"

echo "Please select the action you wish to perform:"
echo "   - Type 'install' (without quotes) to proceed with the installation."
echo "   - Type 'uninstall' (without quotes) to remove the script from your system."

read -r -p "$(color_read 'Enter your choice: ' ${GREEN} ${NORMAL})" input

RUST_INSTALL_DIR="$HOME/.cargo"

# Define the Rust version and download URL
RUST_VERSION="1.75.0"
RUST_TAR_URL="https://static.rust-lang.org/dist/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu.tar.gz"

# Define the installation directory
INSTALL_DIR="$HOME/.rustc"
TMP_DIR="$HOME/.tmp"

install_rust() {
    # Create installation directory if it doesn't exist
    mkdir -p "${INSTALL_DIR}"

    # Create temp directory if it doesn't exist
    mkdir -p "${TMP_DIR}"

    # Download and extract Rust
    echo "Downloading Rust ${RUST_VERSION}..."
    wget "${RUST_TAR_URL}" -O "${TMP_DIR}/rust.tar.gz"
    tar -xzf "${TMP_DIR}/rust.tar.gz" -C "${TMP_DIR}"

    # Move the binary to INSTALL_DIR
    mv "${TMP_DIR}/rust-${RUST_VERSION}-x86_64-unknown-linux-gnu"/* "${INSTALL_DIR}"

    # Remove the downloaded tarball and temp directory
    rm -rf "${TMP_DIR}"

    # Add Rust binary paths to PATH in ~/.bashrc
    echo 'export PATH="$PATH:'"$HOME/.rustc/rustc/bin"'"' >> "$HOME/.bashrc"
    echo 'export PATH="$PATH:'"$HOME/.rustc/cargo/bin"'"' >> "$HOME/.bashrc"
    
    source "$HOME/.bashrc"

    # Display Rust version
    echo "Rust ${RUST_VERSION} has been installed. Please restart your shell or run 'source ~/.bashrc' to use it."

}

yes_no() {
    local user_choice
    while true; do
        read -rp "$(color_read 'Enter your choice (Yes/No): ' ${GREEN} ${NORMAL})" user_choice
        case $user_choice in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo "Operation cancelled."
                exit 0
                ;;
            *)
                echo "Invalid option. Please enter 'Yes' or 'No'."
                ;;
        esac
    done
}

uninstaller() {
    echo "Are you sure you want to uninstall Rust?: "
    yes_no
    echo "Uninstalling Rust..."

    # Remove Rust Binaries
    rm -rf "${INSTALL_DIR}"

    # Remove Rust installation
    rm -rf "$HOME/.rustc"

    # Remove Rust binary paths from PATH in ~/.bashrc
    sed -i '/\/home\/[a-zA-Z0-9_]*\/\.rustc\/rustc\/bin/d; /\/home\/[a-zA-Z0-9_]*\/\.rustc\/cargo\/bin/d' ~/.bashrc

    source "$HOME/.bashrc"

    printf "\n${GREEN}[-] Rust has been uninstalled.${NORMAL}\n"
}

if [ "$input" = "install" ]; then
    install_rust
elif [ "$input" = "uninstall" ]; then
    uninstaller
else
    printf "\n${RED}Invalid input. Exiting...${NORMAL}\n"
    exit 1
fi
