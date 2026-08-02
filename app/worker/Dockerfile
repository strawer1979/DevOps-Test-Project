# Stage 1: Install dependencies
FROM node:20-alpine AS deps

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Stage 2: Build application
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY src/ ./src/
COPY __tests__/ ./__tests__/

# Run tests
RUN npm test

# Stage 3: Production runtime
FROM node:20-alpine AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 shopsimple

# Copy production dependencies
COPY --from=deps /app/node_modules ./node_modules

# Copy source code
COPY src/ ./src/

# Create required directories
RUN mkdir -p /app/logs && chown -R shopsimple:nodejs /app/logs

# Switch to non-root user
USER shopsimple

# Expose health check port
EXPOSE 4001

# Environment variables
ENV NODE_ENV=production \
    PORT=4001 \
    LOG_LEVEL=info

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node -e "require('http').get('http://localhost:4001/health/liveness', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"

# Start the worker
CMD ["node", "src/index.js"]
