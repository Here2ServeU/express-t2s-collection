# Use official Node.js image
FROM node:18-alpine

# Set app directory
WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy app source code and public folder
COPY . .

# Expose port
EXPOSE 3000

# Start app
CMD ["node", "index.js"]
