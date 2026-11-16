# openclaw

My [OpenClaw](https://openclaw.ai/) setup: a personal AI assistant that runs in Docker,
talks to me over Telegram and a web dashboard, and uses local models from
[LM Studio](https://lmstudio.ai/) with Gemini as the cloud fallback.

## Layout

| Path | What it is | In git |
|---|---|---|
| `docker-compose.yml` | One `gateway` service, pinned image, state in a Docker volume | yes |
| `config/openclaw.json` | OpenClaw config. Mounted read-only; values come from `.env` as `${VAR}` | yes |
| `.env` | Secrets and anything machine-specific (image tag, port, model, URLs) | no |
| `workspace/` | The agent's persona and memory files | no |
| `workspace.example/` | Starting point for `workspace/` | yes |
| `backups/` | Output of `make backup` | no |

Runtime state (sessions, device pairing, Telegram state, installed plugins) lives in the
`openclaw_state` Docker volume, not in this directory. OpenClaw runs with
`OPENCLAW_CONFIG_READONLY=1`, so it never rewrites the config file.

## Setup

You need Docker (I use OrbStack) and LM Studio.

```bash
make init        # creates .env and workspace/ from the examples
```

Fill in `.env`:

- `OPENCLAW_GATEWAY_TOKEN`: `openssl rand -hex 32`
- `LM_STUDIO_URL`, `LM_STUDIO_API_KEY`: from LM Studio's Developer tab. Keep
  `host.docker.internal` as the host, only the port changes.
- `TELEGRAM_BOT_TOKEN`: from @BotFather
- `GEMINI_API_KEY`, `COMPOSIO_API_KEY`: optional

Then edit `workspace/USER.md` so the agent knows who it works for.

In LM Studio, start the server, download the models listed in `config/openclaw.json`
plus `text-embedding-nomic-embed-text-v1.5` (used for memory search), and set the
context length to at least 32768 for the chat models. OpenClaw refuses anything under 16K.

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

Local models are listed under `models.providers.lm-studio.models` with the exact LM
Studio model key (`lms ls`), referenced elsewhere as `lm-studio/<key>`. The default is
`OPENCLAW_MODEL` in `.env`; fallbacks are in `agents.defaults.model.fallbacks`.
`agents.defaults.models` is just the list shown in the model picker.

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
