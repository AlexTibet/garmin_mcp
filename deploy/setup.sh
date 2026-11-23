#!/usr/bin/env bash
# Создаёт .env с адресом sslip.io и случайными секретами.
set -euo pipefail
if [ -f .env ]; then echo ".env уже есть, не трогаю"; else
  IP=$(curl -4 -s https://ifconfig.me)
  DOMAIN="$(echo "$IP" | tr . -).sslip.io"
  SECRET_PATH=$(openssl rand -hex 24)
  MCP_TOKEN=$(openssl rand -hex 32)
  printf 'DOMAIN=%s\nSECRET_PATH=%s\nMCP_TOKEN=%s\n' "$DOMAIN" "$SECRET_PATH" "$MCP_TOKEN" > .env
  chmod 600 .env
fi
. ./.env
echo
echo "Адрес для коннектора Claude:"
echo "  https://${DOMAIN}/${SECRET_PATH}/mcp"
echo "Никому его не показывайте — это ключ к вашим данным."
