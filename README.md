# Startline Docs

Self-hosted [Outline](https://github.com/outline/outline) wiki for team documentation at `docs.startlineau.com`.

## Prerequisites

- Docker + Docker Compose
- direnv
- AWS CLI (authenticated)
- DO CLI (`doctl`, for droplet management)

## Quick start (local dev)

```bash
# Clone
git clone git@github.com:StartlineAU/docs.git
cd docs

# Bootstrap (first time only — generates secrets, creates SM entries)
./setup.sh

# Unlock env vars
direnv allow

# Start
docker compose up
```

Open http://localhost:3000.

## Production

### 1. Cognito pool (one-time)

```bash
aws cognito-idp create-user-pool --pool-name startline-docs-prod --policies 'PasswordPolicy={MinimumLength=12,RequireUppercase=true,RequireLowercase=true,RequireNumbers=true,RequireSymbols=true}' --auto-verified-attributes email --schema Name=email,Required=true,Mutable=false

aws cognito-idp create-user-pool-domain --domain docs-auth-prod --user-pool-id <pool-id>

aws cognito-idp create-user-pool-client --client-name outline --user-pool-id <pool-id> --generate-secret --callback-urls '["https://docs.startlineau.com/auth/oidc.callback"]' --logout-urls '["https://docs.startlineau.com"]' --allowed-o-auth-flows authorization_code --allowed-o-auth-scopes openid email profile --supported-identity-providers COGNITO
```

### 2. Deploy droplet

```bash
cd terraform
terraform init
terraform apply   # prompts for DO token
```

### 3. Secrets

`ssh root@<droplet-ip>`, then:

```bash
cd /opt/docs
./setup.sh         # populate AWS SM with secrets
direnv allow
docker compose up -d
```

### 4. DNS

Cloudflare DNS `docs.startlineau.com CNAME → droplet IP` managed in the main Startline repo terraform (`cloudflare-dns.tf`).

## Adding users

```bash
aws cognito-idp admin-create-user \
  --user-pool-id <pool-id> \
  --username user@example.com \
  --temporary-password TempPass123! \
  --message-action SUPPRESS
```

User signs in at `https://docs.startlineau.com` via OIDC — Outline creates their account automatically.

## Upgrading

```bash
docker compose pull && docker compose up -d
```

## Architecture

```
Cloudflare ──► DigitalOcean Droplet (SYD1, $6/mo) ──► Outline (Docker)
                       │                                   │
                       └── Docker Compose                   ├── PostgreSQL (Docker)
                                                            ├── Redis (Docker)
                                                            └── Local filesystem (uploads)
```
