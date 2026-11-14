#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="Sea-Star"
BUNDLE_ID="UpPeriscope.Sea-Star"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MACAPP_DIR="$ROOT_DIR/macapp"
DERIVED_DIR="$MACAPP_DIR/build"
APP_BUNDLE="$DERIVED_DIR/Build/Products/Debug/$APP_NAME.app"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

cd "$MACAPP_DIR"
xcodegen generate
xcodebuild -project SeaStar.xcodeproj -scheme SeaStar -config Debug \
  -derivedDataPath "$DERIVED_DIR" build

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 1
    if pgrep -x "$APP_NAME" >/dev/null; then
      echo "OK: $APP_NAME is running from $APP_BUNDLE"
    else
      echo "FAIL: $APP_NAME did not stay running" >&2
      exit 1
    fi
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
