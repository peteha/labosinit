#!/bin/sh
sudo su
setuser=$1
TIMEZONE="Australia/Brisbane"

# Add User
adduser $setuser
usermod -aG sudo $setuser

# Set no sudo passwd
echo "$setuser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
sudo -k

# Set Timezone
echo $TIMEZONE > /etc/timezone
cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime


# Update OS
apt update
apt upgrade -y

# Install Base Packages
apt install certbot python3-certbot-dns-cloudflare nfs-common

if [ $2 = 'docker' ]
then
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	echo \
	  "deb [arch=arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
	  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	apt-get update
	apt-get install docker-ce docker-ce-cli containerd.io
	sudo groupadd docker
	usermod -aG docker $setuser
