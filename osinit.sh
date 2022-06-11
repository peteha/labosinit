#!/bin/bash

mkdir -p /home/$username/osbuild
cd /home/$username/osbuild
## 
curl -fs https://raw.githubusercontent.com/peteha/labosinit/main/osinit.sh --output osinit.sh
chmod +x osinit.sh

if [ ! -f hostbuild.env ]; then
    echo ## No hostbuild.env file available ##
    curl -fs https://raw.githubusercontent.com/peteha/labosinit/main/hostbuild.env --output hostbuild.env
    sudo apt install nano
    nano hostbuild.env
fi

source hostbuild.env

cur_tz=`cat /etc/timezone`
fullhn="$buildhostname.$domain"

echo "## Setting Up Environment ##"
echo
## Create new User
if id "$username" &>/dev/null; then
    echo -n "Enter new password for $username (blank to leave the same): "
    read -s passwd
    newuser=""
else
    echo -n "Enter Password for $username: "
    read -s passwd
    newuser=True
fi
echo

if [ ! -z ${newuser} ]
	then
	    echo "## Adding User '$username' ##"
		useradd $username --create-home --shell /bin/bash --groups sudo
		echo "$username:$passwd" | sudo chpasswd
fi
if [[ "$sudoers" == "True" ]]
    then
		# Set no sudo passwd
        if sudo grep -Fxq "$username ALL=(ALL) NOPASSWD: ALL" /etc/sudoers
            then
                echo "## Already SUDO ##"
            else
                echo "Set SUDO Happening for $username"
                sudo echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        fi
fi
if [[ "$gitpk" == "True" ]]
    then
		gitpk_dl=`curl -s https://github.com/$username.keys`
        if [[ $gitpk_dl != "Not Found" ]]
        then
            if grep -Fxq "$gitpk_dl" /home/$username/.ssh/authorized_keys
                then
                    echo "## Already in authorized_keys ##"
                else
                    echo "Adding authorized_keys for $username"
                    sudo mkdir -p /home/$username/.ssh
                    sudo echo "$gitpk_dl" >> /home/$username/.ssh/authorized_keys
                    sudo chown $username:$username /home/$username/.ssh/authorized_keys
            fi
        else
            echo "## No Keys in GitHub for $username ##"
        fi
fi
echo
echo
echo "Username will be:             $username"
## Hostname Setup
if [[ "$buildhostname" != "$HOSTNAME" ]]
    then
        echo "## Setting Hostname $buildhostname ##"
	    sudo hostnamectl set-hostname $buildhostname
    else
        buildhostname=$"$HOSTNAME"
    fi
echo "Hostname will be:             $buildhostname"
sed -i.bak "/buildhostname=/c\buildhostname=$buildhostname" hostbuild.env && rm hostbuild.env.bak

if [[ "$cur_tz" != "$tz" ]]
    then
        echo "## Setting Timezone $tz ##"
	    sudo timedatectl set-timezone $tz
    else
        tz=$"$cur_tz"
    fi
echo "Timezone will be:             $tz"

if [[ $createcert == "True" ]]
then
    if [ ! -f /home/$username/cfcred/cf-api-token.ini ]
    then
        echo -n "Enter CloudFlare API Token: "
        read cfapitoken
        mkdir -p /home/$username/cfcred
		echo dns_cloudflare_api_token = "$cfapitoken" > /home/$username/cfcred/cf-api-token.ini
		chmod 600 /home/$username/cfcred/cf-api-token.ini
    fi
    sudo apt install certbot python3-certbot-dns-cloudflare python3-pip -y
	if [ ! -z ${buildhostname} ]
	then
		echo "## Creating Key for Host $buildhostname"
        ssl_admin=$"$ssl_admin_pre$domain"
		sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /home/$username/cfcred/cf-api-token.ini -d $fullhn -m $ssl_admin --agree-tos -n
        if [ -f /etc/letsencrypt/live/$fullhn/fullchain.pem ]
        then
            echo "Copying certs for docker"
            mkdir -p $certdir
            bash -c "cat /etc/letsencrypt/live/$fullhn/fullchain.pem /etc/letsencrypt/live/$fullhn/privkey.pem >$certdir/$fullhn.cert"
            bash -c "cat /etc/letsencrypt/live/$fullhn/fullchain.pem >$certdir/$fullhn-fullchain.cert"
            bash -c "cat /etc/letsencrypt/live/$fullhn/privkey.pem >$certdir/$fullhn-privkey.key"
            chown -R $username:$username $certdir
        fi
	fi
fi
# Install Cockpit #
if [[ $inst_cockpit == "True" ]]
then
    sudo apt install cockpit -y
    if [ -f /etc/letsencrypt/live/$fullhn/fullchain.pem ]
    then
        echo "Copying certs for Cockpit"
        bash -c "cat /etc/letsencrypt/live/$fullhn/fullchain.pem /etc/letsencrypt/live/$fullhn/privkey.pem >/etc/cockpit/ws-certs.d/$fullhn.cert"
        sudo systemctl stop cockpit.service
        sudo systemctl start cockpit.service
    fi
fi

# Install Docker

if [[ $inst_docker == "True" ]]
    then
        if [[ $(which docker) && $(docker --version) ]]
        then
            echo "Docker installed"
        else
            echo "## Installing Docker ##"
            curl -sSL https://get.docker.com | sh
            groupadd docker
            usermod -aG docker $username
        fi
    if [[ $inst_dockercompose == "True" ]]
    then
        pip3 install docker-compose
    fi
fi

if [[ $update == "True" ]]
then
		sudo apt update
		sudo apt upgrade -y
		# Install Base Packages
		sudo apt install $inst_pkgs -y
fi