# Multi-stage Dockerfile for NutriScan Backend
FROM node:22-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY tsconfig.json ./
COPY src/ ./src/
RUN npm run build

# Production Runner
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/dist ./dist
COPY migrations/ ./migrations/

# Create uploads directory for local fallback
RUN mkdir -p /app/uploads && chown -R node:node /app

USER node

EXPOSE 10000 4000
CMD ["node", "dist/server.js"]
