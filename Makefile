# Shortcuts for docker compose. For any other OpenClaw command:
#   docker compose exec gateway openclaw <command>

# First run: create .env and workspace/ from the examples. OpenClaw expects
# its config to be private (git doesn't keep file modes).
init:
	test -f .env || cp .env.example .env
	test -d workspace || cp -R workspace.example workspace
	chmod 600 .env config/openclaw.json

up:
	docker compose up -d

down:
	docker compose down

# Recreate the container so .env changes apply (config edits apply on their own)
restart:
	docker compose up -d --force-recreate

logs:
	docker compose logs -f gateway

# Dashboard link that signs in with the gateway token
dashboard:
	@echo "http://localhost:$$(grep ^OPENCLAW_GATEWAY_PORT= .env | cut -d= -f2)/#token=$$(grep ^OPENCLAW_GATEWAY_TOKEN= .env | cut -d= -f2)"

devices:
	docker compose exec gateway openclaw devices list

# make approve ID=<requestId from make devices>
approve:
	docker compose exec gateway openclaw devices approve $(ID)

# Verified archive of sessions, pairing and workspace, saved to backups/
backup:
	mkdir -p backups
	docker compose exec gateway sh -c 'mkdir -p /tmp/backup && openclaw backup create --verify --output /tmp/backup'
	docker compose cp gateway:/tmp/backup/. backups/
	docker compose exec gateway rm -rf /tmp/backup

.PHONY: init up down restart logs dashboard devices approve backup
