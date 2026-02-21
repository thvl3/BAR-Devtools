#!/bin/bash
set -e

_term() {
  echo "Caught termination signal"
  kill -TERM "$child" 2>/dev/null
  wait "$child"
}
trap _term SIGTERM SIGINT

cp -R /spads_etc/* /opt/spads/etc/ 2>/dev/null || true
cp -R /spads_var/* /opt/spads/var/ 2>/dev/null || true

# Use the dev config instead of production config
cp /spads_dev.conf /opt/spads/etc/spads_dev.conf

mkdir -p /opt/spads/var/log
mkdir -p /opt/spads/var/plugins
mkdir -p /opt/spads/var/spring
mkdir -p /opt/spads/var/spads_dev/log

pidfiles=$(find /opt/spads/var -name "*.pid" -type f 2>/dev/null)
if [ -n "$pidfiles" ]; then
  echo "Cleaning stale pid files"
  echo "$pidfiles" | xargs rm -f
fi

if [ ! -d "${SPRING_DATADIR}/games" ] || [ -z "$(ls -A ${SPRING_DATADIR}/games/ 2>/dev/null)" ]; then
  echo "Downloading BAR game data (first run only)..."
  /spring-engines/latest/pr-downloader \
    --filesystem-writepath "${SPRING_DATADIR}" \
    --download-game byar:test 2>&1 || echo "WARNING: Game download failed. SPADS may not start properly."
fi

echo "Starting SPADS with dev config, connecting to ${SPADS_LOBBY_HOST:-127.0.0.1}:8200..."

perl /opt/spads/spads.pl /opt/spads/etc/spads_dev.conf \
  ${SPADS_ARGS} &

child=$!
echo "SPADS PID: $child"
wait "$child"
