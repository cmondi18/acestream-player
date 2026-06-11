# Ace Stream Player

A minimal macOS app for playing `acestream://` links.

## How it works

Ace Stream doesn't have a native macOS engine, so this app runs the
[Ace Stream Engine](https://wiki.acestream.media/) inside a small Docker
container ([`martinbjeldbak/acestream-http-proxy`](https://github.com/martinbjeldbak/acestream-http-proxy)),
which exposes an HTTP API on `127.0.0.1:6878`. The app:

1. Checks that Docker Desktop is running.
2. Starts (or resumes) the `acestream-engine` container if it isn't running.
3. Waits for the engine's HTTP port to come online.
4. When you paste an `acestream://<id>` link (or bare content ID) and hit
   **Play**, it builds `http://127.0.0.1:6878/ace/manifest.m3u8?id=<id>` and
   plays that HLS stream with AVPlayer.

On quit, the app stops the Docker container.

## Requirements

- macOS 14+
- [Docker Desktop](https://www.docker.com/products/docker-desktop/), running
  - On Apple Silicon, the engine image is amd64-only and runs under
    emulation — make sure **Settings > General > "Use Rosetta for
    x86/amd64 emulation on Apple Silicon"** is enabled in Docker Desktop.
- Xcode Command Line Tools / Swift 6 toolchain (for building)
- [Homebrew](https://brew.sh/) (used by the setup script to install Docker
  Desktop if it's missing)

## Setup

```bash
./Scripts/setup.sh
```

This checks for/installs the Swift toolchain, Homebrew, and Docker Desktop,
pre-pulls the Ace Stream engine image, and builds `AceStreamPlayer.app`. If
it installs Xcode Command Line Tools or Docker Desktop for the first time,
re-run it afterwards to finish.

## Build & run

```bash
# Run during development (window opens directly)
swift run

# Or build a double-clickable .app bundle
./Scripts/build-app.sh
open AceStreamPlayer.app
```

The first launch downloads the engine image (if `setup.sh` didn't already)
and can take a few minutes — the app shows a status message while this
happens. Subsequent launches are fast since the container is reused.

## Usage

Paste an `acestream://<40-char-hex-id>` link (or just the bare hex ID) into
the field at the bottom and press **Play** / Return. Playback uses a bare
`AVPlayerLayer` (no transport controls) — use the field/Play button again to
switch streams.

## Notes

- Only stream content you have the rights to access — Ace Stream is a
  peer-to-peer protocol and this app is a content-neutral player; it doesn't
  ship with or suggest any channels/links.
- If playback fails to start, check `docker logs acestream-engine` — some
  streams take 10-30 seconds to gather enough peers before the HLS manifest
  becomes available.
