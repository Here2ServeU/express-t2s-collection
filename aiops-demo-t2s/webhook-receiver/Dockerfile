FROM node:20-alpine
WORKDIR /usr/src/app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev
COPY . .
EXPOSE 5001
CMD ["npm","start"]
