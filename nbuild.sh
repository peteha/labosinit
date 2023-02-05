#!/bin/bash
echo "## Setting Up OS Build Directory ##"
# Create Base DIR

## Load hostbuild variables

source build.sh
. /etc/lsb-release

## Establish user credentials

read -rp "Username: " user
read -rsp "Password: " password

if id "$user" >/dev/null 2>&1; then
  usrchgdef="Y"
  echo
  read -rp "Change existing user password: (default: $usrchgdef): " usrchg
  usrchg=${usrchg:-$usrchgdef}
  usrchg=$(echo "$usrchg" | tr '[:lower:]' '[:upper:]')
  if [ "$usrchg" == "Y" ]; then
    echo "User $user exists. Changing password..."
    echo "$user:$password" | chpasswd
  else
    echo "## Password not change ##"
  fi
else
  echo
  echo "User $user does not exist. Adding user and password..."
  useradd "$user" --create-home --shell /bin/bash --groups sudo
  echo "$user:$password" | chpasswd
  if grep -Fxq "$user ALL=(ALL) NOPASSWD: ALL" /etc/sudoers
    then
      echo "## Already SUDO ##"
    else
      echo "Set SUDO Happening for $user"
      echo "$user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
    fi
fi
echo "## Getting SSH Keys ##"
curl -s "https://github.com/$user.keys" > "$user.keys"
gitpk_dl=$(cat "$user.keys")
if [ $? -eq 0 ] ; then
  if grep -Fxq "$gitpk_dl" "/home/$user/.ssh/authorized_keys"; then
    echo "## Already in authorized_keys ##"
  else
    mkdir -p "/home/$user/.ssh"
    cat "$user.keys" >> "/home/$user/.ssh/authorized_keys"
    echo "The SSH key was added successfully."
  fi
else
  echo "Failed to retrieve the SSH key. Please check your GitHub username."
fi
read -rp "Hostname: " hostname
echo "## Setting Hostname to $hostname ##"
hostnamectl set-hostname "$hostname"

echo "## Setting K8 parameters ##"
# shellcheck disable=SC2154
if [ -f "$bootfile" ]; then
  if grep -q "$k8_params" "$bootfile"; then
    echo
    echo "## Params for K8 already in $bootfile ##"
  else
    sed -i '$ s/$/ '"$k8_params"'/' "$bootfile"
    echo "## Params for K8 added to $bootfile ##"
  fi
else
  echo "## bootfile not found ##"
fi
echo
echo "Updating apt"
declare -f rel
declare -f baserel
baserel=$baserelease
rel=$DISTRIB_RELEASE

if (( $(echo "$baserel < $rel" | bc -l) )); then
  echo "## Removing Restart from Updates ##"
  sed -i 's/#$nrconf{restart} = '"'"'i'"'"';/$nrconf{restart} = '"'"'a'"'"';/g' /etc/needrestart/needrestart.conf
  sed -i "s/#\$nrconf{kernelhints} = -1;/\$nrconf{kernelhints} = -1;/g" /etc/needrestart/needrestart.conf
fi

echo "## APT Update ##"
apt update
# shellcheck disable=SC2070
echo "## pkgs being installed ##"
if [[ -n ${inst_pkgs} ]]; then
  apt install $inst_pkgs -y
else
  echo "## Install Packages not defined ##"
fi
echo "## APT Upgrade ##"
apt upgrade -y
sudo apt clean
reboot



