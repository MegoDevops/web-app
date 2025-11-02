FROM node:14-alpine as build-stage

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source code
COPY . .

# Build the app (if needed - adjust based on your web framework)
RUN npm run build || echo "No build script, serving directly"

FROM node:14-alpine as production-stage

WORKDIR /app

# Copy built app or source files
COPY --from=build-stage /app .

# Create non-root user
RUN adduser -D appuser && chown -R appuser:appuser /app
USER appuser

EXPOSE 8080

# Adjust this based on your web framework
CMD ["npm", "start"] || ["node", "server.js"]