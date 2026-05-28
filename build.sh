#!/usr/bin/env bash
# Compiles the Swift sources into a proper .app bundle under ./build/.
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="MeetingAirplane"
APP_DIR="build/${APP_NAME}.app"
EXEC_DIR="${APP_DIR}/Contents/MacOS"
RES_DIR="${APP_DIR}/Contents/Resources"

# Sanity check: we need swiftc.
if ! command -v swiftc >/dev/null 2>&1; then
    echo "✗ swiftc not found." >&2
    echo "  Install Xcode Command Line Tools first:" >&2
    echo "    xcode-select --install" >&2
    exit 1
fi

# Fresh build dir.
rm -rf build
mkdir -p "$EXEC_DIR" "$RES_DIR"

# Compile.
swiftc -O \
    -framework AppKit \
    -framework EventKit \
    -framework QuartzCore \
    -o "${EXEC_DIR}/${APP_NAME}" \
    Sources/*.swift

# Install the Info.plist that tells macOS this is a real app bundle with
# calendar usage permission.
cp Info.plist "${APP_DIR}/Contents/Info.plist"

# Ad-hoc codesign. Required on Apple Silicon for TCC (calendar permission)
# to grant reliably to a launchd-launched binary.
codesign --force --deep --sign - "${APP_DIR}" >/dev/null 2>&1 || true

echo "✓ Built ${APP_DIR}"
