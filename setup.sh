#!/usr/bin/env bash
set -euo pipefail

echo "=== Startline Docs — Bootstrap ==="
echo ""

# 1. Generate secrets
OUTLINE_SECRET_KEY=$(openssl rand -hex 32)
UTILS_SECRET=$(openssl rand -hex 32)

# 2. Prompt for Cognito details (from the one-shot CLI you ran)
echo "Enter the Cognito User Pool ID (e.g. ap-southeast-2_XXXXX):"
read -r COGNITO_POOL_ID

echo "Enter the Cognito App Client ID:"
read -r COGNITO_CLIENT_ID

echo "Enter the Cognito App Client Secret:"
read -rs COGNITO_CLIENT_SECRET
echo ""

echo "Enter the Cognito Domain prefix (e.g. docs-auth-nonprod):"
read -r COGNITO_DOMAIN_PREFIX

# 3. Prompt for Resend SMTP credentials
echo "Enter Resend SMTP Host (e.g. email-smtp.ap-southeast-2.amazonaws.com):"
read -r SMTP_HOST

echo "Enter Resend SMTP Username:"
read -r SMTP_USERNAME

echo "Enter Resend SMTP Password:"
read -rs SMTP_PASSWORD
echo ""

# 4. Build Cognito OIDC URIs
COGNITO_REGION="${COGNITO_POOL_ID%_*}"
OIDC_AUTH_URI="https://${COGNITO_DOMAIN_PREFIX}.auth.${COGNITO_REGION}.amazoncognito.com/oauth2/authorize"
OIDC_TOKEN_URI="https://${COGNITO_DOMAIN_PREFIX}.auth.${COGNITO_REGION}.amazoncognito.com/oauth2/token"
OIDC_USERINFO_URI="https://${COGNITO_DOMAIN_PREFIX}.auth.${COGNITO_REGION}.amazoncognito.com/oauth2/userinfo"
OIDC_LOGOUT_URI="https://${COGNITO_DOMAIN_PREFIX}.auth.${COGNITO_REGION}.amazoncognito.com/logout"

# 5. Write secret to AWS Secrets Manager
SECRET_JSON=$(cat <<EOF
{
  "OUTLINE_SECRET_KEY": "${OUTLINE_SECRET_KEY}",
  "UTILS_SECRET": "${UTILS_SECRET}",
  "COGNITO_POOL_ID": "${COGNITO_POOL_ID}",
  "COGNITO_CLIENT_ID": "${COGNITO_CLIENT_ID}",
  "COGNITO_CLIENT_SECRET": "${COGNITO_CLIENT_SECRET}",
  "COGNITO_DOMAIN_PREFIX": "${COGNITO_DOMAIN_PREFIX}",
  "OIDC_AUTH_URI": "${OIDC_AUTH_URI}",
  "OIDC_TOKEN_URI": "${OIDC_TOKEN_URI}",
  "OIDC_USERINFO_URI": "${OIDC_USERINFO_URI}",
  "OIDC_LOGOUT_URI": "${OIDC_LOGOUT_URI}",
  "SMTP_HOST": "${SMTP_HOST}",
  "SMTP_PORT": "587",
  "SMTP_USERNAME": "${SMTP_USERNAME}",
  "SMTP_PASSWORD": "${SMTP_PASSWORD}",
  "SMTP_FROM_EMAIL": "docs@startlineau.com",
  "SMTP_FROM_NAME": "Startline Docs"
}
EOF
)

aws secretsmanager create-secret \
  --name startline/docs \
  --description "Startline Outline documentation server" \
  --secret-string "$SECRET_JSON"

echo ""
echo "Secret startline/docs created."

# 6. Write docker.env from template + secrets
cat docker.env.example > docker.env

