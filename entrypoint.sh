#!/bin/sh

set -e

# declare the environment variables from the .env file
if [ -f "./.env" ]
then
  declare $(grep -v '^#' ./.env | xargs) 
fi



# show the booting page until the server is ready
booting_page="templates/booting.html"
cp "$booting_page" /var/www/html/index.nginx-debian.html
nginx


NGINX_CONF_FILE=/etc/nginx/nginx.conf

SERVER_PORT=${SERVER_PORT:-3000}
CLIENT_PORT=${CLIENT_PORT:-4200}


# add the nginx configuration to the nginx configuration file
echo "
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

" > "$NGINX_CONF_FILE"

# remove the default nginx index.html
rm -rf /usr/share/nginx/html/*

# save the current working directory as the root directory
ROOT_DIR=$(pwd)
SERVER_DIR="$ROOT_DIR/dist/apps/server"
CLIENT_DIR="$ROOT_DIR/dist/apps/docit"

wait_for_it_dir="$ROOT_DIR/scripts/wait-for-it.sh"

# make the wait-for-it.sh script executable
chmod +x "$wait_for_it_dir"


# Wait for a certain duration before proceeding
sleep 7


# Start backend server
cd $SERVER_DIR && node --enable-source-maps main.js &

# wait for the server to start then start the client
wait_for_it_dir localhost:$SERVER_PORT -t 0 -- cd $CLIENT_DIR \
 && npm set-script start "next start -p $CLIENT_PORT" \ 
 && npm run start &


# wait for the client to start then start the nginx server (at this point both the client and server are running)
wait_for_it_dir localhost:$CLIENT_PORT -t 0 -- nginx -g "daemon off;"
