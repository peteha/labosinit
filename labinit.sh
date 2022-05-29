#!/bin/sh

## Created by Peter Hauck for lab build.
while getopts u:p:h:drtnmakwf o
do	case "$o" in
	u)  setuser="$OPTARG";;
	p)  setpasswd="$OPTARG";;
	h)  sethostname="$OPTARG";;
	n)  noupt="yes";;
	d)  dockerinst="yes";;
	m)  netdata="yes";;
	t)  TIMEZONE="Australia/Brisbane";;
	r)  rebootinst="yes";;
	a)  adduser="yes";;
	k)  setk8param="yes";;
	w)  nowireless="yes";;
	f)  fixdhcp="yes";;
	[?])	print >&2 "Usage: $0 [-u user] [-p passwd] [-d] [-r] ..."
		exit 1;;
	esac
done

# Add User
if [ ! -z ${adduser} ]
then
	if [ ! -z ${setpasswd} ]
	then
		echo "## Adding User $setuser ##"
		useradd $setuser --create-home --shell /bin/bash --groups sudo
		echo "$setuser:$setpasswd" | chpasswd
		# Set no sudo passwd
		echo "$setuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
		mkdir -p ~/.ssh
		echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJZ9XR6ETVk9UkAd9glryFPO9TTLNiBx5y/11BC50QJZ peteha@Dreadnought.local >> ~/.ssh/authorized_keys
	fi
fi

if [ ! -z ${TIMEZONE} ]
then
	# Set Timezone
	echo "## Setting Timezone $TIMEZONE ##"
	timedatectl set-timezone $TIMEZONE
fi

if [ ! -z ${setk8param} ]
then
	# K8 Parameters
	echo "## Setting K8 Parameters ##"
    sudo sed -i -e 's/$/ cgroup_enable=memory cgroup_memory=1/' /boot/firmware/cmdline.txt
	cat /boot/firmware/cmdline.txt
fi

if [ ! -z ${nowireless} ]
then
	# K8 Parameters
	echo "## Setting Wireless Off ##"
	echo "dtoverlay=disable-wifi" >> /boot/firmware/usercfg.txt
	echo "dtoverlay=disable-bt" >> /boot/firmware/usercfg.txt
	cat /boot/firmware/usercfg.txt
fi

if [ ! -z ${sethostname} ]
then
	# Set Hostname
	echo "## Setting Hostname $sethostname ##"
	hostnamectl set-hostname $sethostname
fi

if [ ! -z ${fixdhcp} ]
then
	# Fix DHCP Options
	cat $(dirname "$0")/10-rpi-ethernet-eth0.yaml > /etc/netplan/10-rpi-ethernet-eth0.yaml
	echo "## DHCP Options for MAC identifier added ##"
	cat /etc/netplan/10-rpi-ethernet-eth0.yaml
	echo "\n"
fi

if [ ! -z ${noupt} ]
then
		apt update
		apt upgrade -y
		# Install Base Packages
		apt install certbot python3-certbot-dns-cloudflare nfs-common python3-pip cockpit -y
fi

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
#if [ ! -z ${netdata} ]
#then
#	echo "## Installing Netdata $netdata ##"
#        bash <(curl -Ss https://my-netdata.io/kickstart.sh)
#
#fi
if [ ! -z ${rebootinst} ]
then
	echo "## Rebooting $rebootinst ##"
	sleep 3s
	reboot
fi