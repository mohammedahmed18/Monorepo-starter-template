#!/bin/sh

# Start Nginx server
nginx -g "daemon off;" &

# Start backend server
node --enable-source-maps dist/apps/server/main.js
