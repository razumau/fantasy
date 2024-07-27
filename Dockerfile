# syntax = docker/dockerfile:1

# Adjust NODE_VERSION as desired
ARG NODE_VERSION=19.8.1
FROM node:${NODE_VERSION}-slim AS base

LABEL fly_launch_runtime="Next.js/Prisma"

# Next.js/Prisma app lives here
WORKDIR /app

# Set production environment
ENV NEXT_TELEMETRY_DISABLED="1" \
    NODE_ENV="production" \
    DATABASE_URL="file:/data/sqlite.db"

# Install pnpm
ARG PNPM_VERSION=9.6.0
RUN npm install -g pnpm@$PNPM_VERSION


# Throw-away build stage to reduce size of final image
FROM base AS build

# Install packages needed to build node modules
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential node-gyp openssl pkg-config python-is-python3

# Install node modules
COPY --link package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod=false

# Generate Prisma Client
COPY --link prisma .
RUN npx prisma generate

# Copy application code
COPY --link . .

# Build application
RUN pnpm run build

# Remove development dependencies
RUN pnpm prune --prod


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
