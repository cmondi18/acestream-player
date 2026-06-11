#!/bin/bash
# One-time setup: installs/checks all dependencies needed to build and run
# AceStreamPlayer, then builds the .app bundle.
set -euo pipefail

cd "$(dirname "$0")/.."

# 1. Xcode Command Line Tools (provides the Swift toolchain)
if ! command -v swift &>/dev/null; then
    echo "Swift toolchain not found. Installing Xcode Command Line Tools..."
    xcode-select --install
    echo "Finish the Xcode Command Line Tools install in the dialog that just opened,"
    echo "then re-run this script."
    exit 1
fi
echo "Swift toolchain: OK ($(swift --version | head -1))"

# 2. Homebrew (used to install Docker Desktop)
if ! command -v brew &>/dev/null; then
    echo "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
echo "Homebrew: OK"

# 3. Docker Desktop
if ! command -v docker &>/dev/null; then
    echo "Docker not found. Installing Docker Desktop..."
    brew install --cask docker
    echo "Launching Docker Desktop for first-time setup..."
    open -a Docker
    echo "Complete the Docker Desktop setup, then re-run this script."
    exit 1
fi
echo "Docker CLI: OK"

# 4. Docker daemon running
if ! docker info &>/dev/null; then
    echo "Starting Docker Desktop..."
    open -a Docker
    echo -n "Waiting for Docker daemon to come online"
    until docker info &>/dev/null; do
        echo -n "."
        sleep 2
    done
    echo
fi
echo "Docker daemon: OK"

# 5. Pre-pull the Ace Stream engine image (amd64 only; runs via emulation on
#    Apple Silicon — make sure "Use Rosetta for x86/amd64 emulation" is
#    enabled in Docker Desktop > Settings > General).
echo "Pulling Ace Stream engine image (this can take a few minutes)..."
docker pull --platform linux/amd64 ghcr.io/martinbjeldbak/acestream-http-proxy

# 6. Build the app
echo "Building AceStreamPlayer.app..."
./Scripts/build-app.sh

echo
echo "Setup complete. Launch with:"
echo "  open AceStreamPlayer.app"
