#!/bin/bash
echo "## Setting Up OS Build Directory ##"
# Create Base DIR
mkdir -p /opt/osbuild
cd /opt/osbuild || exit

## Install host build file

if [ ! -f build.sh ]; then
    echo "## No hostbuild.env file available ##"
    curl -fs "https://raw.githubusercontent.com/peteha/labosinit/main/hostbuild.env --output build.sh"
    ## nano hostbuild.env
fi

## Load hostbuild variables

source hostbuild.env

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
curl -s "https://github.com/$user.keys" > "/tmp/$user.keys"
gitpk_dl=$(cat "/tmp/$user.keys")
if [ $? -eq 0 ] ; then
  if grep -Fxq "$gitpk_dl" "/home/$user/.ssh/authorized_keys"; then
    echo "## Already in authorized_keys ##"
  else
    mkdir -p "/home/$user/.ssh"
    cat "/tmp/$user.keys" >> "/home/$user/.ssh/authorized_keys"
    echo "The SSH key was added successfully."
  fi
else
  echo "Failed to retrieve the SSH key. Please check your GitHub username."
fi
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
apt update
if [ -z "${!inst_pkgs}" ]; then
  echo "## Package list does not exist ##"
else
  apt install $inst_pkgs -y
fi

