# OpenClaw — Dockerized Setup

Self-hosted [OpenClaw](https://openclaw.ai/) AI assistant running in Docker, pre-configured for local LLM inference via [LM Studio](https://lmstudio.ai/).

## Prerequisites

- **Docker & Docker Compose** — [Install Docker Desktop](https://docs.docker.com/get-docker/)
- **LM Studio** — running on the host with at least one model loaded ([download](https://lmstudio.ai/))
- **Make** — pre-installed on macOS/Linux, or install via `brew install make`

## Quick Start

### 1. Clone and configure

```bash
git clone git@github.com:indranandjha1993/openclaw.git
cd openclaw
cp .env.example .env
```

Edit `.env` with your values:

```bash
# Generate a secure gateway token
openssl rand -hex 32
# Paste it as OPENCLAW_GATEWAY_TOKEN in .env

# Add your LM Studio API key
# (find it in LM Studio → Settings → API)
```

### 2. Configure your LM Studio models

Check which models are loaded in LM Studio:

```bash
curl -H "Authorization: Bearer YOUR_LM_STUDIO_API_KEY" http://localhost:1234/v1/models
```

Edit `config/openclaw.json` and update the `models` array to match your loaded models. Each model entry needs:

```json5
{
  "id": "exact/model-id-from-lmstudio",
  "name": "Human-Readable Name",
  "contextWindow": 32000,
  "maxTokens": 4096
}
```

Also update `agents.defaults.model.primary` to your preferred default model.

### 3. Start the gateway

```bash
make up
```

Wait a few seconds for the health check to pass, then verify:

```bash
make health
```

### 4. Connect the dashboard

```bash
make dashboard
```

This prints a URL like `http://127.0.0.1:18789/#token=abc123...`. Open it in your browser.

### 5. Approve device pairing

On first connection (and after container recreates), the browser shows **"pairing required"**. This is expected — Docker's network bridge makes the browser appear as an external device.

To approve:

```bash
# List pending devices
make devices

# Approve all pending devices
make approve
```

Then click **Connect** in the browser. You're in!

## Management

Run `make` to see all available commands:

```
Lifecycle
  up              Start the OpenClaw gateway
  down            Stop all OpenClaw services
  restart         Restart the gateway (picks up .env + config changes)

Observability
  logs            Tail gateway logs (Ctrl+C to stop)
  status          Show running containers and health

Interaction
  cli             Open an interactive CLI session
  dashboard       Print the authenticated dashboard URL
  health          Check gateway health and reachability
  devices         List pending and paired devices
  approve         Approve all pending device pairing requests

Configuration
  config          Open openclaw.json in your editor
  token           Generate and save a new gateway token
  env             Show current .env values (secrets masked)

Maintenance
  update          Pull latest image and restart
  destroy         Remove containers, volumes, and images (keeps config/)
```

## Configuration

| File | Purpose |
|---|---|
| `.env` | Gateway token, LM Studio API key, ports, timezone |
| `.env.example` | Template with all required variables (safe to commit) |
| `config/openclaw.json` | Gateway bind mode, LLM providers, agent defaults, tools |
| `workspace/` | Files directly accessible to the OpenClaw agent |

### Environment Variables

| Variable | Required | Description |
|---|---|---|
| `OPENCLAW_GATEWAY_TOKEN` | Yes | Auth token for dashboard and API connections |
| `LM_STUDIO_API_KEY` | Yes | LM Studio API key for model access |
| `OPENCLAW_GATEWAY_PORT` | No | Gateway port (default: `18789`) |
| `OPENCLAW_BRIDGE_PORT` | No | Bridge port (default: `18790`) |
| `TZ` | No | Timezone (default: `Asia/Kolkata`) |

## Architecture

```
Host Machine
├── LM Studio (:1234)           ← local LLM inference
├── PostgreSQL (:5432)          ← available via host.docker.internal
└── Redis (:6379)               ← available via host.docker.internal

Docker
└── openclaw-gateway (:18789)
    ├── connects to LM Studio via host.docker.internal:1234
    ├── config/ bind-mounted for persistence
    └── workspace/ bind-mounted for agent file access
```

> **Note:** OpenClaw uses file-based storage (JSON) for sessions, memory, and tasks.
> PostgreSQL and Redis are accessible from the container but not used by OpenClaw core.

## Troubleshooting

### "pairing required" on dashboard

This happens because Docker's bridge network makes browser connections appear external.

```bash
make devices    # check pending devices
make approve    # approve them
```

Then click **Connect** in the browser.

### Gateway keeps restarting

Check logs for config errors:

```bash
make logs
```

Common causes:
- Invalid JSON in `config/openclaw.json` (comments are allowed — it's JSON5)
- Missing `name` field on model entries
- Missing `LM_STUDIO_API_KEY` in `.env`

### LM Studio models not working

Verify LM Studio is reachable from the container:

```bash
docker exec openclaw-gateway curl -s \
  -H "Authorization: Bearer $LM_STUDIO_API_KEY" \
  http://host.docker.internal:1234/v1/models
```

Ensure model IDs in `config/openclaw.json` exactly match LM Studio's model IDs.

### Config changes not taking effect

Use `make restart` (not just `docker compose restart`) — it recreates the container to pick up `.env` changes.

## Security Notes

- Gateway token is required for all connections
- LM Studio API key is stored in `.env` (git-ignored) and injected via env var
- Gateway binds to `0.0.0.0` inside the container for Docker port forwarding — only exposed to `localhost` on the host
- Do not expose port 18789 to the public internet without additional auth
- Device pairing adds a second layer of trust for non-loopback connections
