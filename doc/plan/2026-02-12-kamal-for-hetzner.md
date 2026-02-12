# Plan: Kamal Deployment to Hetzner VPS

## Context

Building on the Docker Compose / Portainer work in [2026-02-11-docker-compose-for-portainer.md](./2026-02-11-docker-compose-for-portainer.md), Kaya Server needed a production deployment via Kamal (the Rails-native deployment tool) targeting a Hetzner VPS.

The domain is `savebutton.com`. The Hetzner VPS public IP is `46.225.121.36`. Kamal handles TLS termination via Let's Encrypt. Container images are hosted on Docker Hub under `deobald/kaya_server`.

## Summary of Changes

### 1. Database configuration with separate databases

Production uses four separate PostgreSQL databases (primary, cache, queue, cable) on a single Postgres instance. A `primary_production` YAML anchor centralizes the connection config (`DB_HOST`, `POSTGRES_USER`, `POSTGRES_PASSWORD`), and each database inherits from it.

**File:** `config/database.yml`

- Added `primary_production` anchor with `host`, `username`, `password` from env vars
- Each production database inherits from `primary_production` and specifies its own `database:` name
- `DB_HOST` env var points to the Postgres container on the Kamal Docker network (`kaya_server-db`)

**Why separate databases instead of a single shared `DATABASE_URL`?** This follows the Kamal deployment conventions demonstrated on kamal-deploy.org. It also avoids a Rails quirk where `DATABASE_URL` is only automatically applied to the `primary` database -- non-primary databases (cache, queue, cable) would need separate `CACHE_DATABASE_URL`, `QUEUE_DATABASE_URL`, and `CABLE_DATABASE_URL` env vars or inline ERB URL derivation.

### 2. Kamal deploy configuration

**File:** `config/deploy.yml`

- **Server:** `46.225.121.36` (Hetzner VPS)
- **Proxy:** `ssl: true`, `host: savebutton.com`, `app_port: 80` -- Kamal proxy terminates TLS via Let's Encrypt
- **Registry:** Docker Hub (`username: deobald`, password from `KAMAL_REGISTRY_PASSWORD`)
- **Image:** `deobald/kaya_server`
- **Environment:**
  - Secrets: `RAILS_MASTER_KEY`, `POSTGRES_PASSWORD`
  - Clear: `SOLID_QUEUE_IN_PUMA: true`, `DB_HOST: kaya_server-db`, `RAILS_LOG_LEVEL: debug`
- **Volumes:** `kaya_server_storage:/rails/storage` (ActiveStorage files)
- **Accessory (`db`):** PostgreSQL 17 on the same host, port bound to `127.0.0.1:5432`, with `db/production.sql` and `docker/02-setup-extensions.sh` mounted as numbered init scripts (`01-`, `02-`) to ensure correct execution order

**File:** `.kamal/secrets`

- `KAMAL_REGISTRY_PASSWORD` -- Docker Hub access token, sourced from shell environment
- `RAILS_MASTER_KEY` -- read from `config/master.key`
- `POSTGRES_PASSWORD` -- sourced from shell environment

### 3. Rails production configuration

**File:** `config/environments/production.rb`

- Enabled `config.assume_ssl = true` (required when behind TLS-terminating proxy)
- Enabled `config.force_ssl = true` (HSTS, secure cookies)
- Enabled `config.ssl_options` with health check exclusion for `/up`
- Set `action_mailer.default_url_options` host to `savebutton.com`

### 4. Job processing

Solid Queue runs inside Puma via `SOLID_QUEUE_IN_PUMA: true` (set in `deploy.yml`). This is the standard Rails 8 single-server setup. The `plugin :solid_queue` line in `config/puma.rb` activates when this env var is present, starting the Solid Queue supervisor as a background thread alongside the web server.

In development, `SOLID_QUEUE_IN_PUMA` is not set, so jobs require a separate `bin/jobs` process. This is by design -- two processes in dev for easier debugging, one process in prod for simpler deployment.

The commented-out `job:` server role in `deploy.yml` is available for future use if job processing needs to be split to a dedicated machine.

## Files Changed

| File | Action |
|------|--------|
| `config/database.yml` | Edit |
| `config/deploy.yml` | Edit |
| `config/environments/production.rb` | Edit |
| `.kamal/secrets` | Edit |

## Deployment Commands

```bash
# First-time setup (installs Docker on VPS, boots accessory + app):
export KAMAL_REGISTRY_PASSWORD=<docker-hub-access-token>
export POSTGRES_PASSWORD=<strong-password>
kamal setup

# Subsequent deploys:
export KAMAL_REGISTRY_PASSWORD=<docker-hub-access-token>
export POSTGRES_PASSWORD=<strong-password>
kamal deploy
```

## Prerequisites

- DNS A record: `savebutton.com` -> `46.225.121.36` (required for Let's Encrypt)
- SSH key access to the Hetzner VPS from the local machine
- Environment variables: `KAMAL_REGISTRY_PASSWORD`, `POSTGRES_PASSWORD`
- `config/master.key` present locally (read by `.kamal/secrets`)

## Outstanding Concerns

1. **`RAILS_LOG_LEVEL: debug` in production** -- currently set to `debug` for initial deployment troubleshooting. Should be changed to `info` once the deployment is stable.
