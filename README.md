# FrankMega

Self-hosted, security-hardened file sharing service designed for sharing files with family and friends. Upload a file, get a time-limited download link with a counter, share it. Files auto-expire after a configurable TTL (max 24h) or when the download limit is reached.

Not intended for public-facing or large-scale deployments — the primary use case is a personal home server behind a Cloudflare Tunnel, where you control who gets an account via invite-only registration.

Built with Ruby on Rails 8.1, SQLite3, Tailwind CSS. Zero external services required — no Redis, no Postgres, no S3.

## Features

- **Time-limited sharing** — configurable TTL (1–24h) and download counter (1–100)
- **Two-step downloads** — public landing page shows file info before consuming a download
- **Invite-only registration** — first user becomes admin, everyone else needs an invitation code
- **Passkey / WebAuthn support** — passwordless login via hardware keys or platform authenticators
- **TOTP 2FA** — optional authenticator app verification with QR code setup
- **Admin panel** — manage users, invitations, files, and allowed MIME types
- **Aggressive rate limiting** — Rack::Attack throttles + automatic IP banning on suspicious behavior
- **Cloudflare-aware** — trusts Cloudflare proxy IPs so `request.ip` returns the real client
- **Dark mode** — toggle with system preference fallback
- **QR codes** — generated for every download link
- **Real-time notifications** — Turbo Streams notify uploaders when their files are downloaded
- **Auto-cleanup** — background jobs purge expired files and bans every 15 minutes

## Production Deployment (Docker Compose)

### 1. Generate secrets

```bash
# Secret key base
docker run --rm ruby:3.4.8-slim ruby -e "puts SecureRandom.hex(64)"

# ActiveRecord encryption keys (generates 3 keys, one per line)
docker run --rm ruby:3.4.8-slim ruby -e "3.times { puts SecureRandom.hex(32) }"
```

### 2. Create a `.env` file

> **Important:** `RAILS_MASTER_KEY` must be the value from `config/master.key` in your repo (created by `rails new`). Do **not** generate a new one — it must match the key that encrypted `config/credentials.yml.enc`.

```env
SECRET_KEY_BASE=<generated above>
RAILS_MASTER_KEY=<copy from config/master.key>

HOST=frankmega.yourdomain.com
WEBAUTHN_ORIGIN=https://frankmega.yourdomain.com
WEBAUTHN_RP_ID=frankmega.yourdomain.com

ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<first key>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<second key>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<third key>

SMTP_ADDRESS=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=you@gmail.com
SMTP_PASSWORD=your-app-password

# SSL: defaults to true — set to false only for local Docker testing without TLS
FORCE_SSL=true
```

### 3. Start the container

**Option A: Pull from Docker Hub (recommended)**

```bash
docker compose pull
docker compose up -d
```

**Option B: Build from source**

```bash
docker compose build
docker compose up -d
```

The pre-built image is available at [`akitaonrails/frankmega`](https://hub.docker.com/r/akitaonrails/frankmega) on Docker Hub.

The app listens on port **3100** (mapped from container port 80 via Thruster). On first visit, you'll be prompted to create the admin account.

Data is persisted in two Docker volumes: `uploads` (files) and `db_data` (SQLite databases).

### 4. Cloudflare Tunnel setup

1. In the [Cloudflare Zero Trust dashboard](https://one.dash.cloudflare.com/), create a tunnel pointing to your server
2. Add a public hostname rule:
   - **Subdomain:** `frankmega` (or your choice)
   - **Domain:** `yourdomain.com`
   - **Service:** `http://localhost:3100`
3. Under **SSL/TLS** settings for the domain, set encryption mode to **Full**
4. Set `FORCE_SSL=true` in your `.env` — this enables `assume_ssl` and `force_ssl` so Rails trusts the `X-Forwarded-Proto` header from Cloudflare

The app automatically trusts [Cloudflare IP ranges](https://www.cloudflare.com/ips/) so that rate limiting and IP banning work against real client IPs, not Cloudflare's.

> **Important:** The `HOST`, `WEBAUTHN_ORIGIN`, and `WEBAUTHN_RP_ID` env vars must match the domain configured in Cloudflare. WebAuthn will fail silently if these don't match.

## Local Development

### Prerequisites

- Ruby 3.4.8 (use [mise](https://mise.jdx.dev/), rbenv, or asdf)
- Bundler

### Setup

```bash
bundle install
rails db:prepare
rails db:seed        # seeds default allowed MIME types
bin/dev              # starts Rails server + Tailwind watcher on port 3000
```

`bin/dev` uses foreman to run both the Rails server and the Tailwind CSS watcher.

### Security settings in development

Rate limits are 10x more lenient and IP banning is disabled by default. See `config/initializers/security.rb` to adjust:

| Setting                     | Production | Development |
|-----------------------------|------------|-------------|
| Rate limit multiplier       | 1x         | 10x         |
| Ban duration                | 1 hour     | 1 minute    |
| IP banning enabled          | yes        | no          |
| Invalid hash attempts limit | 3          | 10          |
| Minimum password length     | 12 chars   | 12 chars    |

## Running Tests

```bash
bundle exec rails test                 # full test suite
bundle exec rails test test/models     # model tests only
bundle exec rails test test/controllers/downloads_controller_test.rb  # single file
```

### Linters and security checks

```bash
bundle exec rubocop                    # style (rubocop-rails-omakase)
bundle exec brakeman --no-pager        # static security analysis
bundle exec bundler-audit check        # vulnerable gem detection
```

All four checks run automatically via [Lefthook](https://github.com/evilmartians/lefthook) git hooks — rubocop, brakeman, and bundler-audit on pre-commit, full test suite on pre-push.

## License

MIT
