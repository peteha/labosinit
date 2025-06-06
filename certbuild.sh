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
    while read -r line; do
        # Skip empty lines
        if [[ -z "$line" ]]; then
            continue
        fi

        log "Processing line from certlist: $line"

        # Split the line into an array of domains
        IFS=' ' read -r -a domains <<< "$line"

        # Construct the certbot -d arguments dynamically
        certbot_args=""
        for domain in "${domains[@]}"; do
            certbot_args+=" -d $domain"
        done

        # Remove leading whitespace from certbot_args (in case there's any)
        certbot_args=$(echo "$certbot_args" | sed 's/^[ \t]*//')

        log "Running certbot with the following domains: ${domains[*]}"

        # Construct the certbot command
        certbot_command="sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials /home/peteha/cfcred/cf-api-token.ini --dns-cloudflare-propagation-seconds 20 $certbot_args -m $CERT_ADMIN --agree-tos -n"

        # Output the command to the screen
        log "About to run the following certbot command:"
        echo "$certbot_command" | tee -a "$LOG_FILE"

        # Run the certbot command and capture its output
        log "Running certbot..."
        certbot_output=$($certbot_command 2>&1 | tee -a "$LOG_FILE")

        # Output the result to the screen
        echo "$certbot_output"

        # Check if certificate is not up for renewal
        if echo "$certbot_output" | grep -q "Certificate not yet due for renewal"; then
            log "Certificate is not due for renewal. Skipping certificate copying for this domain."
            continue
        fi

        # Extract the directory path where certbot saved the certificates
        full_path=$(echo "$certbot_output" | grep -oP '(?<=Certificate is saved at: ).*fullchain\.pem' | head -n 1)
        cert_dir_path=$(dirname "$full_path")

        if [[ -z "$cert_dir_path" ]]; then
            log "Failed to determine the certificate directory from certbot output. Skipping $line."
            continue
        fi

        log "Certificate directory determined: $cert_dir_path"

        # Only run the cat commands if the certificate is renewed
        main_domain=${domains[0]#*.}
        log "Copying certificates to $CERT_DIR for domain: $main_domain"
        mkdir -p "$CERT_DIR"
        bash -c "cat $cert_dir_path/fullchain.pem $cert_dir_path/privkey.pem >$CERT_DIR/$main_domain.cert"
        bash -c "cat $cert_dir_path/fullchain.pem >$CERT_DIR/$main_domain-fullchain.cert"
        bash -c "cat $cert_dir_path/privkey.pem >$CERT_DIR/$main_domain-privkey.key"
        log "Setting ownership and permissions for certificates in $CERT_DIR"
        chown -R "$CURRENT_USER":"$CURRENT_USER" "$CERT_DIR"
        chmod -R 755 "$CERT_DIR"

        log "Certificates copied and permissions updated for $main_domain"
    done < "$certs"
else
    log "No certlist file found in $CERT_DIR; exiting script."
    exit 1
fi

log "=== Certificate Script Completed ==="