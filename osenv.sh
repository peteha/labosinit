#!/bin/bash
source hostbuild.env
source .env
echo "## Setting Up Environment ##"
echo
## Hostname Setup
echo Hostname is $HOSTNAME
echo Config Hostname is $hn
echo
if [ -z "$hn" ]
    then
        echo -n "Enter new hostname: "
        read -r hn
    fi
if [[ "$hn" != "$HOSTNAME" ]]
    then
        echo "## Setting Hostname $hn ##"
	    hostnamectl set-hostname $hn
    fi
hn=$"$HOSTNAME"
echo "Hostname will be $hn"
sed -i.bak '/hn=/c\hn=rrr' hostbuild.env && rm hostbuild.env.bak




#select yn in "Yes" "No"; do
#    case $yn in
#        Yes ) make install; break;;
#        No ) exit;;
#    esac
#done