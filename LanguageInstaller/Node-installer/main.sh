#!/bin/bash

echo "This is the NVM, Node.js, and npm Installer!"
printf "\033[0;31mDisclaimer: This installer is unofficial and Ultra.cc staff will not support any issues with it\033[0m\n"
read -r -p "Type 'install' to install or 'uninstall' to uninstall the script: " input



installer(){
    if command -v nvm &>/dev/null; then
        echo "Node.js is installed."
    else
        echo "Node.js is not installed."
        echo "Installing Node.js and npm."


        # Install nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Load nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        
        # Install the latest LTS version of Node.js
        nvm install --lts
        
        # Set the installed version as the default
        nvm alias default $(nvm current)
        
        # Verify the installation
        # Verify Node.js and npm versions
        node_version=$(node -v)
        npm_version=$(npm -v)
        echo "Node.js version: $node_version"
        echo "npm version: $npm_version"
        echo "Node pack manager has been installed successfully."
        source ~/.profile
        source ~/.bashrc
        sleep 5
        exec "$SHELL"
    fi
    sleep 1
    clear
    
    
}

uninstall() {
    read -r -p "Are you sure you want to uninstall NVM, Node.js, and npm? (y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "Uninstalling NVM, Node.js, and npm..."
        
        # Remove NVM environment variables from .bashrc
        grep -vE 'export NVM_DIR="\$HOME\/.nvm"' "$HOME/.bashrc" > "$HOME/.bashrc.temp"
        grep -vE '\[ -s "\$NVM_DIR\/nvm.sh" \] && \. "\$NVM_DIR\/nvm.sh"' "$HOME/.bashrc.temp" > "$HOME/.bashrc"
        grep -vE '\[ -s "\$NVM_DIR\/bash_completion" \] && \. "\$NVM_DIR\/bash_completion"' "$HOME/.bashrc" > "$HOME/.bashrc.temp"
        
        # Remove NVM directory
        rm -rf "$HOME/.nvm"
        rm -rf "$HOME/.npm"
        rm "$HOME/.bashrc.temp"
        echo "NVM, Node.js, and npm have been uninstalled successfully."
        exec "$SHELL"
    else
        echo "Uninstallation canceled."
    fi
}



if [ "$input" = "install" ]; then
    installer
    elif [ "$input" = "uninstall" ]; then
    uninstall
else
    echo "Invalid input. Exiting..."
    exit 1
fi

