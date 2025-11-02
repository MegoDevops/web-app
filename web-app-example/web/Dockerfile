FROM node:14-alpine as build-stage

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source code including vue.config.js
COPY . .

# Build the Vue.js app for production
RUN npm run build

# Production stage
FROM node:14-alpine

WORKDIR /app

# Copy built Vue app
COPY --from=build-stage /app/dist ./dist

# Copy package.json for production dependencies
COPY package*.json ./

# Install only production dependencies for Express server
RUN npm install express cors axios

# Create production server file
COPY server.js ./

# Create non-root user
RUN addgroup -g 1000 appuser && \
    adduser -S -u 1000 -G appuser appuser && \
    chown -R appuser:appuser /app

USER appuser

EXPOSE 8080

CMD ["node", "server.js"]