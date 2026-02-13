FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
# This line is critical to copy the 'public' folder
COPY . . 
EXPOSE 3000
CMD ["node", "index.js"]
