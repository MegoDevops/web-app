FROM node:14-alpine as build-stage

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

FROM node:14-alpine

WORKDIR /app

COPY --from=build-stage /app/dist ./dist
COPY package*.json ./
RUN npm install express cors axios
COPY server.js ./

EXPOSE 8080

CMD ["node", "server.js"]