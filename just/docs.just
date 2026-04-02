set export

DEVTOOLS_DIR := justfile_directory()
RECOIL_DIR   := DEVTOOLS_DIR / "RecoilEngine"
COMPOSE_FILE := DEVTOOLS_DIR / "docker-compose.dev.yml"
COMPOSE      := "docker compose -f " + COMPOSE_FILE

# Generate lua library locally, then build docs and start Hugo dev server
server:
    just lua::library
    {{COMPOSE}} run --rm --service-ports recoil-docs server_dev -- --bind 0.0.0.0

# Generate lua library locally, then build Lua API pages only
generate:
    just lua::library
    {{COMPOSE}} run --rm recoil-docs lua_pages_only

# Start Hugo dev server without regenerating
server-only:
    {{COMPOSE}} run --rm --service-ports recoil-docs server -- --bind 0.0.0.0

# Full pipeline inside Docker (uses npm lua-doc-extractor, for CI-like builds)
generate-full:
    {{COMPOSE}} run --rm recoil-docs lua_pages

# Full pipeline inside Docker then serve (uses npm lua-doc-extractor)
server-full:
    {{COMPOSE}} run --rm --service-ports recoil-docs server_full -- --bind 0.0.0.0

# Rebuild the docs container image
build:
    {{COMPOSE}} build recoil-docs

#   TODO: Same workaround as lua::reset. doc/site/data/* are pipeline outputs tracked in git, so
#         local docs generation dirties the tree. Prefer these as build-only artifacts (CI publishes
#         them) rather than tracked outputs developers must constantly revert.

# Reset generated doc data files
reset:
    #!/usr/bin/env bash
    set -euo pipefail
    source "$DEVTOOLS_DIR/scripts/common.sh"
    info "Resetting doc site data in RecoilEngine..."
    cd "$RECOIL_DIR"
    git checkout -- doc/site/data/
    git clean -fd doc/site/data/
    ok "Doc data reset."
