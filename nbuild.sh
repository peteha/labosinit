
k8_params=$(jq -r '.k8_params' "$CONFIG_FILE")

#!/bin/bash

# Usage:
#   bash <(curl -s https://raw.githubusercontent.com/peteha/labosinit/main/nbuild.sh)
#
# This script requires config.json in the same directory. If missing, it will be downloaded automatically.

set -euo pipefail

# Color codes
GREEN="\033[1;32m"
CYAN="\033[1;36m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

CONFIG_FILE="config.json"
GITHUB_REPO="peteha/labosinit"

function error_exit {
  echo -e "${RED}Error: $1${RESET}" >&2
  exit 1
}

function ensure_jq_installed {
  if ! command -v jq >/dev/null 2>&1; then
    echo -e "${CYAN}## jq not found. Installing... ##${RESET}"
    sudo apt-get update && sudo apt-get install -y jq || error_exit "Failed to install jq."
  else
    echo -e "${CYAN}## jq is already installed. ##${RESET}"
  fi
}

function ensure_config {
  if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${CYAN}## $CONFIG_FILE not found. Downloading from GitHub... ##${RESET}"
    curl -fsSL -o "$CONFIG_FILE" "https://raw.githubusercontent.com/$GITHUB_REPO/main/config.json" || error_exit "Could not download $CONFIG_FILE."
    echo -e "${GREEN}## Downloaded $CONFIG_FILE. ##${RESET}"
  fi
}

function parse_config {
  inst_pkgs=$(jq -r '.inst_pkgs' "$CONFIG_FILE")
  bootfile=$(jq -r '.bootfile' "$CONFIG_FILE")
  k8_params=$(jq -r '.k8_params' "$CONFIG_FILE")
  if [[ -z "$inst_pkgs" || -z "$bootfile" || -z "$k8_params" ]]; then
    error_exit "Missing required configuration values in $CONFIG_FILE."
  fi
}

function prompt_user_credentials {
  echo -e "${CYAN}## Please enter your credentials ##${RESET}"
  read -rp "$(echo -e ${GREEN}Username:${RESET}) " user
  read -rsp "$(echo -e ${GREEN}Password:${RESET}) " password
  echo -e "\n${CYAN}## Thank you! Proceeding... ##${RESET}"
}

function create_or_update_user {
  if id "$user" >/dev/null 2>&1; then
    echo -e "\n${YELLOW}## User $user already exists. ##${RESET}"
    read -rp "$(echo -e ${CYAN}## Change existing user password? (default: Y): ${RESET})" usrchg
    usrchg=${usrchg:-Y}
    usrchg=$(echo "$usrchg" | tr '[:lower:]' '[:upper:]')
    if [ "$usrchg" == "Y" ]; then
      echo "$user:$password" | chpasswd
      echo -e "${GREEN}## Password updated. ##${RESET}"
    else
      echo -e "${CYAN}## Password not changed. ##${RESET}"
    fi
  else
    echo -e "${CYAN}## Creating user $user... ##${RESET}"
    useradd "$user" --create-home --shell /bin/bash --groups sudo || error_exit "Failed to create user."
    echo "$user:$password" | chpasswd
    echo -e "${GREEN}## User created. ##${RESET}"
  fi

  # Sudoers
  if ! grep -Fxq "$user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "$user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    echo -e "${GREEN}## Sudoers updated. ##${RESET}"
  fi
}

function setup_ssh_keys {
  echo -e "${CYAN}## Configuring SSH keys for $user ##${RESET}"
  curl -fsSL "https://github.com/$user.keys" -o "/tmp/$user.keys" || error_exit "Could not fetch SSH keys from GitHub."
  ssh_dir="/home/$user/.ssh"
  auth_keys="$ssh_dir/authorized_keys"
  mkdir -p "$ssh_dir"
  touch "$auth_keys"
  if [ -s "/tmp/$user.keys" ]; then
    while IFS= read -r key; do
      if ! grep -Fxq "$key" "$auth_keys" 2>/dev/null; then
        echo "$key" >> "$auth_keys"
        echo "SSH key added."
      fi
    done < "/tmp/$user.keys"
  else
    echo -e "${YELLOW}No SSH keys found for $user on GitHub.${RESET}"
  fi
  chown -R "$user:$user" "$ssh_dir"
  chmod 700 "$ssh_dir"
  chmod 600 "$auth_keys"
  rm -f "/tmp/$user.keys"
}

function set_hostname {
  read -rp "Hostname: " hostname
  echo -e "${CYAN}## Setting hostname to $hostname ##${RESET}"
  hostnamectl set-hostname "$hostname"
}

function configure_k8s_boot {
  echo -e "${CYAN}## Configuring Kubernetes parameters ##${RESET}"
  if [ -f "$bootfile" ]; then
    if ! grep -q "$k8_params" "$bootfile"; then
      sed -i '$ s/$/ '"$k8_params"'/' "$bootfile"
      echo "Kubernetes parameters added to $bootfile."
    else
      echo "Kubernetes parameters already exist in $bootfile."
    fi
  else
    echo -e "${YELLOW}Bootfile $bootfile not found.${RESET}"
  fi
}

function apt_update_upgrade {
  echo -e "${CYAN}## Updating APT repositories ##${RESET}"
  # Ubuntu 24.04: No special aarch64/jammy logic needed
  apt update
  if [[ -n $inst_pkgs ]]; then
    apt install -y $inst_pkgs
  else
    echo -e "${YELLOW}No packages specified for installation.${RESET}"
  fi
  apt upgrade -y
  apt clean
}

function main {
  ensure_jq_installed
  ensure_config
  parse_config
  prompt_user_credentials
  create_or_update_user
  setup_ssh_keys
  set_hostname
  configure_k8s_boot
  apt_update_upgrade
  echo -e "${GREEN}## System setup complete. Rebooting... ##${RESET}"
  reboot
}

main