# Use official Node.js image
FROM node:18-alpine

# Set working directory
WORKDIR /usr/src/app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy ALL files, including public folder
COPY . .

# Expose app port
EXPOSE 3000

# Start app
CMD ["node", "index.js"]
