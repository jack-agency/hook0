#!/usr/bin/env sh
set -eu

# Entrypoint for frontend container: write runtime config and start Caddy

if [ -z "${API_ENDPOINT-}" ]; then
  echo "ERROR: API_ENDPOINT environment variable is not set. Refusing to start." >&2
  exit 1
fi

cat > /usr/share/caddy/config.json <<EOF
{"API_ENDPOINT":"${API_ENDPOINT}"}
EOF

echo "Wrote /usr/share/caddy/config.json: $(cat /usr/share/caddy/config.json)"

# Exec Caddy (default command in image would have been used otherwise)
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
