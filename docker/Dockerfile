FROM debian:11

# set debian frontend to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update -yq \
    && apt-get install curl gnupg zip nginx certbot python3-certbot-nginx -yq \
    && apt-get install -yq build-essential \
    && apt-get clean -y

# Install Node.js v16.14.2 via nvm
RUN curl -O https://nodejs.org/dist/v16.14.2/node-v16.14.2-linux-x64.tar.xz \
    && tar -xf node-v16.14.2-linux-x64.tar.xz \
    && mv node-v16.14.2-linux-x64 /usr/local/lib/nodejs \
    && echo 'export PATH="/usr/local/lib/nodejs/bin:$PATH"' >> /etc/profile.d/nodejs.sh \
    && /bin/bash -c "source /etc/profile.d/nodejs.sh" \
    && rm node-v16.14.2-linux-x64.tar.xz
ENV PATH=/usr/local/lib/nodejs/bin:$PATH


# Clean up cache files
RUN rm -rf \
  /root/.cache \
  /root/.npm \
  /root/.pip \
  /usr/local/share/doc \
  /usr/share/doc \
  /usr/share/man \
  /var/lib/apt/lists/* \
  /tmp/*


VOLUME [ "/data-volume" ]

WORKDIR /usr/app

# installl the nx cli
RUN npm install -g nx

# clean install of dependencies
COPY package*.json ./
RUN npm ci

# copy the rest of the files
COPY . .

# Build the apps
RUN npx nx run-many --target=build --projects=server,client --skip-nx-cache


# setup nginx
ADD nginx/single/nginx.conf /etc/nginx
ADD nginx/single/nginx-default-site.conf /etc/nginx/sites-enabled/default
COPY nginx/booting.html /usr/share/nginx/html/index.html
RUN mkdir -p /var/log/nginx && \
  touch /var/log/nginx/error.log && \
  touch /var/run/nginx.pid && \
  usermod -a -G tty www-data

RUN chmod +x ./deploy/letsencrypt/certificate-request.sh ./deploy/letsencrypt/certificate-renew.sh

RUN chmod +x start-prod.sh

EXPOSE 443
EXPOSE 80

CMD ["./start-prod.sh"]
