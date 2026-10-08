#!/usr/bin/env bash
# Capture a Sea-Star reading as a PNG, opening the cockpit if it is closed.
#
# Why this exists: an agent can build a reading and never *see* it. The founder hit
# exactly this -- "I would take a screenshot of but I can't click back to that from
# this window either" -- and asked whether screen grabs were possible. They are.
#
# Opening the cockpit is the only hard part, and it is done by clicking the status
# item through AppleScript. Two alternatives were tried and rejected on evidence:
#
#   - A distributed notification the app listens for. It built, launched and never
#     fired: `notifyutil -p` left `SeaStar.cockpitOpen` at 1 while the AppleScript
#     click took it to 0. The hook was removed rather than shipped, because a door
#     that silently does not open is the exact failure this project exists to avoid.
#   - A URL scheme. Permanent public surface, wanting a real design decision, for
#     something only a development script needs.
#
# This host now has assistive access granted to the terminal; earlier in the project
# it did not, and `osascript` returned -1719 for anything touching the UI.
#
# Usage:
#   script/shot.sh flat   [name]   the flat 2D pool
#   script/shot.sh deep   [name]   the 3D room
#   script/shot.sh list   [name]   the four rows
#
# Output lands in $TMPDIR/sea-star-shots/ unless SEA_STAR_SHOT_DIR says otherwise.
# Nothing is written into the repository: a screenshot of someone's desktop is not
# a build artefact.

set -euo pipefail

READING="${1:?usage: shot.sh <flat|deep|list> [name]}"
NAME="${2:-$READING}"
DOMAIN="UpPeriscope.Sea-Star"
OUT="${SEA_STAR_SHOT_DIR:-${TMPDIR:-/tmp}/sea-star-shots}"

# Graph or list, and how deep. The mode is a *choice* (first run asks), the depth
# is only a graph control, so list has no depth to set.
case "$READING" in
  flat|deep)
    defaults write "$DOMAIN" SeaStar.cockpitMode -string graph
    defaults write "$DOMAIN" SeaStar.graphDepth -string "$READING"
    ;;
  list)
    defaults write "$DOMAIN" SeaStar.cockpitMode -string list
    ;;
  *)
    echo "unknown reading: $READING (want flat, deep or list)" >&2
    exit 2
    ;;
esac

if ! pgrep -x "Sea-Star" >/dev/null 2>&1; then
  echo "Sea-Star is not running. Start it with ./script/build_and_run.sh run" >&2
  exit 1
fi

mkdir -p "$OUT"

# Open it if closed. `SeaStar.cockpitOpen` is written by the popover's own
# show/close delegate, so it is the honest signal rather than a guess.
open_cockpit() {
  osascript -e 'tell application "System Events" to tell process "Sea-Star" to click menu bar item 1 of menu bar 1' >/dev/null 2>&1 || true
}

if [ "$(defaults read "$DOMAIN" SeaStar.cockpitOpen 2>/dev/null || echo 0)" != "1" ]; then
  open_cockpit
fi

# The cockpit re-reads the machine every 2s and the popover takes a moment to
# settle after opening, so a fixed wait is honest here — there is nothing to
# observe, because the thing being waited for is the founder's own screen.
sleep 4

TARGET="$OUT/$NAME.png"
# -C keeps the cursor: without it the picture reads as though the machine were
# unattended, and -x drops the click sound.
screencapture -x -o -C "$TARGET"
echo "$TARGET"