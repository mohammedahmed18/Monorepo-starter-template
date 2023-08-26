#!/bin/bash
CUSTOM_DOMAIN="$1"

if [[ -f "/etc/letsencrypt/live/$CUSTOM_DOMAIN/fullchain.pem" ]]; then
    echo "Certificate already exists for $CUSTOM_DOMAIN - exiting"
else

    # Request from Lets Encrypt
    certbot certonly --webroot --webroot-path="/var/www/html" \
        --register-unsafely-without-email \
        --domains $CUSTOM_DOMAIN \
        --rsa-key-size 4096 \
        --agree-tos \
        --force-renewal

    if (($? != 0)); then
        echo "ERROR: certbot request failed for $CUSTOM_DOMAIN use http on port 80 - exiting"
        exit 1
    else
        cp /usr/app/deploy/letsencrypt/options-ssl-nginx.conf /etc/letsencrypt/options-ssl-nginx.conf
        cp /usr/app/deploy/letsencrypt/ssl-dhparams.pem /etc/letsencrypt/ssl-dhparams.pem
        cp /usr/app/deploy/letsencrypt/nginx-ssl.conf /etc/nginx/sites-available/nginx-ssl.conf
        sed -i "s/CUSTOM_DOMAIN/$CUSTOM_DOMAIN/g" /etc/nginx/sites-available/nginx-ssl.conf
        ln -s /etc/nginx/sites-available/nginx-ssl.conf /etc/nginx/sites-enabled/nginx-ssl.conf
    fi

fi
