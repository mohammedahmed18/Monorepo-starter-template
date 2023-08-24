#!/bin/sh

# remove the default nginx index.html
rm -rf /usr/share/nginx/html/*

# Start Nginx server
nginx -g "daemon off;" &


# cd into the dist folder where the compiled react code is
cd dist/apps/docit
npm set-script start "next start -p 4200"

# start the client server in the background
npm run start &

# cd into the server
cd ../server

# Start backend server
node --enable-source-maps main.js
