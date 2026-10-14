# Startline Docs

Self-hosted [Outline](https://github.com/outline/outline) wiki for team documentation at `docs.startlineau.com`.

This repo holds the **app deploy config** (Docker Compose). Infrastructure (droplet,
DNS, Cognito) lives in [`startline-infra`](https://github.com/StartlineAU/startline-infra).

## Repo split

| Concern | Repo |
|---|---|
| Droplet, `docs.startlineau.com` DNS, Cognito pool/domain/client | `startline-infra` |
| Outline app: `docker-compose.yml`, `docker.env.example` | this repo |

## Deploy / update the app

The droplet is created by `startline-infra`. To deploy or update Outline:

```bash
# 1. Build docker.env from the startline/docs secret
#    (or copy an existing docker.env)

# 2. Ship it to the droplet
scp docker-compose.yml docker.env root@<droplet-ip>:/opt/docs/

# 3. Start / update
ssh root@<droplet-ip> "cd /opt/docs && docker compose up -d"
```

Upgrade Outline:

```bash
ssh root@<droplet-ip> "cd /opt/docs && docker compose pull && docker compose up -d"
```

## Adding users

Users are managed in the Cognito pool `startline-docs-prod` (see `startline-infra`):

```bash
aws cognito-idp admin-create-user \
  --user-pool-id ap-southeast-2_yz6f102Mk \
  --username user@example.com \
  --user-attributes Name=name,Value="Full Name" \
  --temporary-password TempPass123! \
  --message-action SUPPRESS
```

User signs in at `https://docs.startlineau.com` via OIDC — Outline creates their
account automatically.

## Architecture

```
Cloudflare ──► DigitalOcean Droplet (SYD1) ──► Outline (Docker)
                     │                              │
                     └── Docker Compose              ├── PostgreSQL (Docker)
                                                      ├── Redis (Docker)
                                                      └── Local filesystem (uploads)

Auth: AWS Cognito (OIDC) · DNS/TLS: Cloudflare
```

Secrets live in AWS Secrets Manager `startline/docs` (loaded into `docker.env`).
