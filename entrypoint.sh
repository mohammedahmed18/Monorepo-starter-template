#!/bin/bash

set -e

# Load environment variables from the .env file
if [ -f "./.env" ]; then
  export $(grep -v '^#' ./.env | xargs)
fi

SERVER_PORT=3000
CLIENT_PORT=4200

# Define paths
ROOT_DIR=$(pwd)
SERVER_DIR="$ROOT_DIR/dist/apps/server"
CLIENT_DIR="$ROOT_DIR/dist/apps/docit"
WAIT_FOR_IT_SCRIPT="$ROOT_DIR/scripts/wait-for-it.sh"


# Make the wait-for-it.sh script executable
chmod +x "$WAIT_FOR_IT_SCRIPT"


# Start backend server
cd "$SERVER_DIR" && node --enable-source-maps main.js &

# Wait for backend server to start
$WAIT_FOR_IT_SCRIPT localhost:$SERVER_PORT -t 0

# Start frontend client
cd "$CLIENT_DIR" && npm set-script start "next start -p $CLIENT_PORT" && npm run start &

# Wait for frontend client to start
$WAIT_FOR_IT_SCRIPT localhost:$CLIENT_PORT -t 0


# Start nginx (now that the backend and frontend servers are running) in the background
nginx -g "daemon off;" &

if [[ ! -z "${CUSTOM_DOMAIN}" ]]; then
    # Add monthly cron job to renew certbot certificate
    echo -n "* * 2 * * root exec "$ROOT_DIR"/deploy/letsencrypt/certificate-renew.sh ${CUSTOM_DOMAIN}" >> /etc/cron.d/certificate-renew
    chmod +x /etc/cron.d/certificate-renew
    # Request the certbot certificate
    "$ROOT_DIR"/deploy/letsencrypt/certificate-request.sh ${CUSTOM_DOMAIN}
    # restart nginx to use the new certificate
    nginx -s reload
fi

