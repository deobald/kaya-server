# Plan: Docker Compose for Portainer Deployment

## Context

Kaya Server needed a `docker-compose.yml` for deployment as a Portainer "Stack" on a single VPS. TLS termination is handled externally (e.g. Caddy, nginx, or similar -- not managed by this compose file).

A secondary goal was to fix the Dockerfile, which still referenced SQLite despite the project having migrated to PostgreSQL.

## Summary of Changes

### 1. Dockerfile: Replace SQLite with PostgreSQL client libraries

The Rails-generated `Dockerfile` included `sqlite3` but Kaya uses PostgreSQL.

**File:** `Dockerfile`

- Base stage: replaced `sqlite3` with `libpq5` (PostgreSQL runtime client library)
- Build stage: added `libpq-dev` (headers for compiling the `pg` gem)

### 2. Docker Compose for Portainer

**File:** `docker-compose.yml` (new)

A Portainer-compatible stack with two services:
- `db`: PostgreSQL 17 with named volume, init scripts, healthcheck, port bound to `127.0.0.1:5432`
- `web`: pulls `deobald/kaya_server:latest` from Docker Hub, depends on healthy `db`, exposes port 80 on `127.0.0.1:3000`

**File:** `docker-compose.override.yml` (new)

Local override that adds `build: .` to the `web` service, so `docker compose up --build` builds locally. Docker Compose merges this automatically. Portainer ignores it unless explicitly added.

### 3. Database initialization scripts

**File:** `db/production.sql` (new)

Creates all four production databases:
- `kaya_production`, `kaya_production_cache`, `kaya_production_queue`, `kaya_production_cable`

**File:** `docker/02-setup-extensions.sh` (new)

Enables PostgreSQL extensions after the databases are created:
- `pgcrypto` on all four databases (required for UUID primary keys)
- `pg_trgm` on `kaya_production` only (for future full-text search, ref: ADR 0005)

Files are numbered (`01-`, `02-`) to ensure correct execution order in `/docker-entrypoint-initdb.d/`.

### 4. Docker entrypoint fix

**File:** `bin/docker-entrypoint`

- Changed `db:prepare` to `db:prepare:all` so that all four databases (primary, cache, queue, cable) are created and migrated on boot, not just `primary`

### 5. Supporting files

**File:** `.env.example` (new)

Documents required environment variables: `RAILS_MASTER_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`.

**File:** `.dockerignore`

- Updated stale SQLite comment
- Added `docker-compose*.yml` and `docker/` to exclusions

## Files Changed

| File | Action |
|------|--------|
| `Dockerfile` | Edit |
| `bin/docker-entrypoint` | Edit |
| `.dockerignore` | Edit |
| `db/production.sql` | Create |
| `docker/02-setup-extensions.sh` | Create |
| `docker-compose.yml` | Create |
| `docker-compose.override.yml` | Create |
| `.env.example` | Create |

## Deployment Commands

```bash
# Build and push image to Docker Hub:
docker build -t deobald/kaya_server:latest .
docker push deobald/kaya_server:latest

# Local build + run (uses docker-compose.override.yml automatically):
docker compose up --build
```

## Prerequisites

- A reverse proxy (e.g. Caddy) in front for TLS termination
- Environment variables set in Portainer or `.env`: `RAILS_MASTER_KEY`, `POSTGRES_USER`, `POSTGRES_PASSWORD`
