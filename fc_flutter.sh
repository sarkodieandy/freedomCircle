#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR/mobile_app"

if [[ ! -f "$APP_DIR/pubspec.yaml" ]]; then
  echo "Flutter project not found at: $APP_DIR" >&2
  exit 1
fi

cd "$APP_DIR"
command flutter "$@"
