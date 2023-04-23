#!/bin/bash
certdir="/opt/certs"
if [ -f /opt/certs/certlist ]
then
    if [ ! -f /home/peteha/cfcred/cf-api-token.ini ]
    then
        echo -n "Enter CloudFlare API Token: "
        read cfapitoken
        mkdir -p /home/peteha/cfcred
		echo dns_cloudflare_api_token = "$cfapitoken" > /home/peteha/cfcred/cf-api-token.ini
		chmod 600 /home/peteha/cfcred/cf-api-token.ini
    fi
	certs="/opt/certs/certlist"
    certlines=$(cat $certs)
    echo -n "Cert Admin: "
    read ssl_admin
    for line in $certlines
    do
		echo "## Creating Key for Host $line ##"
		sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /home/peteha/cfcred/cf-api-token.ini -d $line -m $ssl_admin --agree-tos -n
        if [ -f /etc/letsencrypt/live/$line/fullchain.pem ]
        then
            echo "Copying certs for $line"
            mkdir -p $certdir
            bash -c "cat /etc/letsencrypt/live/$line/fullchain.pem /etc/letsencrypt/live/$line/privkey.pem >$certdir/$line.cert"
            bash -c "cat /etc/letsencrypt/live/$line/fullchain.pem >$certdir/$line-fullchain.cert"
            bash -c "cat /etc/letsencrypt/live/$line/privkey.pem >$certdir/$line-privkey.key"
            chown -R $username:$username $certdir
        fi
    done
fi
