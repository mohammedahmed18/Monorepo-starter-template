FROM debian:11

# set debian frontend to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update -yq \
    && apt-get install curl gnupg zip nginx -yq \
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

WORKDIR /user/app

# installl the nx cli
RUN npm install -g nx

# clean install of dependencies
COPY package*.json ./
RUN npm ci

# copy the rest of the files
COPY . .

# Build the apps
RUN npx nx run-many --target=build --projects=server,docit --skip-nx-cache

# Set up entrypoint script
COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]


EXPOSE 80
