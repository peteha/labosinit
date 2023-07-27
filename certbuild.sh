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
    if [ ! -f /opt/certs/certadmin.env ]
    then
        echo -n "Cert Admin: "
        read certadmin
        mkdir -p /home/peteha/cfcred
		echo certadmin = "$certadmin" > /opt/certs/certadmin.env
    fi
    source /opt/certs/certadmin.env set
    echo $certadmin
    certs="/opt/certs/certlist"
    certlines=$(cat $certs)
    for line in $certlines
    do
		echo "## Creating Key for Host $line ##"
		sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /home/peteha/cfcred/cf-api-token.ini --dns-cloudflare-propagation-seconds 20 -d $line -m $certadmin --agree-tos -n
        echo "Copying certs for $line"
        mkdir -p $certdir
        bash -c "cat /etc/letsencrypt/live/$line/fullchain.pem /etc/letsencrypt/live/$line/privkey.pem >$certdir/$line.cert"
        bash -c "cat /etc/letsencrypt/live/$line/fullchain.pem >$certdir/$line-fullchain.cert"
        bash -c "cat /etc/letsencrypt/live/$line/privkey.pem >$certdir/$line-privkey.key"
        chown -R $username:$username $certdir
    done
fi
