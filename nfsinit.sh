#!/bin/sh

## Created by Peter Hauck for lab build.
while getopts u:h:i:r o
do	case "$o" in
	u)	setuser="$OPTARG";;
	h)  hostname="$OPTARG";;
	i)  nasip="$OPTARG";;
	r)  rebootinst="yes";;
	[?])	print >&2 "Usage: $0 [-u user] [-p passwd] [-d] [-c cloudflarednsapikey] [-r] ..."
		exit 1;;
	esac
done

apt update
apt install nfs-common -y

# Set FSTAB
if [ ! -z ${hostname} ] && [ ! -z ${nasip} ] 
then
	echo "## Setup Up Shares ##"
	mkdir /nfs
	mkdir /nfs/media 
	echo "$nasip:/volume1/Media    /nfs/media   nfs auto,nofail,noatime,nolock,intr,tcp,users,x-systemd.automount,actimeo=1800 0 0" >> /etc/fstab
	mkdir /nfs/pggbnet
	echo "$nasip:/volume1/pggbnet  /nfs/pggbnet    nfs auto,nofail,noatime,nolock,intr,tcp,users,x-systemd.automount,actimeo=1800 0 0" >> /etc/fstab
	mkdir /nfs/images
	echo "$nasip:/volume1/Images   /nfs/images  nfs auto,nofail,noatime,nolock,intr,tcp,users,x-systemd.automount,actimeo=1800 0 0" >> /etc/fstab
	mkdir /nfs/data
	echo "$nasip:/volume1/$hostname   /nfs/data  nfs auto,nofail,noatime,nolock,intr,tcp,users,x-systemd.automount,actimeo=1800 0 0" >> /etc/fstab
	mount -a
fi


if [ ! -z ${rebootinst} ]
then
	echo "## Rebooting $rebootinst ##"
	sleep 3s
	reboot
fi