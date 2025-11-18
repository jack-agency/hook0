ARG NODE_VERSION=24
ARG CADDY_VERSION=2.10

FROM node:${NODE_VERSION} AS build
WORKDIR /app
COPY frontend/ ./
RUN --mount=type=bind,source=mediakit,target=/mediakit \
    rm -rf -- dist/ && npm ci && npm run build

FROM caddy:${CADDY_VERSION}
RUN sed -i '/file_server/i try_files {path} /index.html' /etc/caddy/Caddyfile
RUN apk --no-cache add curl gettext
COPY --from=build /app/dist /usr/share/caddy/

# Create entrypoint script that injects runtime config
RUN cat > /entrypoint.sh <<'SH'
#!/bin/sh
# Write runtime config using the API_ENDPOINT environment variable (expanded at container start)
cat > /usr/share/caddy/config.json <<EOL
{"apiEndpoint": "${API_ENDPOINT}"}
EOL
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
SH

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
EXPOSE 80
