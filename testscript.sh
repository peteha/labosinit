#!/bin/bash
echo "## Setting Up OS Build Directory ##"
# Create Base DIR
mkdir -p /opt/osbuild
cd /opt/osbuild
## 
echo "## Installing Scripts ##"
curl -fs https://raw.githubusercontent.com/peteha/labosinit/main/osinit.sh --output osinit.sh
chmod +x osinit.sh
curl -fs https://raw.githubusercontent.com/peteha/labosinit/main/certbuild.sh --output certbuild.sh
chmod +x certbuild.sh

if [ ! -f hostbuild.env ]; then
    echo "## No hostbuild.env file available ##"
    curl -fs https://raw.githubusercontent.com/peteha/labosinit/main/hostbuild.env --output hostbuild.env
    sudo apt install nano
    nano hostbuild.env
fi

echo "## Using hostbuild.env ##"
source hostbuild.env

cur_tz=`cat /etc/timezone`
fullhn="$buildhostname.$domain"

# Install NTP #
ntpstatus=$(systemctl is-active ntp)
if [[ $inst_ntp == "True" ]]; then
    if [[ ! $ntpstatus == "active" ]]; then
        sudo apt install ntp -y
    fi
    sed -i '/^pool /d' /etc/ntp.conf
    echo "pool $ntpserver" >> /etc/ntp.conf
    systemctl restart ntp
    echo
    echo "## NTP Installed and using $ntpserver ##"
fi