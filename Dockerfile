# Dockerfile
FROM elixir:1.17-slim AS builder

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

ARG ERL_FLAGS="+JMsingle true"
ENV ERL_FLAGS=${ERL_FLAGS}

RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential git curl ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the working directory in the container
WORKDIR /app

# Install Hex and Rebar3
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy Mix files
COPY mix.exs mix.lock ./

# Fetch and compile dependencies (only for production)
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy assets directory
COPY assets assets

# Copy configuration files
COPY config config

# Copy priv directory (for static assets, migrations, etc.)
COPY priv priv

# Copy application code
COPY lib lib

# Compile the application (including assets)
# Assets are built using assets.deploy alias which runs esbuild and tailwind
RUN mix compile

# Build assets for production. This generates digested files and cache_manifest.json
RUN mix assets.deploy

# Build the release
# The release name should match your OTP app name (:draft_guru)
RUN mix release

# Development image
FROM builder AS dev

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    inotify-tools \
    chromium-driver \
    && rm -rf /var/lib/apt/lists/*

# Set MIX_ENV to dev
ENV MIX_ENV=dev

# Install all dependencies, including dev and test
RUN mix deps.get --force

# Copy the rest of the application code
COPY . .

# The port Phoenix listens on
EXPOSE 4000

# The command to start the Phoenix server in development
CMD ["mix", "phx.server"]

# Stage 2: Create the final runtime image
# ----------------------------------------
# Use a minimal Debian image as the base
FROM debian:bookworm-slim AS app

# Set environment variables
ENV MIX_ENV=prod \
    LANG=C.UTF-8

# Install runtime dependencies (libsctp1 for distribution, libssl for crypto/https)
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    libsctp1 openssl libssl-dev \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Create a non-root user and group for security
RUN adduser --system --group appuser

# Set the working directory
WORKDIR /app

# Copy the compiled release from the builder stage
# Ensure ownership is set to the non-root user
COPY --from=builder --chown=appuser:appuser /app/_build/prod/rel/draft_guru ./

# Set the default user for running the application
USER appuser

# Expose the port the application will run on (default 4000, check runtime.exs)
# The PORT env var can override this at runtime.
EXPOSE 4000

# Define the entry point and command to start the application.
# Using "start" runs the application in the foreground.
# Consider adding migration step here using DraftGuru.Release.migrate (see release.ex)
# CMD ["bin/draft_guru", "start"]
# OR, if you want to run migrations automatically on start:
CMD ["/app/bin/draft_guru", "start"]