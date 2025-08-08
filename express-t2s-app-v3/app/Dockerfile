# Use official Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json first for caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy all files to container
COPY . .

# Expose the app port
EXPOSE 3000

# Start the Node.js server
CMD ["node", "index.js"]
