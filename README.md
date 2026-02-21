# BAR Devtools

Local development environment for [Beyond All Reason](https://www.beyondallreason.info/) -- spins up **Teiserver** (lobby server), **PostgreSQL**, **SPADS** (autohost), and **bar-lobby** (game client) with a single command.

Everything server-side runs in Docker. The game client runs natively.

## Quick Start

```bash
git clone https://github.com/thvl3/BAR-Devtools.git
cd BAR-Devtools
./devtools.sh init
./devtools.sh up
```

`init` walks you through installing dependencies, cloning repositories, and building Docker images. You only need to run it once.

`up` starts PostgreSQL and Teiserver. On first run it seeds the database with test data and creates default accounts (~2-3 minutes). Subsequent starts are fast.

Once running:

| Service | URL |
|---------|-----|
| Teiserver Web UI | http://localhost:4000 |
| Teiserver HTTPS | https://localhost:8888 |
| Spring Protocol | `localhost:8200` (TCP) / `:8201` (TLS) |
| PostgreSQL | `localhost:5433` |

**Default login:** `root@localhost` / `password`

## Requirements

- **Linux** (Arch, Debian/Ubuntu, or Fedora)
- **Docker** with Compose V2
- **Git**
- **Node.js** (only needed if running bar-lobby)

`./devtools.sh install-deps` will detect your distro and install what's missing.

## Commands

### Getting Started

| Command | Description |
|---------|-------------|
| `init` | Full first-time setup: install deps, clone repos, build images |
| `install-deps` | Install system packages (docker, git, nodejs) |

### Services

| Command | Description |
|---------|-------------|
| `up [lobby] [spads]` | Start services (options are additive) |
| `down` | Stop all services |
| `status` | Show running containers |
| `logs [service]` | Tail logs (postgres, teiserver, spads, or all) |
| `lobby` | Start bar-lobby dev server standalone |
| `shell [service]` | Shell into a container (default: teiserver) |
| `reset` | Destroy all data and rebuild from scratch |

### Repositories

| Command | Description |
|---------|-------------|
| `clone [group]` | Clone/update repos. Groups: `core`, `extra`, `all` |
| `repos` | Show status of all configured repositories |
| `update` | Pull latest on all cloned repos (fast-forward only) |

## Using Your Own Forks

`repos.conf` lists the default upstream repositories. To use your own forks or work on specific branches:

```bash
cp repos.conf repos.local.conf
```

Edit `repos.local.conf` -- only include the repos you want to override:

```
teiserver  https://github.com/yourname/teiserver.git  your-branch  core
bar-lobby  https://github.com/yourname/bar-lobby.git  your-branch  core
```

Then clone or re-clone:

```bash
./devtools.sh clone core
```

`repos.local.conf` is gitignored so it won't affect anyone else.

## Repository Config Format

`repos.conf` uses a simple whitespace-delimited format:

```
# directory    url    branch    group
teiserver      https://github.com/beyond-all-reason/teiserver.git    master    core
```

- **directory** -- local folder name (created by `clone`)
- **url** -- git clone URL
- **branch** -- branch to checkout
- **group** -- `core` (required for the dev stack) or `extra` (optional)

## Architecture

```
BAR-Devtools/
├── devtools.sh                  # Main CLI script
├── repos.conf                   # Repository sources & branches
├── docker-compose.dev.yml       # Service definitions
├── docker/
│   ├── teiserver.dev.Dockerfile # Teiserver dev image (Elixir + Phoenix)
│   ├── teiserver-entrypoint.sh  # DB init, seeding, migrations
│   ├── teiserver.dockerignore   # Build context optimization
│   ├── setup-spads-bot.exs      # Creates SPADS bot account in Teiserver
│   ├── spads-dev-entrypoint.sh  # SPADS startup + game data download
│   └── spads_dev.conf           # Simplified SPADS config for dev
├── teiserver/                   # ← cloned by devtools.sh (gitignored)
├── bar-lobby/                   # ← cloned by devtools.sh (gitignored)
└── spads_config_bar/            # ← cloned by devtools.sh (gitignored)
```

### What the Docker stack does

- **PostgreSQL 16** -- database for Teiserver, persisted in a Docker volume
- **Teiserver** -- runs in Elixir dev mode (`mix phx.server`). On first boot:
  - Creates the database and runs migrations
  - Seeds fake data (test users, matchmaking data)
  - Sets up Tachyon OAuth
  - Creates a `spadsbot` account with Bot/Moderator roles
- **SPADS** (optional, `up spads`) -- Perl autohost using `badosu/spads:latest`. Downloads game data via `pr-downloader` on first run. Connects to Teiserver via Spring protocol on port 8200.
- **bar-lobby** -- Electron/Vue.js game client, runs natively on the host (not in Docker)

### Ports

| Port | Service |
|------|---------|
| 4000 | Teiserver HTTP |
| 5433 | PostgreSQL (configurable via `BAR_POSTGRES_PORT`) |
| 8200 | Spring lobby protocol (TCP) |
| 8201 | Spring lobby protocol (TLS) |
| 8888 | Teiserver HTTPS |

## SPADS

SPADS is optional and started separately because it requires downloading ~300MB of game data on first run. The download depends on external rapid repositories that can be unreliable.

```bash
./devtools.sh up spads        # Start with SPADS
./devtools.sh logs spads      # Check SPADS status
```

The SPADS bot account (`spadsbot` / `password`) is created automatically during Teiserver initialization.

## Troubleshooting

**Port 5432/5433 conflict with host PostgreSQL:**
Either stop your local PostgreSQL (`sudo systemctl stop postgresql`) or change the port:
```bash
BAR_POSTGRES_PORT=5434 ./devtools.sh up
```

**Teiserver takes forever on first run:**
The initial database seeding includes generating fake data. Follow progress with:
```bash
./devtools.sh logs teiserver
```

**SPADS fails with "No Spring map/mod found":**
Game data download may have failed. Check logs and retry:
```bash
./devtools.sh logs spads
./devtools.sh down
./devtools.sh up spads
```

**Docker permission denied:**
```bash
sudo usermod -aG docker $USER
# Then log out and back in
```

**Nuclear option -- start completely fresh:**
```bash
./devtools.sh reset
./devtools.sh up
```
