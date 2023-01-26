#!/bin/bash
source hostbuild.env
if [ ! -f ~/cfcred/cf-api-token.ini ]
then
    printf "Enter CloudFlare API Token: "
    read cfapitoken
    mkdir -p ~/cfcred
	printf "dns_cloudflare_api_token = $cfapitoken" > ~/cfcred/cf-api-token.ini
	chmod 600 ~/cfcred/cf-api-token.ini
    printf "## Cloud Flare Token Added to ~/cfcred/cf-api-token.ini ##\n"
fi
if ! command -v certbot &> /dev/null; then
    echo "## No certbot installed ##"
    exit
fi
if [ ! -z ${buildhostname} ]
then
    fullhn=$buildhostname.$domain
    ssl_admin=$"$ssl_admin_pre$domain"
	printf "## Creating Key for Host $fullhn ##\n"
    ssl_admin=$"$ssl_admin_pre$domain"
	sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/cfcred/cf-api-token.ini -d $fullhn -m $ssl_admin --agree-tos -n
    if [ -f /etc/letsencrypt/live/$fullhn/fullchain.pem ]
    then
        printf "Copying certs for $fullhn"
        mkdir -p $certdir
        bash -c "cat /etc/letsencrypt/live/$fullhn/fullchain.pem /etc/letsencrypt/live/$fullhn/privkey.pem >$certdir/$fullhn.cert"
        bash -c "cat /etc/letsencrypt/live/$fullhn/fullchain.pem >$certdir/$fullhn-fullchain.cert"
        bash -c "cat /etc/letsencrypt/live/$fullhn/privkey.pem >$certdir/$fullhn-privkey.key"
        chown -R $username:$username $certdir
    fi
fi