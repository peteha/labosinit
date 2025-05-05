#!/bin/bash

LOG_DIR="/var/log/certbot"
LOG_FILE="$LOG_DIR/certbot.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
CURRENT_USER=$(whoami)

# Ensure the log directory exists
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    chmod 755 "$LOG_DIR"
fi

# Log function to output to both console and log file
log() {
    echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# Start logging
log "=== Starting Certificate Script ==="

# Load environment variables from the .env file
if [ -f ".env" ]; then
    log "Loading environment variables from .env"
    export $(grep -v '^#' .env | xargs)
else
    log "No .env file found; proceeding without it."
fi

# Set CERT_DIR; use fallback if unset
if [ -z "$CERT_DIR" ]; then
    CERT_DIR="/opt/certs"
    log "CERT_DIR not set in .env; using default: $CERT_DIR"
else
    log "CERT_DIR loaded: $CERT_DIR"
fi

# Set CERT_ADMIN; prompt if unset
if [ -z "$CERT_ADMIN" ]; then
    echo -n "Cert Admin (email address): " | tee -a "$LOG_FILE"
    read certadmin
    CERT_ADMIN=$certadmin
    log "CERT_ADMIN provided: $CERT_ADMIN"
else
    log "CERT_ADMIN loaded: $CERT_ADMIN"
fi

# Ensure CERT_DIR exists and has correct permissions
if [ ! -d "$CERT_DIR" ]; then
    log "CERT_DIR does not exist; creating directory at $CERT_DIR"
    mkdir -p "$CERT_DIR"
else
    log "CERT_DIR exists: $CERT_DIR"
fi

log "Setting read/write permissions for CERT_DIR"
chown -R "$CURRENT_USER":"$CURRENT_USER" "$CERT_DIR"
chmod -R 755 "$CERT_DIR"

if [ -f "$CERT_DIR/certlist" ]; then
    log "certlist file found at $CERT_DIR/certlist"

    # Check for Cloudflare credentials
    if [ ! -f /home/peteha/cfcred/cf-api-token.ini ]; then
        echo -n "Enter CloudFlare API Token: " | tee -a "$LOG_FILE"
        read -s cfapitoken
        mkdir -p /home/peteha/cfcred
        echo dns_cloudflare_api_token = "$cfapitoken" > /home/peteha/cfcred/cf-api-token.ini
        chmod 600 /home/peteha/cfcred/cf-api-token.ini
        log "Cloudflare API token saved to /home/peteha/cfcred/cf-api-token.ini"
    else
        log "Cloudflare API token already exists."
    fi

    # Save CERT_ADMIN in .env if not already saved
    if [ ! -f "$CERT_DIR/certadmin.env" ]; then
        echo "certadmin=$CERT_ADMIN" > "$CERT_DIR/certadmin.env"
        log "CERT_ADMIN saved to $CERT_DIR/certadmin.env"
    fi

    source "$CERT_DIR/certadmin.env"
    log "Loaded CERT_ADMIN: $CERT_ADMIN"

    certs="$CERT_DIR/certlist"
    certlines=$(cat $certs)
    for line in $certlines; do
        # Split the line into an array of domains
        log "Processing line: $line"
        IFS=' ' read -r -a domains <<< "$line"

        # Construct the certbot -d arguments dynamically
        certbot_args=""
        for domain in "${domains[@]}"; do
            certbot_args="$certbot_args -d $domain"
        done
        echo $certbot_args
        log "Creating certificate for: ${domains[*]}"
        ## sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /home/peteha/cfcred/cf-api-token.ini --dns-cloudflare-propagation-seconds 20 $certbot_args -m $CERT_ADMIN --agree-tos -n | tee -a "$LOG_FILE"

        # Use the first domain for output naming
        main_domain=${domains[0]#*.}

        log "Copying certificates to $CERT_DIR for domain: $main_domain"
        #mkdir -p "$CERT_DIR"
        #bash -c "cat /etc/letsencrypt/live/${domains[0]}/fullchain.pem /etc/letsencrypt/live/${domains[0]}/privkey.pem >$CERT_DIR/$main_domain.cert"
        #bash -c "cat /etc/letsencrypt/live/${domains[0]}/fullchain.pem >$CERT_DIR/$main_domain-fullchain.cert"
        #bash -c "cat /etc/letsencrypt/live/${domains[0]}/privkey.pem >$CERT_DIR/$main_domain-privkey.key"
        #log "Setting ownership and permissions for copied certificates"
        #chown -R "$CURRENT_USER":"$CURRENT_USER" "$CERT_DIR"
        #chmod -R 755 "$CERT_DIR"
        #log "Certificates copied for $main_domain"
    done
else
    log "No certlist file found in $CERT_DIR; exiting script."
    exit 1
fi

log "=== Certificate Script Completed ==="