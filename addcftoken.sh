#!/bin/bash
source hostbuild.env
if [ ! -f /home/$username/cfcred/cf-api-token.ini ]
then
    echo -n "Enter CloudFlare API Token: "
    read cfapitoken
    mkdir -p /home/$username/cfcred
	echo dns_cloudflare_api_token = "$cfapitoken" > /home/$username/cfcred/cf-api-token.ini
	chmod 600 /home/$username/cfcred/cf-api-token.ini
    echo "## Cloudflare Token Added to /home/$username/cfcred/cf-api-token.ini ##"
fi
if ! command -v certbot &> /dev/null; then
    echo "## No certbot installed ##"
    exit
fi