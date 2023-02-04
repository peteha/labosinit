#!/bin/bash
echo "## Setting Up OS Build Directory ##"
# Create Base DIR
mkdir -p /opt/osbuild
cd /opt/osbuild

## Install host build file

if [ ! -f hostbuild.env ]; then
    echo "## No hostbuild.env file available ##"
    curl -fs https://raw.githubusercontent.com/peteha/labosinit/main/hostbuild.env --output hostbuild.env
    ## nano hostbuild.env
fi

## Load hostbuild variables

source hostbuild.env

## Establish user credentials

read -p "Username: " user
read -sp "Password: " password

if id "$user" >/dev/null 2>&1; then
  usrchgdef = "Y"
  read -p "Change existing user password: (default: $usrchgdef): " usrchg
  usrchg=${usrchg:-$usrchgdef}
  usrchg=$(echo "$usrchg" | tr '[:lower:]' '[:upper:]')
  if usrchg = "Y"; then
    echo "User $user exists. Changing password..."
    echo "$user:$password" | chpasswd
  fi
else
  echo "User $user does not exist. Adding user and password..."
  useradd "$user"
  echo "$user:$password" | chpasswd
  usermod -aG sudo "$user"
fi
