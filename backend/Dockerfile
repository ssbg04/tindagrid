# Unified Single-Container Dockerfile for TindaGrid ($0 Free Tier MVP on Render/Railway/Fly.io)
# Multi-stage build optimized for minimal RAM footprint (<150 MB)

# --- Stage 1: Build ---
FROM node:22-alpine AS builder

WORKDIR /usr/src/app

# Install build dependencies
RUN apk add --no-cache openssl

COPY package*.json ./
COPY tsconfig*.json ./
COPY nest-cli.json ./
COPY prisma ./prisma/

# Install dependencies and generate Prisma Client
RUN npm ci
RUN npx prisma generate

COPY libs ./libs/
COPY apps ./apps/

# Build shared libraries and the unified api-gateway bundle
RUN npm run build:libs
RUN npm run build

# --- Stage 2: Production Runner ---
FROM node:22-alpine AS runner

WORKDIR /usr/src/app

ENV NODE_ENV=production
ENV PORT=10000
# Memory optimization constraint for 150MB target
ENV NODE_OPTIONS="--max-old-space-size=140"

RUN apk add --no-cache openssl

COPY package*.json ./
COPY prisma ./prisma/

# Install only production dependencies
RUN npm ci --omit=dev && npm cache clean --force
RUN npx prisma generate

# Copy compiled artifacts from builder
COPY --from=builder /usr/src/app/dist ./dist

EXPOSE 10000

# Run healthcheck against /health endpoint
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:10000/health || exit 1

CMD ["node", "dist/apps/api-gateway/main.js"]
