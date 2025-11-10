# syntax = docker/dockerfile:1

FROM oven/bun:1.3.2 AS base

# Next.js/Prisma app lives here
WORKDIR /app

# Set production environment
ENV NEXT_TELEMETRY_DISABLED="1" \
    NODE_ENV="production" \
    DATABASE_URL="file:/data/sqlite.db"

# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential openssl pkg-config

# Install node modules
COPY --link package.json bun.lock ./
RUN bun install --frozen-lockfile

# Generate Prisma Client
COPY --link prisma .
RUN bunx prisma generate

# Copy application code
COPY --link . .

# Build application
RUN bun run build

# Remove development dependencies
RUN bun install --production --frozen-lockfile


# Final stage for app image
FROM base

# Install packages needed for deployment
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y openssl ca-certificates fuse3 sqlite3 curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ARG LITESTREAM_VERSION=0.3.13
RUN curl https://github.com/benbjohnson/litestream/releases/download/v0.3.13/litestream-v${LITESTREAM_VERSION}-linux-amd64.deb -O -L
RUN dpkg -i litestream-v${LITESTREAM_VERSION}-linux-amd64.deb

# Copy built application
COPY --from=build /app /app
COPY --from=build /app/litestream.yml /etc/litestream.yml

# Setup sqlite3 on a separate volume
RUN mkdir -p /data
VOLUME /data

RUN chmod +x scripts/entrypoint.sh
EXPOSE 3000
ENTRYPOINT ["scripts/entrypoint.sh"]
