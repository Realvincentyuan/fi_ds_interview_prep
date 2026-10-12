#!/usr/bin/env bash
set -e

# Change to script directory
cd "$(dirname "$0")"

# Detect primary local IP address for iPad access
IP_ADDR=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "127.0.0.1")

echo "========================================================"
echo " Starting Local Docs Preview (with Private Career Hub) "
echo "========================================================"
echo " Local Machine : http://localhost:8000"
echo " iPad / Network: http://${IP_ADDR}:8000"
echo "========================================================"
echo ""

exec .venv/bin/zensical serve -f zensical.local.toml -a 0.0.0.0:8000
