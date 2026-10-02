#!/usr/bin/env bash
#
# Build, sign, package and notarise Sea-Star for people who are not us.
#
# The whole script exists to make one thing true: nothing reaches a stranger's
# Mac without Gatekeeper having agreed to it. So every step that could quietly
# produce a broken artefact instead stops and says what is missing.
#
#   ./script/release.sh --dry-run     build and package with ad-hoc signing.
#                                     Proves the pipeline without an Apple
#                                     account. The DMG it makes will NOT open
#                                     on another Mac. That is the point.
#
#   ./script/release.sh               the real thing. Needs:
#                                       - a paid Apple Developer Program membership
#                                       - a "Developer ID Application" certificate
#                                         in the login keychain
#                                       - SEASTAR_TEAM_ID set to your Team ID
#                                       - a notarytool keychain profile
#                                         (see docs/ship.md for the one command)
#
# Exits non-zero on the first thing that is wrong, rather than at the end with a
# DMG that looks fine and is not.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Sea-Star"
BUNDLE_ID="UpPeriscope.Sea-Star"
SCHEME="SeaStar"
PROJECT_DIR="${REPO_ROOT}/macapp"
BUILD_DIR="${PROJECT_DIR}/build/release"
DIST_DIR="${REPO_ROOT}/dist"
NOTARY_PROFILE="${SEASTAR_NOTARY_PROFILE:-seastar-notary}"

DRY_RUN=0
for arg in "$@"; do
  case "${arg}" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) sed -n '2,30p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Unknown option: ${arg}" >&2; exit 2 ;;
  esac
done

say()  { printf '\n\033[1m%s\033[0m\n' "$*"; }
fail() { printf '\n\033[31mStopped:\033[0m %s\n\n' "$*" >&2; exit 1; }

# --- 1. What we are building -------------------------------------------------

VERSION="$(sed -n 's/^[[:space:]]*MARKETING_VERSION:[[:space:]]*"\(.*\)"/\1/p' "${PROJECT_DIR}/project.yml" | head -1)"
BUILD="$(sed -n 's/^[[:space:]]*CURRENT_PROJECT_VERSION:[[:space:]]*"\(.*\)"/\1/p' "${PROJECT_DIR}/project.yml" | head -1)"
[ -n "${VERSION}" ] || fail "Could not read MARKETING_VERSION from macapp/project.yml."
DMG_PATH="${DIST_DIR}/${APP_NAME}-${VERSION}.dmg"

say "Sea-Star ${VERSION} (build ${BUILD})"
if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Mode: DRY RUN — ad-hoc signing, no notarisation, not for distribution."
else
  echo "Mode: RELEASE — this artefact is intended for other people's Macs."
fi

# --- 2. The things that must be true before we start -------------------------

command -v xcodegen >/dev/null 2>&1 || fail \
"xcodegen is not installed. Install it with: brew install xcodegen"

if [ "${DRY_RUN}" -eq 0 ]; then
  # A missing certificate is the single most likely reason this script is run.
  # Saying so here, in plain words, is the difference between a five-minute fix
  # and an afternoon of confusion.
  if ! security find-identity -v -p codesigning 2>/dev/null | grep -q "Developer ID Application"; then
    # The private key and the certificate request are already prepared, so this
    # is two clicks on Apple's website rather than a trip through Xcode. The key
    # is in the login keychain and trusted by codesign; when the certificate
    # comes back it pairs with the key automatically.
    fail "No 'Developer ID Application' certificate on this Mac.

  A Developer Program membership is not a certificate — signing needs the
  certificate itself, and it is not here. The request for it is already made:

    1. developer.apple.com > Certificates, Identifiers & Profiles
       > Certificates > + > Developer ID > Developer ID Application
    2. When it asks for a CSR, upload:
         ${HOME}/.seastar/signing/developerID.certSigningRequest
    3. Download the .cer it gives you, then say so — one command finishes it:
         security import <downloaded>.cer -k ~/Library/Keychains/login.keychain-db -T /usr/bin/codesign

  Then set your Team ID (developer.apple.com > Membership) and run this again:
    export SEASTAR_TEAM_ID=XXXXXXXXXX
    ./script/release.sh

  To watch the pipeline work without any of that:
    ./script/release.sh --dry-run"
  fi

  [ -n "${SEASTAR_TEAM_ID:-}" ] || fail \
"SEASTAR_TEAM_ID is not set. Find it at developer.apple.com > Membership
  (it is the 10-character code), then: export SEASTAR_TEAM_ID=XXXXXXXXXX"

  # Notarisation uploads to Apple, so it needs a stored credential. One command
  # sets it up; this only checks that it happened.
  if ! xcrun notarytool history --keychain-profile "${NOTARY_PROFILE}" >/dev/null 2>&1; then
    fail "No notarytool credential stored under the profile '${NOTARY_PROFILE}'.

  Create one with an app-specific password from appleid.apple.com:
    xcrun notarytool store-credentials ${NOTARY_PROFILE} \\
      --apple-id you@example.com --team-id \$SEASTAR_TEAM_ID --password <app-specific-password>

  See docs/ship.md."
  fi
