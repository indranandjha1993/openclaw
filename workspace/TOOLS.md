# TOOLS.md - Local Notes

## Infrastructure

### LM Studio
- **Host:** localhost:1234 (from host) / host.docker.internal:1234 (from Docker)
- **Models loaded:**
  - `google/gemma-4-e2b` — Primary model, 32K context
  - `mistralai/ministral-3-3b-reasoning` — Fallback/reasoning
  - `qwen/qwen3.5-4b` — Alternative
  - `nvidia/nemotron-3-nano-4b` — Lightweight tasks
  - `text-embedding-nomic-embed-text-v1.5` — Embeddings (available but using local provider)
- **Auth:** API key required (set in .env as LM_STUDIO_API_KEY)

### OpenClaw Gateway
- **Access:** https://openclaw-gateway.openclaw.orb.local (HTTPS only)
- **Backend:** Docker container `openclaw-backend`, no direct host port exposure
- **Proxy:** nginx TLS termination via `openclaw-gateway` container
- **Embeddings:** Local provider (embeddinggemma-300m, runs in-container)

### Telegram
- **Bot:** @injha_bot
- **DM Policy:** Pairing mode (new users must be approved)
- **Group Policy:** Allowlist

## Preferences

### TTS
- _(not configured yet)_

### Default Behavior
- Web search: disabled
- Web fetch: enabled (max 10K chars)
- Tool profile: messaging (agent), minimal (global)
