# Startline Docs

Outline (self-hosted) documentation server at `docs.startlineau.com`.

## Infra

| Resource | Where | Management |
|---|---|---|
| Docker Compose | This repo | `docker compose up` |
| Cognito user pool | AWS, created via CLI one-shot | Manual (`aws cognito-idp`) |
| DO droplet | This repo terraform | `terraform apply` |
| DNS `docs.startlineau.com CNAME` | Main repo terraform (`cloudflare-dns.tf`) | `terraform apply` |
| Secrets | AWS SM `startline/docs` | `setup.sh` |

## Setup

```bash
# One-time: Cognito pool + domain + app client
aws cognito-idp create-user-pool --pool-name startline-docs-{env} ...
aws cognito-idp create-user-pool-domain ...
aws cognito-idp create-user-pool-client ...

# Bootstrap secrets
./setup.sh

# Deploy droplet (reads DO token from AWS SM startline/tf-bootstrap)
cd terraform && terraform apply

# On droplet
cd /opt/docs && direnv allow && docker compose up
```

## Adding users

```bash
aws cognito-idp admin-create-user --user-pool-id <id> --username user@example.com --temporary-password TempPass123! --message-action SUPPRESS
```

User logs in via OIDC on first visit — Outline auto-provisions.

## Upgrading

```bash
docker compose pull && docker compose up -d
```
