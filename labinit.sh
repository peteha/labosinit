#!/bin/sh

## Created by Peter Hauck for lab build.
while getopts u:p:d:c:r:t o
do	case "$o" in
	u)	setuser="$OPTARG";;
	p)  setpasswd="$OPTARG";;
	d)	dockerinst="yes";;
	c)  certbotinst=$OPTARG;;
	t)  TIMEZONE="Australia/Brisbane";;
	r)  rebooinst="yes";;
	[?])	print >&2 "Usage: $0 [-u user] [-p passwd] [-d] [-c cloudflarednsapikey] [-r] ..."
		exit 1;;
	esac
done


# Add User
if [ -z $setuser ]
then 
	useradd $setuser --create-home --shell /bin/bash --groups sudo
	echo "$setuser:$setpasswd" | chpasswd
	# Set no sudo passwd
	echo "$setuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

if [ -z $TIMEZONE ]
then
	# Set Timezone
	echo "## Setting Timezone $TIMEZONE ##"
	echo $TIMEZONE > /etc/timezone
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
fi

# Update OS
#apt update
#apt upgrade -y

# Install Base Packages
#apt install certbot python3-certbot-dns-cloudflare nfs-common

if [ -z $dockerinst ]
then
	echo "## Intsalling Docker ##"
	curl -fsSL https://get.docker.com -o get-docker
	sh get-docker.sh
	groupadd docker
	usermod -aG docker $setuser
fi
if [ -z $rebootinst ]
then
    echo "## Rebooting ##"
	sleep 3s
	#reboot
fi
