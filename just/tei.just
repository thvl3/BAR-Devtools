set export

DEVTOOLS_DIR    := justfile_directory()
COMPOSE_FILE    := DEVTOOLS_DIR / "docker-compose.dev.yml"
COMPOSE         := "docker compose -f " + COMPOSE_FILE
TEISERVER_DIR   := DEVTOOLS_DIR / "teiserver"

[private]
require-setup:
    #!/usr/bin/env bash
    if [ ! -d "{{TEISERVER_DIR}}" ]; then
        echo "Error: teiserver is not cloned." >&2
        echo "Run: just setup::init" >&2
        exit 1
    fi

# Run teiserver mix tests
mix *args: require-setup
    {{COMPOSE}} run --rm -e MIX_ENV=test --entrypoint "" \
        -v {{TEISERVER_DIR}}/test:/app/test \
        teiserver bash -c "mix ecto.create --quiet 2>/dev/null; mix ecto.migrate --quiet && mix test {{args}}"
