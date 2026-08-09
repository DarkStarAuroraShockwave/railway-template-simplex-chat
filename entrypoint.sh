#!/usr/bin/env bash
set -Eeuo pipefail

require() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    printf 'Required variable %s is not set.\n' "$name" >&2
    exit 1
  fi
}

for name in \
  RAILWAY_TCP_PROXY_DOMAIN \
  RAILWAY_TCP_PROXY_PORT \
  SIMPLEX_CREATE_PASSWORD
do
  require "$name"
done

case "$RAILWAY_TCP_PROXY_DOMAIN" in
  *[!A-Za-z0-9.-]*|'')
    printf 'RAILWAY_TCP_PROXY_DOMAIN is not a valid TCP proxy hostname.\n' >&2
    exit 1
    ;;
esac

case "$SIMPLEX_CREATE_PASSWORD" in
  *[!A-Za-z0-9_-]*|'')
    printf 'SIMPLEX_CREATE_PASSWORD may contain only letters, numbers, underscore, and hyphen.\n' >&2
    exit 1
    ;;
esac

if (( ${#SIMPLEX_CREATE_PASSWORD} < 16 )); then
  printf 'SIMPLEX_CREATE_PASSWORD must contain at least 16 characters.\n' >&2
  exit 1
fi

http_port="${PORT:-8080}"
application_port="${RAILWAY_TCP_APPLICATION_PORT:-5223}"
external_port="$RAILWAY_TCP_PROXY_PORT"

for port in "$http_port" "$application_port" "$external_port"; do
  if [[ ! "$port" =~ ^[0-9]+$ ]] || (( port < 1 || port > 65535 )); then
    printf 'Invalid port: %s\n' "$port" >&2
    exit 1
  fi
done

if [[ "$application_port" == "$external_port" ]]; then
  printf 'The Railway TCP application and proxy ports must be different.\n' >&2
  exit 1
fi

config_dir=/etc/opt/simplex
state_dir="${config_dir}/state"
mkdir -p "$config_dir" /var/opt

config_file="${config_dir}/smp-server.ini"
create_password="$SIMPLEX_CREATE_PASSWORD"

if [[ ! -f "$config_file" ]]; then
  smp-server init \
    --yes \
    --store-log \
    --daily-stats \
    --source-code \
    --fqdn "$RAILWAY_TCP_PROXY_DOMAIN" \
    --password "$create_password" \
    >/dev/null 2>&1
fi

mkdir -p "$state_dir"
rm -rf /var/opt/simplex
ln -s "$state_dir" /var/opt/simplex

sed -i -E \
  -e "s|^host[[:space:]]*=[[:space:]].*|host = ${RAILWAY_TCP_PROXY_DOMAIN}|" \
  -e "s|^port[[:space:]]*=[[:space:]].*|port = ${external_port}|" \
  -e 's|^[^#]*https[[:space:]]*=[[:space:]]|#&|' \
  -e 's|^[^#]*cert[[:space:]]*=[[:space:]]|#&|' \
  -e 's|^[^#]*key[[:space:]]*=[[:space:]]|#&|' \
  "$config_file"

if grep -q '^create_password[[:space:]]*=' "$config_file"; then
  sed -i -E "s|^create_password[[:space:]]*=.*|create_password = ${create_password}|" "$config_file"
else
  sed -i "/^\[AUTH\]/a create_password = ${create_password}" "$config_file"
fi

unset SIMPLEX_CREATE_PASSWORD

DOCKER=true /usr/local/bin/simplex-servers-stopscript smp-server

fingerprint="$(cat "${config_dir}/fingerprint")"
www_dir=/tmp/simplex-www
mkdir -p "${www_dir}/cgi-bin"

cat >"${www_dir}/index.html" <<EOF
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>SimpleX SMP relay</title></head>
<body>
  <main>
    <h1>SimpleX SMP relay is running</h1>
    <p>Public endpoint: <code>${RAILWAY_TCP_PROXY_DOMAIN}:${external_port}</code></p>
    <p>Fingerprint: <code>${fingerprint}</code></p>
    <p>In Railway, copy <code>SIMPLEX_CREATE_PASSWORD</code> and insert it after the fingerprint:</p>
    <pre>smp://${fingerprint}:&lt;SIMPLEX_CREATE_PASSWORD&gt;@${RAILWAY_TCP_PROXY_DOMAIN}:${external_port}</pre>
    <p>The creation password is intentionally never exposed on this public page.</p>
  </main>
</body>
</html>
EOF

cat >"${www_dir}/cgi-bin/healthz" <<'EOF'
#!/bin/sh
if socat -T2 /dev/null "TCP:127.0.0.1:${SIMPLEX_EXTERNAL_PORT}" >/dev/null 2>&1; then
  printf 'Status: 200 OK\r\nContent-Type: text/plain\r\n\r\nready\n'
else
  printf 'Status: 503 Service Unavailable\r\nContent-Type: text/plain\r\n\r\nnot ready\n'
fi
EOF
chmod 755 "${www_dir}/cgi-bin/healthz"
export SIMPLEX_EXTERNAL_PORT="$external_port"

smp-server start +RTS -N -RTS &
server_pid=$!
socat "TCP-LISTEN:${application_port},reuseaddr,fork" "TCP:127.0.0.1:${external_port}" &
proxy_pid=$!
/bin/busybox httpd -f -p "0.0.0.0:${http_port}" -h "$www_dir" &
http_pid=$!

cleanup() {
  trap - INT TERM
  kill -INT "$server_pid" 2>/dev/null || true
  kill -TERM "$proxy_pid" "$http_pid" 2>/dev/null || true
  wait "$server_pid" "$proxy_pid" "$http_pid" 2>/dev/null || true
}

trap 'cleanup; exit 0' INT TERM
set +e
wait -n "$server_pid" "$proxy_pid" "$http_pid"
status=$?
set -e
cleanup
exit "$status"
