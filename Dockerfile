# Fumadocs Documentation Site — Dockerfile
# Node 24 Alpine base, multi-stage build

FROM node:24-alpine AS builder
WORKDIR /app
COPY . .
RUN mkdir -p public
RUN npm install && npm run build

FROM node:24-alpine AS runner
WORKDIR /app
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000 HOSTNAME=0.0.0.0
CMD ["node", "server.js"]
