#!/bin/sh

## Created by Peter Hauck for lab build.
while getopts u:p:d:c:r o
do	case "$o" in
	u)	setuser="$OPTARG";;
	p)  setpasswd="$OPTARG";;
	d)	dockerinst="yes";;
	c)  certbotinst=$OPTARG;;
	r)  rebooinst="yes";;
	[?])	print >&2 "Usage: $0 [-u user] [-p passwd] [-d] [-c cloudflarednsapikey] [-r] ..."
		exit 1;;
	esac
done
TIMEZONE="Australia/Brisbane"

# Add User
if [ setuser ]
then 
	useradd $setuser --create-home --shell /bin/bash --groups sudo
	echo "$setuser:$setpasswd" | sudo chpasswd
	# Set no sudo passwd
	echo "$setuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
	sudo -k
fi

# Set Timezone
echo $TIMEZONE > /etc/timezone
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime


# Update OS
apt update
apt upgrade -y

# Install Base Packages
apt install certbot python3-certbot-dns-cloudflare nfs-common

if [ dockerinst ]
then
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo \
	  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt-get update
	apt-get install docker-ce docker-ce-cli containerd.io -y
	groupadd docker
	usermod -aG docker $setuser
fi
if [ rebootinst ]
then
	reboot
fi
