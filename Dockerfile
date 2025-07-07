# ─────────────────────────────────────────────────────────────
#  Stage 1 – builder  ▸  compile BEAM code + JS assets + release
# ─────────────────────────────────────────────────────────────
FROM elixir:1.17-slim AS builder

ENV MIX_ENV=prod LANG=C.UTF-8 \
    # keep idle containers lightweight
    ERL_FLAGS="+JMsingle true"

# ❶ Build & asset toolchain
RUN apt-get update -y && apt-get install -y --no-install-recommends \
      build-essential git curl ca-certificates \
      # Node 20 (for esbuild / tailwind) — feel free to pin
      && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
      apt-get install -y nodejs \
   && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ❷ Elixir tooling
RUN mix local.hex --force && mix local.rebar --force

# ❸ Cache deps
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

# ❹ Copy source
COPY config      config
COPY lib         lib
COPY priv        priv
COPY assets      assets

# ❺ Compile + build static assets + release
RUN mix compile && \
    mix assets.deploy && \
    mix release

# ─────────────────────────────────────────────────────────────
#  Stage 2 – runtime  ▸  ultra-slim image that only runs the release
# ─────────────────────────────────────────────────────────────
FROM debian:bookworm-slim AS runtime

ENV LANG=C.UTF-8 MIX_ENV=prod

# ❻ Minimal libs Phoenix / SSL need
RUN apt-get update -y && apt-get install -y --no-install-recommends \
      libsctp1 openssl ca-certificates \
   && apt-get clean && rm -rf /var/lib/apt/lists/*

# ❼ Non-root user
RUN adduser --system --group appuser
USER appuser
WORKDIR /app

# ❽ Copy release built in stage 1
COPY --from=builder --chown=appuser:appuser /app/_build/prod/rel/draft_guru ./

EXPOSE 4000
CMD ["/app/bin/draft_guru", "start"]