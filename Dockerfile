# syntax = docker/dockerfile:1

# Find eligible builder and runner images at https://hub.docker.com/r/hexpm/elixir
ARG ELIXIR_VERSION=1.18.3
ARG OTP_VERSION=27.3.3
ARG DEBIAN_VERSION=bookworm-20250407-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build ENV
ENV MIX_ENV="prod"

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# Compile the app first (generates colocated LiveView hooks needed by esbuild)
RUN mix compile

# Compile assets
RUN mix assets.deploy

# Copy runtime config
COPY config/runtime.exs config/

# Build release
COPY rel rel
RUN mix release

# Start a new build stage for the final image
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates curl sqlite3 \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install litestream for SQLite replication
ARG LITESTREAM_VERSION=0.3.13
RUN curl -L https://github.com/benbjohnson/litestream/releases/download/v${LITESTREAM_VERSION}/litestream-v${LITESTREAM_VERSION}-linux-amd64.deb -o /tmp/litestream.deb \
    && dpkg -i /tmp/litestream.deb \
    && rm /tmp/litestream.deb

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG="en_US.UTF-8"
ENV LANGUAGE="en_US:en"
ENV LC_ALL="en_US.UTF-8"

WORKDIR /app

# Set runner ENV
ENV MIX_ENV="prod"

# Create data directory for SQLite
RUN mkdir -p /data

# Only copy the final release from the build stage
COPY --from=builder /app/_build/${MIX_ENV}/rel/fantasy ./

# Copy litestream config and entrypoint
COPY litestream.yml /etc/litestream.yml
COPY scripts/entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Run as non-root user for security
RUN useradd --create-home app
RUN chown -R app:app /app /data
USER app

EXPOSE 4001

ENTRYPOINT ["/app/entrypoint.sh"]
