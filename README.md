# OpenClaw — Dockerized Setup

Self-hosted [OpenClaw](https://openclaw.ai/) AI assistant running in Docker, pre-configured for local LLM inference via [LM Studio](https://lmstudio.ai/).

## Prerequisites

- Docker & Docker Compose
- LM Studio running on the host with at least one model loaded

## Quick Start

```bash
# 1. Configure
cp .env.example .env
# Edit .env — set your gateway token and LM Studio API key

# 2. Update model IDs in config to match your LM Studio models
# Check available models:
curl -H "Authorization: Bearer $LM_STUDIO_API_KEY" http://localhost:1234/v1/models
# Then edit config/openclaw.json

# 3. Start
make up

# 4. Open dashboard
make dashboard
```

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
| `.env` | Secrets and port configuration |
| `config/openclaw.json` | Gateway, model providers, agent defaults, tools |
| `workspace/` | Files accessible to the OpenClaw agent |

### Adding/Changing LM Studio Models

Edit `config/openclaw.json` → `models.providers.lm-studio.models` array. Each model needs:

```json5
{ "id": "model/name-from-lmstudio", "name": "Display Name", "contextWindow": 32000, "maxTokens": 4096 }
```

Then run `make restart`.

## Architecture

```
Host Machine
├── LM Studio (:1234)        ← LLM inference
├── PostgreSQL (:5432)       ← available if needed by extensions
└── Redis (:6379)            ← available if needed by extensions

Docker
└── openclaw-gateway (:18789)
    ├── connects to LM Studio via host.docker.internal
    ├── config/ mounted for persistence
    └── workspace/ mounted for agent file access
```

## Security Notes

- Gateway token is required for all connections
- LM Studio API key is stored in `.env` (git-ignored) and injected via env var
- Gateway binds to `0.0.0.0` inside the container for Docker port forwarding — only exposed to localhost on the host
- Do not expose port 18789 to the public internet without additional auth
