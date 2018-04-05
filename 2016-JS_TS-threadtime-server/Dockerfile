FROM node:7

# Create app directory
RUN mkdir -p /app
WORKDIR /app

# Copy package.json

COPY .npmrc /app
COPY .npm-cacert.pem /app
COPY package.json /app
COPY yarn.lock /app
RUN npm set strict-ssl false
RUN npm install

COPY tsconfig.json /app

RUN mkdir -p /app/src /app/test
COPY src /app/src
COPY test /app/test
COPY utils /app/utils

RUN npm run build

# Bundle in compiled app source
RUN mkdir -p /app/dist

# Remove cert, npmrc, src and tests
RUN rm -r .npmrc .npm-cacert.pem tsconfig.json src/ test/ utils/

EXPOSE 3000
CMD ["npm", "start"]