# Overwrite secret values
if [[ "$OSTYPE" == "darwin"* ]]; then
  sed -i '' "s|SECRET_KEY=change_me|SECRET_KEY=${OUTLINE_SECRET_KEY}|" docker.env
  sed -i '' "s|UTILS_SECRET=change_me|UTILS_SECRET=${UTILS_SECRET}|" docker.env
  sed -i '' "s|OIDC_CLIENT_ID=change_me|OIDC_CLIENT_ID=${COGNITO_CLIENT_ID}|" docker.env
  sed -i '' "s|OIDC_CLIENT_SECRET=change_me|OIDC_CLIENT_SECRET=${COGNITO_CLIENT_SECRET}|" docker.env
  sed -i '' "s|OIDC_AUTH_URI=change_me|OIDC_AUTH_URI=${OIDC_AUTH_URI}|" docker.env
  sed -i '' "s|OIDC_TOKEN_URI=change_me|OIDC_TOKEN_URI=${OIDC_TOKEN_URI}|" docker.env
  sed -i '' "s|OIDC_USERINFO_URI=change_me|OIDC_USERINFO_URI=${OIDC_USERINFO_URI}|" docker.env
  sed -i '' "s|OIDC_LOGOUT_URI=change_me|OIDC_LOGOUT_URI=${OIDC_LOGOUT_URI}|" docker.env
  sed -i '' "s|SMTP_HOST=change_me|SMTP_HOST=${SMTP_HOST}|" docker.env
  sed -i '' "s|SMTP_USERNAME=change_me|SMTP_USERNAME=${SMTP_USERNAME}|" docker.env
  sed -i '' "s|SMTP_PASSWORD=change_me|SMTP_PASSWORD=${SMTP_PASSWORD}|" docker.env
else
  sed -i "s|SECRET_KEY=change_me|SECRET_KEY=${OUTLINE_SECRET_KEY}|" docker.env
  sed -i "s|UTILS_SECRET=change_me|UTILS_SECRET=${UTILS_SECRET}|" docker.env
  sed -i "s|OIDC_CLIENT_ID=change_me|OIDC_CLIENT_ID=${COGNITO_CLIENT_ID}|" docker.env
  sed -i "s|OIDC_CLIENT_SECRET=change_me|OIDC_CLIENT_SECRET=${COGNITO_CLIENT_SECRET}|" docker.env
  sed -i "s|OIDC_AUTH_URI=change_me|OIDC_AUTH_URI=${OIDC_AUTH_URI}|" docker.env
  sed -i "s|OIDC_TOKEN_URI=change_me|OIDC_TOKEN_URI=${OIDC_TOKEN_URI}|" docker.env
  sed -i "s|OIDC_USERINFO_URI=change_me|OIDC_USERINFO_URI=${OIDC_USERINFO_URI}|" docker.env
  sed -i "s|OIDC_LOGOUT_URI=change_me|OIDC_LOGOUT_URI=${OIDC_LOGOUT_URI}|" docker.env
  sed -i "s|SMTP_HOST=change_me|SMTP_HOST=${SMTP_HOST}|" docker.env
  sed -i "s|SMTP_USERNAME=change_me|SMTP_USERNAME=${SMTP_USERNAME}|" docker.env
  sed -i "s|SMTP_PASSWORD=change_me|SMTP_PASSWORD=${SMTP_PASSWORD}|" docker.env
fi

# 7. Clean up — unset all vars from this shell
unset OUTLINE_SECRET_KEY UTILS_SECRET
unset COGNITO_POOL_ID COGNITO_CLIENT_ID COGNITO_CLIENT_SECRET COGNITO_DOMAIN_PREFIX
unset OIDC_AUTH_URI OIDC_TOKEN_URI OIDC_USERINFO_URI OIDC_LOGOUT_URI
unset SMTP_HOST SMTP_USERNAME SMTP_PASSWORD
unset SECRET_JSON

echo ""
echo "=== Done ==="
echo "docker.env written with secrets."
echo "Secrets stored in AWS SM as startline/docs."
echo "Run 'docker compose up' to start Outline."
echo ""
echo "Add users via:"
echo "  aws cognito-idp admin-create-user \\"
echo "    --user-pool-id \$COGNITO_POOL_ID \\"
echo "    --username user@example.com \\"
echo "    --temporary-password TempPass123! \\"
echo "    --message-action SUPPRESS"
echo ""
echo "Then share the Outline URL — first login via OIDC auto-provisions the user."
