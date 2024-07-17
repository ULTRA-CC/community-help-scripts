#!/bin/bash

# Python 3 and Pip Installer for Ultra.cc services by Itachi
# This installs python 3, pip and pyenv on your slot using pyenv

# Unofficial Script warning
clear
echo "This is the Python and PIP Installer!"
echo ""
printf "\033[0;31mDisclaimer: This installer is unofficial and Ultra.cc staff will not support any issues with it\033[0m\n"
read -r -p "Type confirm if you wish to continue: " input
if [ ! "$input" = "confirm" ]; then
    exit
fi

# Install pyenv

echo "Installing pyenv..."
sleep 1
curl https://pyenv.run | bash

# Add pyenv to .profile
grep -qxF 'export PYENV_ROOT="$HOME/.pyenv"' "${HOME}/.profile" || echo 'export PYENV_ROOT="$HOME/.pyenv"' >>"${HOME}/.profile"
# Check value present or not if not add it
grep -qxF 'export PATH="$PYENV_ROOT/bin:$PATH"' "${HOME}/.profile" || echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >>"${HOME}/.profile"
#  Check value present or not if not add it
grep -qxF 'eval "$(pyenv init --path)"' "${HOME}/.profile" || echo 'eval "$(pyenv init --path)"' >>"${HOME}/.profile"
# Add pyenv to .bashrc
# Check value present or not if not add it
# grep -qxF "eval \"\$(pyenv init -)\"" "${HOME}/.bashrc" || echo 'eval "$(pyenv init -)"' >> "${HOME}/.bashrc"

# Load new profile
source "${HOME}/.profile"
# Load new bashrc
# source "${HOME}/.bashrc"

# Install xxenv-latest
git clone https://github.com/momo-lab/xxenv-latest.git "$(pyenv root)"/plugins/pyenv-latest

# Python Version Chooser
clear
echo "Choose between 3.8, 3.9, 3.10, latest or 2.7."
echo "1 = Python 3.8"
echo "2 = Python 3.9"
echo "3 = Python 3.10"
echo "4 = Latest Python 3 release"
echo "5 = Python 2.7"
echo "We recommend using Python 3.8 as your default Python version."

while true; do
    read -r -p "Enter your response here: " pyver
    case $pyver in
        1)
            "$HOME"/.pyenv/bin/pyenv install 3.8
            pyenv global 3.8
            break
        ;;
        2)
            "$HOME"/.pyenv/bin/pyenv install 3.9
            pyenv global 3.9
            break
        ;;
        3)
            "$HOME"/.pyenv/bin/pyenv install 3.10
            pyenv global 3.10
            break
        ;;
        4)
            latest_version=$(pyenv install --list | awk '$1 ~ /^[0-9]+\.[0-9]+\.[0-9]+$/ {latest=$1} END {print latest}')
            "$HOME"/.pyenv/bin/pyenv install $latest_version
            pyenv global $latest_version
            break
        ;;
        5)
            "$HOME"/.pyenv/bin/pyenv install 2.7
            break
        ;;
        *)
            echo "Invalid Option. Try again..."
        ;;
    esac
done

# Check Python
clear
echo "Getting python version..."
command -v python
python -m pip -V
sleep 2

# Updating all pip packages

echo "Updating all pip packages..."
pip install --upgrade pip
pip install pip-review --auto
pip-review --auto
pip list --format=freeze | cut -d'=' -f1 | xargs -n1 pip install --upgrade

#Cleanup and Exit
clear
echo "Done. Install successful."
echo "Please execute the SSH command given below to load your newly installed python."
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo "source ~/.profile"
printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' -
echo
exit