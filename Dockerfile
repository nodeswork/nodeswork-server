FROM node:8.3.0

# Create app directory
WORKDIR /usr/src/app

ENV NODE_ENV production

# Install app dependencies
COPY package.json .
COPY package-lock.json .

RUN npm install

# Bundle app source
COPY . .

EXPOSE 3000
CMD [ "npm", "run", "startProd" ]
