# Build Himalaya with OAuth2 support (pre-built binaries don't include it)
FROM rust:1-bookworm AS himalaya-builder
RUN apt-get update && \
    apt-get install -y --no-install-recommends pkg-config libssl-dev && \
    cargo install himalaya --locked --features oauth2 && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

FROM node:24

# Install supervisor for process management and openssh-server for optional SSH access
RUN apt-get update && \
    apt-get install -y --no-install-recommends supervisor openssh-server && \    
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/sshd

# Install OpenClaw and mcporter globally from npm
# renovate: datasource=npm depName=openclaw
ARG OPENCLAW_VERSION=2026.2.26
RUN npm install -g openclaw@${OPENCLAW_VERSION} && npm install -g mcporter@latest

# Pre-install MCP server packages (used by mcporter)
RUN npm install -g \
    @modelcontextprotocol/server-brave-search \
    server-perplexity-ask \
    @modelcontextprotocol/server-sequential-thinking \
    @zengwenliang/mcp-server-sequential-thinking \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-memory \
    @upstash/context7-mcp \
    open-meteo-mcp-server

# Environment setup — set HOME before uv tool install so Python-based
# MCP servers install into /home/node/.local/bin (survives container rebuild
# when /home/node is a mounted volume)
ENV NODE_ENV=production
ENV HOME=/home/node
ENV TERM=xterm-256color

# Install uv (Python package manager) and Python-based MCP servers
ENV UV_INSTALL_DIR="/usr/local/bin"
RUN curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv tool install osm-mcp-server --python-preference managed && \
    uv tool install mcp-server-time --python-preference managed && \
    uv tool install mcp-server-fetch --python-preference managed

# Copy Himalaya binary with OAuth2 support from builder stage
COPY --from=himalaya-builder /usr/local/cargo/bin/himalaya /usr/local/bin/himalaya

# Add supervisord config and entrypoint script
COPY docker/supervisord.conf /etc/supervisor/conf.d/openclaw.conf
COPY docker/entrypoint.sh /entrypoint.sh
COPY docker/patch-config.js /patch-config.js
RUN chmod +x /entrypoint.sh

# Create data directory for OpenClaw config and generated certs
RUN mkdir -p /home/node/.openclaw && \
    chown -R node:node /home/node

# SSH configuration script
COPY docker/setup-ssh.sh /setup-ssh.sh
RUN chmod +x /setup-ssh.sh

EXPOSE 18789 18790 22

ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/conf.d/openclaw.conf"]
