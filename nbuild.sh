
#!/bin/bash

# Usage:
#   bash <(curl -s https://raw.githubusercontent.com/peteha/labosinit/main/nbuild.sh)
#
# This script requires config.json in the same directory. If missing, it will be downloaded automatically.

## Setting Up OS Build Directory ##

# Ensure jq is installed
echo "## Checking if jq is installed... ##"

# Check if jq is not installed
if ! command -v jq >/dev/null 2>&1; then
  echo "## jq is not installed. Installing jq... ##"

  # Attempt to update package list and install jq
  if sudo apt-get update && sudo apt-get install -y jq; then
    echo "## jq successfully installed. ##"
  else
    # Print an error message and exit if the installation fails
    echo "## Failed to install jq. Please install it manually and re-run the script. ##"
    exit 1
  fi
else
  echo "## jq is already installed. Proceeding... ##"
fi

# Load configuration from JSON file
CONFIG_FILE="config.json"


# Check if the config file exists, if not, download it from GitHub
if [ ! -f "$CONFIG_FILE" ]; then
  echo "## Configuration file $CONFIG_FILE not found. Attempting to download from GitHub... ##"
  curl -fsSL -o "$CONFIG_FILE" "https://raw.githubusercontent.com/peteha/labosinit/main/config.json"
  if [ $? -ne 0 ]; then
    echo "## Failed to download $CONFIG_FILE. Please create it manually. ##"
    exit 1
  else
    echo "## Downloaded $CONFIG_FILE from GitHub. ##"
  fi
fi

# Parse values from JSON using jq
inst_pkgs=$(jq -r '.inst_pkgs' "$CONFIG_FILE")
bootfile=$(jq -r '.bootfile' "$CONFIG_FILE")
k8_params=$(jq -r '.k8_params' "$CONFIG_FILE")

# Validate the parsed values
if [[ -z "$inst_pkgs" || -z "$bootfile" || -z "$k8_params" ]]; then
  echo "## Missing required configuration values in $CONFIG_FILE. Please check the file. ##"
  exit 1
fi

# Define color codes
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
RESET="\033[0m"

# Prompt for user credentials with color
echo -e "${CYAN}## Please enter your credentials ##${RESET}"
read -rp "$(echo -e ${GREEN}Username:${RESET}) " user
read -rsp "$(echo -e ${GREEN}Password:${RESET}) " password
echo -e "\n${CYAN}## Thank you! Proceeding... ##${RESET}"

if id "$user" >/dev/null 2>&1; then
  echo -e "\n${RED}## User $user already exists. ##${RESET}"

  # Prompt to change password for existing user
  read -rp "$(echo -e ${CYAN}## Change existing user password? (default: Y): ${RESET})" usrchg
  usrchg=${usrchg:-Y}
  usrchg=$(echo "$usrchg" | tr '[:lower:]' '[:upper:]')

  if [ "$usrchg" == "Y" ]; then
    echo -e "${YELLOW}## Changing password for user $user... ##${RESET}"
    echo "$user:$password" | chpasswd
    echo -e "${GREEN}## Password successfully updated. ##${RESET}"
  else
    echo -e "${CYAN}## Password not changed. Proceeding... ##${RESET}"
  fi
else
  # Add new user
  echo -e "${CYAN}## User $user does not exist. Adding user... ##${RESET}"
  useradd "$user" --create-home --shell /bin/bash --groups sudo
  echo "$user:$password" | chpasswd

  # Configure sudo permissions
  if ! grep -Fxq "$user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo -e "${YELLOW}## Adding $user to sudoers with no password requirement... ##${RESET}"
    echo "$user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo -e "${GREEN}## User $user has been added to sudoers successfully. ##${RESET}"
  else
    echo -e "${CYAN}## User already has sudo privileges. ##${RESET}"
  fi
fi

# Configure SSH keys from GitHub
echo "## Configuring SSH keys for user $user ##"
curl -s "https://github.com/$user.keys" > "$user.keys"

if [ $? -eq 0 ]; then
  ssh_dir="/home/$user/.ssh"
  mkdir -p "$ssh_dir"
  auth_keys="$ssh_dir/authorized_keys"

  if grep -Fxq "$(cat "$user.keys")" "$auth_keys"; then
    echo "SSH key already exists in authorized_keys."
  else
    cat "$user.keys" >> "$auth_keys"
    echo "SSH key added successfully to authorized_keys."
  fi

  # Set proper permissions
  chown -R "$user:$user" "$ssh_dir"
  chmod 700 "$ssh_dir"
  chmod 600 "$auth_keys"
else
  echo "Failed to retrieve the SSH key. Please check your GitHub username."
fi

# Prompt and set hostname
read -rp "Hostname: " hostname
echo "## Setting hostname to $hostname ##"
hostnamectl set-hostname "$hostname"

# Configure Kubernetes boot parameters
echo "## Configuring Kubernetes parameters ##"
if [ -f "$bootfile" ]; then
  if ! grep -q "$k8_params" "$bootfile"; then
    echo "Adding Kubernetes parameters to $bootfile..."
    sed -i '$ s/$/ '"$k8_params"'/' "$bootfile"
    echo "Kubernetes parameters added to $bootfile."
  else
    echo "## Kubernetes parameters already exist in $bootfile ##"
  fi
else
  echo "## Bootfile not found ##"
fi

# Update APT repositories
echo "## Updating APT repositories ##"

# Special configuration for aarch64 with Ubuntu Jammy
if [ "$(uname -m)" == "aarch64" ] && [ "$VERSION_CODENAME" == "jammy" ]; then
  echo "## Setting a better mirror for aarch64 Ubuntu ##"
  sed -i 's,http://ports.ubuntu.com/ubuntu-ports,https://mirrors.ocf.berkeley.edu/ubuntu-ports,g' /etc/apt/sources.list

  echo "## Removing automatic restarts during updates ##"
  sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
  sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
fi

# Perform APT operations
echo "## Running APT update ##"
apt update

echo "## Installing packages ##"
if [[ -n $inst_pkgs ]]; then
  apt install -y $inst_pkgs
else
  echo "## No packages specified for installation ##"
fi

echo "## Running APT upgrade ##"
apt upgrade -y

# Clean APT cache
echo "## Cleaning APT cache ##"
apt clean

# Finishing up
echo "## System setup complete. Rebooting... ##"
reboot