#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PROJECT_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
CONFIG_FILE=${PROJECT_CONFIG_FILE:-${PROJECT_ROOT}/config/project.env}

if [ ! -f "$CONFIG_FILE" ]; then
  echo "[ERROR] Config file not found: $CONFIG_FILE"
  echo "Create it from: ${PROJECT_ROOT}/config/project.env.example"
  exit 1
fi

# shellcheck disable=SC1091
. "$CONFIG_FILE"

require_var() {
  var_name="$1"
  eval "var_value=\${$var_name-}"
  if [ -z "$var_value" ]; then
    echo "[ERROR] Missing required config: $var_name"
    exit 1
  fi
}

for v in PRESEED_FILE_PATH PRESEED_FALLBACK_PATH PRESEED_SERVER_PORT; do
  require_var "$v"
done

resolve_path() {
  p="$1"
  case "$p" in
    /*) echo "$p" ;;
    *) echo "${PROJECT_ROOT}/$p" ;;
  esac
}

PRESEED_PATH=$(resolve_path "$PRESEED_FILE_PATH")
FALLBACK_PATH=$(resolve_path "$PRESEED_FALLBACK_PATH")

if [ ! -f "$PRESEED_PATH" ]; then
  PRESEED_PATH=$FALLBACK_PATH
fi

if [ ! -f "$PRESEED_PATH" ]; then
  echo "[ERROR] No preseed file found."
  echo "Primary: $(resolve_path "$PRESEED_FILE_PATH")"
  echo "Fallback: $FALLBACK_PATH"
  exit 1
fi

if ! command -v busybox >/dev/null 2>&1; then
  echo "[ERROR] busybox is required for scripts/serve_preseed.sh"
  echo "Install busybox and retry."
  exit 1
fi

TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT HUP INT TERM

cp -f "$PRESEED_PATH" "$TMP_DIR/index.html"

echo "[OK] Serving preseed file: $PRESEED_PATH"
echo "[OK] URL: http://127.0.0.1:${PRESEED_SERVER_PORT}/"
echo "[INFO] Press Ctrl+C to stop"

exec busybox httpd -f -p "$PRESEED_SERVER_PORT" -h "$TMP_DIR"
