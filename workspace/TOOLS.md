# Local Setup

## LM Studio
- Host: localhost:1234 / host.docker.internal:1234 (Docker)
- Models: Gemma 4 E2B (primary), Ministral 3B (fallback), Qwen 3.5 4B, Nemotron 3 Nano 4B
- Context: 32K tokens

## Gateway
- URL: https://openclaw-gateway.openclaw.orb.local
- Backend: openclaw-backend container (no direct host port)
- Embeddings: local provider (embeddinggemma-300m)
- Telegram: @injha_bot (pairing mode)
