#!/bin/bash
if [ -f /opt/certs/certlist ]
then
    if [ ! -f ~/cfcred/cf-api-token.ini ]
    then
        echo -n "Enter CloudFlare API Token: "
        read cfapitoken
        mkdir -p ~/cfcred
		echo dns_cloudflare_api_token = "$cfapitoken" > ~/cfcred/cf-api-token.ini
		chmod 600 ~/cfcred/cf-api-token.ini
    fi
	certs="/opt/certs/certlist"
    certlines=$(cat $certs)
    for line in $certlines
    do
		echo "## Creating Key for Host $line"
        ssl_admin="admin@pggb.net"
		sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/cfcred/cf-api-token.ini -d $line -m $ssl_admin --agree-tos -n
        if [ -f /etc/letsencrypt/live/$line/fullchain.pem ]
        then
            echo "Copying certs for docker"
            mkdir -p $certdir
            bash -c "cat /etc/letsencrypt/live/$line/fullchain.pem /etc/letsencrypt/live/$line/privkey.pem >$certdir/$line.cert"
            bash -c "cat /etc/letsencrypt/live/$line/fullchain.pem >$certdir/$line-fullchain.cert"
            bash -c "cat /etc/letsencrypt/live/$line/privkey.pem >$certdir/$line-privkey.key"
            chown -R $username:$username $certdir
        fi
    done
fi