#!/bin/sh

# declare the environment variables from the .env file
if [ -f "./.env" ]
then
  declare $(grep -v '^#' ./.env | xargs) 
fi



init_loading_pages(){
  local booting_page="templates/booting.html"
  cp "$booting_page" /var/www/html/index.nginx-debian.html
  # Start nginx page to display the Appsmith is Initializing page
  nginx
}

init_loading_pages

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


cd dist/apps/server

sleep 7

# Start backend server
node --enable-source-maps main.js &


./scripts/wait-for-it.sh localhost:$SERVER_PORT -t 0 -- cd ../docit \
 && npm set-script start "next start -p $CLIENT_PORT" \ 
 && npm run start &


# wait for the client to start then start nginx
./scripts/wait-for-it.sh localhost:$CLIENT_PORT -t 0 -- nginx -g "daemon off;"
