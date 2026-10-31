#!/bin/sh
set -eu

umask 077

: "${BABY_MONITOR_DATA_DIR:=/data}"
: "${BABY_MONITOR_FRONTEND_DIR:=/app/frontend-dist}"
: "${BABY_MONITOR_HOST:=0.0.0.0}"
: "${BABY_MONITOR_PORT:=8099}"

export BABY_MONITOR_DATA_DIR
export BABY_MONITOR_FRONTEND_DIR

if ! mkdir -p "${BABY_MONITOR_DATA_DIR}" 2>/dev/null || [ ! -w "${BABY_MONITOR_DATA_DIR}" ]; then
  fallback_data_dir=/config/baby-monitor-data
  if [ "${BABY_MONITOR_DATA_DIR}" != "${fallback_data_dir}" ] \
    && mkdir -p "${fallback_data_dir}" 2>/dev/null \
    && [ -w "${fallback_data_dir}" ]; then
    echo "WARNING: BABY_MONITOR_DATA_DIR '${BABY_MONITOR_DATA_DIR}' is not writable. Falling back to '${fallback_data_dir}'." >&2
    BABY_MONITOR_DATA_DIR="${fallback_data_dir}"
    export BABY_MONITOR_DATA_DIR
  else
    fallback_data_dir=/tmp/baby-monitor-data
    if mkdir -p "${fallback_data_dir}" 2>/dev/null && [ -w "${fallback_data_dir}" ]; then
      echo "WARNING: No persistent data directory is writable. Falling back to '${fallback_data_dir}' (settings may be lost after restart)." >&2
      BABY_MONITOR_DATA_DIR="${fallback_data_dir}"
      export BABY_MONITOR_DATA_DIR
    else
      echo "ERROR: Neither '${BABY_MONITOR_DATA_DIR}', '/config/baby-monitor-data', nor '/tmp/baby-monitor-data' is writable." >&2
      exit 1
    fi
  fi
fi

exec python -m uvicorn baby_monitor.main:app \
  --host "${BABY_MONITOR_HOST}" \
  --port "${BABY_MONITOR_PORT}" \
  --workers 1 \
  --no-proxy-headers \
  --no-server-header
