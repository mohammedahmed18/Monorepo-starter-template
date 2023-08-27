#!/bin/bash

CUSTOM_DOMAIN="$1"

# start nginx to verify domain ownership
nginx

live_path="/etc/letsencrypt/live/$CUSTOM_DOMAIN"

if [[ -e "$live_path" ]]; then
    echo "Existing certificate for domain $CUSTOM_DOMAIN"
    echo "Stop Nginx"
    nginx -s stop
    return
fi

echo "Creating certificate for '$CUSTOM_DOMAIN'"

echo "Requesting Let's Encrypt certificate for '$CUSTOM_DOMAIN'..."
echo "Generating OpenSSL key for '$CUSTOM_DOMAIN'..."

mkdir -p "$live_path" && openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout "$live_path/privkey.pem" \
    -out "$live_path/fullchain.pem" \
    -subj "/CN=localhost"

echo "Removing key now that validation is done for $CUSTOM_DOMAIN..."
rm -Rfv /etc/letsencrypt/live/$CUSTOM_DOMAIN /etc/letsencrypt/archive/$CUSTOM_DOMAIN /etc/letsencrypt/renewal/$CUSTOM_DOMAIN.conf

# Request from Lets Encrypt
certbot certonly --webroot --webroot-path="/var/www/html" \
    --register-unsafely-without-email \
    --domains $CUSTOM_DOMAIN \
    --rsa-key-size 4096 \
    --agree-tos \
    --test-cert \
    --force-renewal

if (($? != 0)); then
    echo "ERROR: certbot request failed for $CUSTOM_DOMAIN use http on port 80"
    exit 1
else
    cp /usr/app/deploy/letsencrypt/options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf
    cp /usr/app/deploy/letsencrypt/ssl-dhparams.pem /etc/letsencrypt/ssl-dhparams.pem
    cp /usr/app/deploy/letsencrypt/nginx-ssl.conf /etc/nginx/sites-available/nginx-ssl.conf
    sed -i "s/CUSTOM_DOMAIN/$CUSTOM_DOMAIN/g" /etc/nginx/sites-available/nginx-ssl.conf
    ln -s /etc/nginx/sites-available/nginx-ssl.conf /etc/nginx/sites-enabled/nginx-ssl.conf
    # everything is fine, stop nginx
    nginx -s stop
fi
