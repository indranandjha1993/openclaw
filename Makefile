.DEFAULT_GOAL := help

# ──────────────────────────────────────────────
#  OpenClaw — Local AI Assistant (Docker)
# ──────────────────────────────────────────────

## ── Lifecycle ──────────────────────────────────

up: ## Start the OpenClaw gateway
	@docker compose up -d openclaw-gateway
	@echo "\n  Dashboard: http://127.0.0.1:18789\n"

down: ## Stop all OpenClaw services
	@docker compose --profile cli down

restart: ## Restart the gateway (picks up .env + config changes)
	@docker compose up -d --force-recreate openclaw-gateway

## ── Observability ─────────────────────────────

logs: ## Tail gateway logs (Ctrl+C to stop)
	@docker compose logs -f openclaw-gateway

status: ## Show running containers and health
	@docker compose ps -a

## ── Interaction ───────────────────────────────

cli: ## Open an interactive CLI session
	@docker compose run --rm openclaw-cli

dashboard: ## Print the authenticated dashboard URL
	@docker compose run --rm openclaw-cli openclaw dashboard --no-open

health: ## Check gateway health and reachability
	@curl -sf http://127.0.0.1:18789/health > /dev/null 2>&1 && echo "  Gateway: healthy" || echo "  Gateway: unreachable"
	@docker compose ps openclaw-gateway --format "  Status:  {{.Status}}"

devices: ## List pending and paired devices
	@docker exec openclaw-gateway openclaw devices list

approve: ## Approve all pending device pairing requests
	@docker exec openclaw-gateway openclaw devices list --json 2>/dev/null | \
		python3 -c "import sys,json; [print(r['id']) for r in json.load(sys.stdin).get('pending',[])]" 2>/dev/null | \
		while read id; do docker exec openclaw-gateway openclaw devices approve "$$id" && echo "  Approved: $$id"; done || \
		echo "  No pending devices (or use 'make devices' to check manually)"

## ── Configuration ─────────────────────────────

config: ## Open openclaw.json in your editor
	@$${EDITOR:-nano} config/openclaw.json

token: ## Generate and save a new gateway token (run `make restart` after)
	@TOKEN=$$(openssl rand -hex 32) && \
	 sed -i '' "s/^OPENCLAW_GATEWAY_TOKEN=.*/OPENCLAW_GATEWAY_TOKEN=$$TOKEN/" .env && \
	 echo "\n  New token: $$TOKEN" && \
	 echo "  Run 'make restart' to apply.\n"

env: ## Show current .env values (secrets masked)
	@awk -F= '/TOKEN|API_KEY/{printf "  %-30s %s…\n", $$1, substr($$2,1,8)} !/TOKEN|API_KEY/{printf "  %-30s %s\n", $$1, $$2}' .env

## ── Maintenance ───────────────────────────────

update: ## Pull latest image and restart
	@docker compose pull
	@docker compose up -d openclaw-gateway
	@echo "\n  Updated to latest image.\n"

destroy: ## Remove containers, volumes, and images (keeps config/)
	@echo "This will remove all OpenClaw containers and images."
	@read -p "  Continue? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker compose --profile cli down --rmi all --volumes --remove-orphans
	@echo "\n  Cleaned up. Config and workspace preserved.\n"

## ── Help ──────────────────────────────────────

help: ## Show this help
	@echo ""
	@echo "  \033[1mOpenClaw Manager\033[0m"
	@echo "  Usage: make <target>"
	@echo ""
	@grep -E '^## ──' $(MAKEFILE_LIST) | sed 's/## /  /' | sed 's/─//g' | sed 's/  *$$//'
	@grep -E '^[a-z][a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | \
		awk -F ':.*## ' '{ printf "    \033[36m%-14s\033[0m %s\n", $$1, $$2 }'
	@echo ""

.PHONY: up down restart logs status cli dashboard health devices approve config token env update destroy help
