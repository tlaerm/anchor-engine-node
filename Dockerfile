# Anchor Engine - JOSS Demo Docker Image
# Production-ready container with WASM-based PGlite backend
# Supports: amd64 (x86_64), arm64 (Apple Silicon, Graviton)

FROM node:20-bookworm

# Install pnpm and runtime dependencies (no C++ build tools needed)
RUN npm install -g pnpm && \
    apt-get update && \
    apt-get install -y \
    libstdc++6 curl \
    git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Set environment variables
ENV PROJECT_ROOT=/app
ENV CONTEXT_DIR=/app/engine/context_data
ENV NODE_ENV=production

# Copy project files
COPY . .

# Install dependencies and build TypeScript (WASM modules are pre-built)
RUN pnpm install --no-frozen-lockfile && \
    pnpm run build

# Create data directories (will be mounted as volumes)
RUN mkdir -p \
    /app/inbox \
    /app/external-inbox \
    /app/mirrored_brain \
    /app/backups \
    /app/engine/context_data \
    /app/notebook && \
    chown -R node:node /app

# Copy sample data and docker-specific settings
RUN cp -r /app/sample-data/* /app/inbox/ 2>/dev/null || true && \
    cp /app/user_settings.docker.json /app/user_settings.json 2>/dev/null || true

# Expose API port (serves both API and UI)
EXPOSE 3160

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3160/health || exit 1

# Start the engine
CMD ["node", "--expose-gc", "engine/dist/index.js"]
