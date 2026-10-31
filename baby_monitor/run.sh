#!/bin/sh
set -eu

umask 077

: "${BABY_MONITOR_DATA_DIR:=/data}"
: "${BABY_MONITOR_FRONTEND_DIR:=/app/frontend-dist}"
: "${BABY_MONITOR_HOST:=0.0.0.0}"
: "${BABY_MONITOR_PORT:=8099}"

export BABY_MONITOR_DATA_DIR
export BABY_MONITOR_FRONTEND_DIR

resolved_data_dir=
checked_dirs=
for candidate in "${BABY_MONITOR_DATA_DIR}" /data /config/baby-monitor-data /addon_configs/baby_monitor /tmp/baby-monitor-data; do
  [ -n "${candidate}" ] || continue
  case " ${checked_dirs} " in
    *" ${candidate} "*) continue ;;
  esac
  checked_dirs="${checked_dirs} ${candidate}"
  if mkdir -p "${candidate}" 2>/dev/null \
    && touch "${candidate}/.baby-monitor-write-test" 2>/dev/null; then
    rm -f "${candidate}/.baby-monitor-write-test"
    resolved_data_dir="${candidate}"
    break
  fi
done

if [ -z "${resolved_data_dir}" ]; then
  echo "ERROR: No writable data directory found. Tried:${checked_dirs}" >&2
  exit 1
fi

if [ "${resolved_data_dir}" != "${BABY_MONITOR_DATA_DIR}" ]; then
  echo "WARNING: BABY_MONITOR_DATA_DIR '${BABY_MONITOR_DATA_DIR}' is not writable. Falling back to '${resolved_data_dir}'." >&2
fi

if [ "${resolved_data_dir}" = "/tmp/baby-monitor-data" ]; then
  echo "WARNING: Using temporary storage at '${resolved_data_dir}' (settings may be lost after restart)." >&2
fi

BABY_MONITOR_DATA_DIR="${resolved_data_dir}"
export BABY_MONITOR_DATA_DIR

exec python -m uvicorn baby_monitor.main:app \
  --host "${BABY_MONITOR_HOST}" \
  --port "${BABY_MONITOR_PORT}" \
  --workers 1 \
  --no-proxy-headers \
  --no-server-header
