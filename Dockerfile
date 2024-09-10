# Stage 1: Build
FROM node:20-buster-slim as builder
WORKDIR /app

# Copy package files (npm only)
COPY package.json .
COPY package-lock.json .

# Install dependencies using npm
RUN npm ci

# Install specific npm version globally
RUN npm install -g npm@10.8.3

# Copy the rest of the application code
COPY . .

# Disable Next.js telemetry
ENV NEXT_TELEMETRY_DISABLED 1

# Build the application
RUN npm run build

# Remove development dependencies
RUN npm prune --production

# Stage 2: Production
FROM node:20-buster-slim
WORKDIR /app

# Set environment variables
ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

# Create and use a non-root user
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs && \
    mkdir -p /app && chown -R nextjs:nodejs /app

# Switch to non-root user
USER nextjs

# Copy necessary files from the builder stage
COPY --chown=nextjs:nodejs --from=builder /app/package.json ./package.json
COPY --chown=nextjs:nodejs --from=builder /app/node_modules ./node_modules
COPY --chown=nextjs:nodejs --from=builder /app/.next ./.next
COPY --chown=nextjs:nodejs --from=builder /app/public ./public

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
