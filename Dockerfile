# Pull base image.
FROM ubuntu:18.04

# Install Node.js
RUN apt-get update
RUN apt-get install --yes nodejs
RUN apt-get install --yes npm
RUN apt-get install --yes build-essential

#Install python and twitter module
RUN apt-get update
RUN apt-get install --yes python
RUN apt-get install -y python-pip
RUN pip install twitter

# Create app directory
WORKDIR /usr/src/app

# Install app dependencies
# A wildcard is used to ensure both package.json AND package-lock.json are copied
# where available (npm@5+)
COPY package*.json ./


RUN npm install
# If you are building your code for production
# RUN npm install --only=production

# Bundle app source
COPY . .

EXPOSE 4000
CMD [ "node", "index.js" ]
