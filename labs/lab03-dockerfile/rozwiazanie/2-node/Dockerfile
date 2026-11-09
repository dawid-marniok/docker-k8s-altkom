FROM node:22-alpine
WORKDIR /app
# zależności przed kodem = cache warstwy npm install
COPY package*.json ./
RUN npm install --omit=dev
COPY . .
EXPOSE 3000
USER node
CMD ["node", "server.js"]
