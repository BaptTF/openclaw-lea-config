# OpenClaw Léa — Docker Image 🌙

Custom Docker image for **Léa**, an OpenClaw AI assistant running 24/7 on a Kubernetes cluster.

## Architecture

```
BaptTF/vps-infra                    ← K8s cluster (deployment, PVC, secrets)
  └── workloads/openclaw/
BaptTF/openclaw-lea-config          ← This repo (Docker image)
rjullien/openclaw-leo               ← Léa's config (workspace, memory, openclaw.json)
```

**This repo** = the Docker image only (system dependencies, tools, entrypoint).  
All runtime config, memory, and workspace files live in `/home` (persistent volume).

## What's in the image

| Component | Purpose |
|-----------|---------|
| [OpenClaw](https://github.com/openclaw/openclaw) | AI assistant gateway |
| [Playwright](https://playwright.dev/) + Chromium | Headless browser (web scraping, automation) |
| [Himalaya](https://github.com/pimalaya/himalaya) | CLI email client (IMAP/SMTP with OAuth2) |
| [GitHub CLI](https://cli.github.com/) (gh) | GitHub operations (PRs, issues, API) |
| [mcporter](https://github.com/nicholasgasior/mcporter) | MCP server manager |
| [uv](https://github.com/astral-sh/uv) | Python package manager |
| [poppler-utils](https://poppler.freedesktop.org/) | PDF text extraction (pdftotext) |
| [tini](https://github.com/krallin/tini) | Init process (PID 1, signal handling) |
| OpenSSH server | Remote SSH access |

### Pre-installed MCP servers (npm)

- `@modelcontextprotocol/server-brave-search`
- `server-perplexity-ask`
- `@modelcontextprotocol/server-sequential-thinking`
- `@zengwenliang/mcp-server-sequential-thinking`
- `@modelcontextprotocol/server-filesystem`
- `@modelcontextprotocol/server-memory`
- `@upstash/context7-mcp`
- `open-meteo-mcp-server`

### Pre-installed MCP servers (Python via uv)

- `osm-mcp-server` — OpenStreetMap
- `mcp-server-time` — Time/timezone
- `mcp-server-fetch` — URL fetching

## Runtime-installed tools (persistent in /home)

These tools are installed by Léa at first boot and persist across rebuilds via the `/home` volume:

| Tool | Install command | Purpose |
|------|----------------|---------|
| [ACE framework](https://github.com/kayba-ai/ace) | `uv tool install ace-framework` | Agent learning from session traces |
| [Mnemon](https://github.com/nicholasgasior/mnemon) | Binary in `~/bin/` | Cross-session semantic memory (SQLite) |
| [mcp-gsuite](https://github.com/nicholasgasior/mcp-gsuite) | Via mcporter config | Google Calendar + Gmail access |

## Data persistence

`/home` is mounted as a PersistentVolumeClaim. Everything under `/home/node/` survives container rebuilds:

```
/home/node/
├── .openclaw/lea/          ← OpenClaw config + workspace (openclaw-leo repo)
│   ├── openclaw.json       ← Main config file
│   └── workspace/          ← Memory, skills, scripts
├── .cache/ms-playwright/   ← Chromium binary (+ proxy wrapper)
├── .local/share/uv/        ← Python tools (ACE, MCP servers)
├── .ssh/                   ← Deploy keys
├── .config/                ← gh CLI, mcporter config
└── bin/                    ← Custom scripts (gtasks, fix-chrome-proxy.sh)
```

## Ports

| Port | Service |
|------|---------|
| 18789 | OpenClaw gateway (HTTP + WebSocket) |
| 18790 | OpenClaw browser CDP proxy |
| 22 | SSH server |

## Health check

```bash
curl http://localhost:18789/health
# → 200 OK
```

K8s liveness/readiness probes should target `GET /health` on port `18789`.

## Building

```bash
docker build -t openclaw-lea .
```

The image is automatically built by GitHub Actions on push to `master` and published to `ghcr.io/bapttf/openclaw-lea-config`.

## Environment variables

Configured via K8s secrets (`openclaw-secret`) and deployment env:

| Variable | Purpose |
|----------|---------|
| `OPENCLAW_CONFIG_PATH` | Path to openclaw.json (`/home/node/.openclaw/lea/openclaw.json`) |
| `OPENCLAW_SSH_ENABLED` | Enable SSH server (`true`) |
| `OPENCLAW_SSH_PORT` | SSH port (`22`) |
| `NODE_OPTIONS` | Node.js memory settings (`--max-old-space-size=1280`) |

API keys and channel tokens are in the K8s secret, not in the image.
