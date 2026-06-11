#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="AceStreamPlayer"
APP_BUNDLE="${APP_NAME}.app"

echo "Building release binary..."
swift build -c release

echo "Assembling ${APP_BUNDLE}..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
cp ".build/release/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

echo "Done. Run with: open ${APP_BUNDLE}"
echo "Or move it to /Applications: mv ${APP_BUNDLE} /Applications/"
