#!/bin/sh

## Created by Peter Hauck for lab build.
while getopts u:p:h:dc:rtn o
do	case "$o" in
	u)	setuser="$OPTARG";;
	p)  setpasswd="$OPTARG";;
	c)  certbotinst="$OPTARG";;
	h)  sethostname="$OPTARG";;
	n)  noupt="yes";;
	d)	dockerinst="yes";;
	t)  TIMEZONE="Australia/Brisbane";;
	r)  rebootinst="yes";;
	[?])	print >&2 "Usage: $0 [-u user] [-p passwd] [-d] [-c cloudflarednsapikey] [-r] ..."
		exit 1;;
	esac
done

# Add User
if [ ! -z ${setpasswd} ]
then
	echo "## Adding User $setuser ##" 
	useradd $setuser --create-home --shell /bin/bash --groups sudo
	echo "$setuser:$setpasswd" | chpasswd
	# Set no sudo passwd
	echo "$setuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

if [ ! -z ${TIMEZONE} ]
then
	# Set Timezone
	echo "## Setting Timezone $TIMEZONE ##"
	echo $TIMEZONE > /etc/timezone
	cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
fi

if [ ! -z ${sethostname} ]
then
	# Set Timezone
	echo "## Setting Hostname $sethostname ##"
	hostnamectl set-hostname $sethostname
fi

apt update
apt upgrade -y

	# Install Base Packages
apt install certbot python3-certbot-dns-cloudflare nfs-common python3-pip -y


if [ ! -z ${dockerinst} ]
then
	echo "## Intsalling Docker $dockerinst ##"
	curl -fsSL https://get.docker.com -o get-docker.sh
	chmod +x get-docker.sh
	./get-docker.sh
	if [ -z ${setuser} ]
	then 
		echo "## No User set - please set with a -u option  ##"
		exit
	fi
	usermod -aG docker $setuser
fi
if [ ! -z ${rebootinst} ]
then
	echo "## Rebooting $rebootinst ##"
	sleep 3s
	reboot
fi
