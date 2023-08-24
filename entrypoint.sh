#!/bin/sh

# copy the frontend build to the nginx folder
cp -r dist/apps/docit/* /usr/share/nginx/html

# Start Nginx server
nginx -g "daemon off;" &

# Start backend server
node --enable-source-maps dist/apps/server/main.js
