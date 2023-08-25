#!/bin/bash

set -e

# Load environment variables from the .env file
if [ -f "./.env" ]; then
  export $(grep -v '^#' ./.env | xargs)
fi

# Set default values if environment variables are not defined
SERVER_PORT=${SERVER_PORT:-3000}
CLIENT_PORT=${CLIENT_PORT:-4200}

# Define paths
ROOT_DIR=$(pwd)
SERVER_DIR="$ROOT_DIR/dist/apps/server"
CLIENT_DIR="$ROOT_DIR/dist/apps/docit"
BOOTING_PAGE="templates/booting.html" # TODO: handle this
NGINX_CONF_FILE="/etc/nginx/nginx.conf"
WAIT_FOR_IT_SCRIPT="$ROOT_DIR/scripts/wait-for-it.sh"


# Make the wait-for-it.sh script executable
chmod +x "$WAIT_FOR_IT_SCRIPT"

# NGINX configuration
NGINX_CONFIG="
events { worker_connections 1024; }

http {
  include /etc/nginx/mime.types;
  client_max_body_size 4m;

  server {
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location /api/ {
      proxy_pass http://localhost:$SERVER_PORT/;
    }

    location / {
      proxy_pass http://localhost:$CLIENT_PORT/;
    }

    listen 80 default_server;
    listen [::]:80;
  }
}
"

# Apply NGINX configuration
echo "$NGINX_CONFIG" > "$NGINX_CONF_FILE"

# overwrite the default NGINX index.html file to show a booting page
cp "$BOOTING_PAGE" /usr/share/nginx/html/index.html

# Start backend server
cd "$SERVER_DIR" && node --enable-source-maps main.js &

# Wait for backend server to start
$WAIT_FOR_IT_SCRIPT localhost:$SERVER_PORT -t 0

# Start frontend client
cd "$CLIENT_DIR" && npm set-script start "next start -p $CLIENT_PORT" && npm run start &

# Wait for frontend client to start
$WAIT_FOR_IT_SCRIPT localhost:$CLIENT_PORT -t 0

# start NGINX (both frontend and backend are running at this point)
nginx -g "daemon off;"
