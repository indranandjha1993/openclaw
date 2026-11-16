# openclaw

My [OpenClaw](https://openclaw.ai/) setup: a personal AI assistant that runs in Docker,
talks to me over Telegram and a web dashboard. It runs on Gemini 3 Flash (free tier) and
falls back to a local [LM Studio](https://lmstudio.ai/) model, which also handles the
routine heartbeat and memory search embeddings.

## Layout

| Path | What it is | In git |
|---|---|---|
| `docker-compose.yml` | One `gateway` service on host networking, pinned image, state in a Docker volume | yes |
| `config/openclaw.json` | OpenClaw config. Mounted read-only; values come from `.env` as `${VAR}` | yes |
| `.env` | Secrets and anything machine-specific (image tag, port, model, URLs) | no |
| `workspace/` | The agent's persona and memory files | no |
| `workspace.example/` | Starting point for `workspace/` | yes |
| `backups/` | Output of `make backup` | no |

Runtime state (sessions, device pairing, Telegram state, installed plugins) lives in the
`openclaw_state` Docker volume, not in this directory. OpenClaw runs with
`OPENCLAW_CONFIG_READONLY=1`, so it never rewrites the config file.

The gateway listens on `127.0.0.1` only. Host networking makes that the host's loopback,
so nothing is exposed beyond this machine and `localhost` inside the container reaches
LM Studio directly.

## Setup

You need LM Studio and Docker with host networking: OrbStack (what I use), Docker
Desktop 4.34+ with host networking enabled, or Docker on Linux.

```bash
make init        # creates .env and workspace/ from the examples
```

Fill in `.env`:

- `OPENCLAW_GATEWAY_TOKEN`: `openssl rand -hex 32`
- `LM_STUDIO_URL`, `LM_STUDIO_API_KEY`: from LM Studio's Developer tab
- `TELEGRAM_BOT_TOKEN`: from @BotFather
- `TELEGRAM_OWNER_ID`: your numeric Telegram user id (@userinfobot tells you). It makes
  you the command owner, the account allowed to run admin commands from chat.
- `GEMINI_API_KEY`: the primary model, from Google AI Studio (free tier works)
- `COMPOSIO_API_KEY`: optional

Then edit `workspace/USER.md` so the agent knows who it works for.

In LM Studio, start the server and download the models listed in `config/openclaw.json`
plus `text-embedding-nomic-embed-text-v1.5` (used for memory search). Then, for each chat
model, open its settings under My Models and set the default context length to 32768.
LM Studio loads models on demand with that default (8192 otherwise), and Claw's prompt
doesn't fit in 8K.

```bash
make up
make dashboard   # prints a login link
```

The first time a browser connects it shows "pairing required":

```bash
make devices                 # find the pending requestId
make approve ID=<requestId>
```

Telegram works the same way. A new sender gets a pairing code from the bot:

```bash
docker compose exec gateway openclaw pairing approve telegram <code>
```

## Day to day

```bash
make up / make down
make restart     # after changing .env
make logs
make backup      # verified archive into backups/
```

Config edits are picked up live; watch `make logs` for `config hot reload applied`.
Anything else is `docker compose exec gateway openclaw <command>`.

## Models

The default is `OPENCLAW_MODEL` in `.env` (`google/gemini-3-flash-preview`); the fallback
in `agents.defaults.model.fallbacks` is the local Qwen, and `agents.defaults.heartbeat`
pins the 30-minute heartbeat to it so check-ins don't use the Gemini quota.
`agents.defaults.models` is just the list shown in the model picker.

Gemini 2.5 models reject the tool results OpenClaw sends, so stay on 3.x. Code Mode and
Tool Search are off (`tools.codeMode`, `tools.toolSearch`) so every model gets the real
tools; through them both models sent malformed tool calls. Web search is pinned to
DuckDuckGo: left on auto, OpenClaw picks Gemini's search grounding whenever a Gemini key
is set, and the free tier answers that with 429.

Local models are listed under `models.providers.lmstudio.models` with the exact LM
Studio model key (`lms ls`), referenced elsewhere as `lmstudio/<key>`. On a 16 GB Mac,
Qwen 3.5 9B (MLX, 4-bit) is about the largest that fits next to Docker; it handles short
replies but is too slow for long tool-heavy turns, which is why it's last in line.

Other providers can be connected from the dashboard (Settings → Models). The key is saved
in OpenClaw's state. If the provider also needs config changes (provider settings, fallback
order, plugin toggles), the UI reports that it couldn't apply them because the config is
read-only; add those to `config/openclaw.json`.

## Upgrading

The image is pinned in `OPENCLAW_IMAGE`. To move to a new release:

```bash
make backup
# bump the tag in .env
make up
make logs
```

If the new version wants config changes, Doctor prints them at startup as a merge
patch ("Config repairs pending"). Apply it to `config/openclaw.json` by hand.

## Troubleshooting

**Gateway restarts in a loop.** `make logs`. Usually the config fails validation
after an upgrade; the log names the keys to fix.

**Local models fail, everything answers from Gemini.** LM Studio's server is off, on a
different port, or the API key in `.env` is stale. Check with:

```bash
docker compose exec gateway sh -c 'curl -s -H "Authorization: Bearer $LM_STUDIO_API_KEY" $LM_STUDIO_URL/models'
```

**"context window too small".** Raise the context length for that model in LM Studio
and reload it.

**"Agent main database … still requires its existing native owner" at startup.** Known
on 2026.11.4: Doctor's cost-cache cleanup tries a database write it isn't allowed to
make during startup maintenance. Nothing is broken; it should go away with the next release.