fi

# The engine is not yet inside the bundle. Rather than let that surprise a user
# after they have downloaded and notarised a DMG, say it now, every time.
if [ ! -d "${PROJECT_DIR}/build/Build/Products/Release/${APP_NAME}.app/Contents/Resources/engine" ] \
   && [ ! -d "${PROJECT_DIR}/SeaStar/Resources/engine" ]; then
  say "Note: the Python engine is not bundled inside the app yet."
  echo "The app looks for sea-star on PATH (or the repo at SeaStarRepositoryPath)."
  echo "That is fine for you and not fine for a stranger. See docs/ship.md —"
  echo "bundling the engine is the remaining packaging gap before a DMG is worth"
  echo "handing out."
fi

# --- 3. Build ---------------------------------------------------------------

say "Generating the Xcode project"
(cd "${PROJECT_DIR}" && xcodegen generate --quiet)

say "Building"
SIGN_ARGS=()
if [ "${DRY_RUN}" -eq 1 ]; then
  # Ad-hoc, unsigned, hardened runtime off: a pipeline test, plainly labelled.
  SIGN_ARGS+=(CODE_SIGN_IDENTITY="-" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=YES ENABLE_HARDENED_RUNTIME=NO)
else
  SIGN_ARGS+=(DEVELOPMENT_TEAM="${SEASTAR_TEAM_ID}" CODE_SIGN_IDENTITY="Developer ID Application")
fi

mkdir -p "${BUILD_DIR}"

xcodebuild \
  -project "${PROJECT_DIR}/SeaStar.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration Release \
  -derivedDataPath "${BUILD_DIR}" \
  "${SIGN_ARGS[@]}" \
  build > "${BUILD_DIR}/xcodebuild.log" 2>&1 \
  || fail "The Release build failed. Full log: ${BUILD_DIR}/xcodebuild.log"

APP_PATH="${BUILD_DIR}/Build/Products/Release/${APP_NAME}.app"
[ -d "${APP_PATH}" ] || fail "Built, but no app at ${APP_PATH}."

# --- 4. Check what we built, before wrapping it ------------------------------

say "Verifying the signature"
codesign --verify --deep --strict --verbose=2 "${APP_PATH}" 2>&1 | tail -3

if [ "${DRY_RUN}" -eq 1 ]; then
  echo "Signature: ad-hoc (expected in a dry run)."
else
  SIGNATURE="$(codesign -dv --verbose=4 "${APP_PATH}" 2>&1)"
  echo "${SIGNATURE}" | grep -q "Developer ID Application" \
    || fail "The app is not signed with a Developer ID. Gatekeeper would refuse it."
  echo "${SIGNATURE}" | grep -q "flags=.*runtime" \
    || fail "The hardened runtime is not enabled. Notarisation would reject it."
  echo "Signature: Developer ID with the hardened runtime. Correct."
fi

# --- 5. Package -------------------------------------------------------------

say "Packaging the DMG"
mkdir -p "${DIST_DIR}"
rm -f "${DMG_PATH}"
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
cp -R "${APP_PATH}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"   # drag-to-install, as people expect

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGE}" \
  -ov -format UDZO \
  "${DMG_PATH}" > /dev/null

if [ "${DRY_RUN}" -eq 0 ]; then
  # The DMG carries its own signature: Gatekeeper checks the thing that was
  # actually downloaded, not only what is inside it.
  codesign --sign "Developer ID Application" --timestamp "${DMG_PATH}"
fi

say "Built ${DMG_PATH}"
du -h "${DMG_PATH}" | awk '{print "Size: " $1}'

# --- 6. Notarise ------------------------------------------------------------

if [ "${DRY_RUN}" -eq 1 ]; then
  say "Dry run complete — stopped before notarisation"
  echo "This DMG is unsigned and will be refused by Gatekeeper on any other Mac."
  echo "Run without --dry-run once your Developer ID certificate exists."
  exit 0
fi

say "Submitting to Apple for notarisation (this usually takes a few minutes)"
xcrun notarytool submit "${DMG_PATH}" \
  --keychain-profile "${NOTARY_PROFILE}" \
  --wait \
  || fail "Notarisation was rejected. The log above names the reason; the full
  record is at: xcrun notarytool log <submission-id> --keychain-profile ${NOTARY_PROFILE}"

say "Stapling the ticket to the DMG"
xcrun stapler staple "${DMG_PATH}" \
  || fail "Notarisation succeeded but stapling failed. The DMG would need an
  internet connection on first open."

# --- 7. Prove it, rather than assuming it -----------------------------------

say "Checking Gatekeeper's own verdict"
if spctl --assess --type open --context context:primary-signature -vv "${DMG_PATH}" 2>&1; then
  say "Done — ${DMG_PATH} is signed, notarised and stapled."
  echo "Next: attach it to a GitHub release. See docs/ship.md."
else
  fail "Gatekeeper still refuses the DMG. Everything claimed success, so this
  is a real problem worth investigating before anyone downloads it."
fi
