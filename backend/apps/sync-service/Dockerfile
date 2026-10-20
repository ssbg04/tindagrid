# Dedicated Dockerfile for horizontal scaling: sync-service
FROM node:22-alpine AS builder
WORKDIR /usr/src/app
RUN apk add --no-cache openssl
COPY package*.json tsconfig*.json nest-cli.json ./
COPY prisma ./prisma/
RUN npm ci && npx prisma generate
COPY libs ./libs/
COPY apps ./apps/
RUN npm run build:libs && npx nest build sync-service

FROM node:22-alpine AS runner
WORKDIR /usr/src/app
ENV NODE_ENV=production
ENV PORT=3001
RUN apk add --no-cache openssl
COPY package*.json ./
COPY prisma ./prisma/
RUN npm ci --omit=dev && npm cache clean --force && npx prisma generate
COPY --from=builder /usr/src/app/dist/apps/sync-service ./dist/apps/sync-service
COPY --from=builder /usr/src/app/dist/libs ./dist/libs
EXPOSE 3001
CMD ["node", "dist/apps/sync-service/main.js"]
