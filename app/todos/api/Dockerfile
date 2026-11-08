# ToDos API — obraz produkcyjny
FROM node:22-alpine

WORKDIR /app

# najpierw same zależności: ta warstwa trafia do cache, dopóki package*.json się nie zmieni
COPY package*.json ./
RUN npm ci --omit=dev

# potem kod — zmiana w server.js nie wymusza ponownego npm ci
COPY server.js ./

ENV PORT=3000
EXPOSE 3000

# nie uruchamiamy aplikacji jako root (użytkownik node jest w obrazie bazowym)
USER node

# forma exec: sygnały trafiają prosto do node
CMD ["node", "server.js"]
