#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
#
# github-copilot.sh — install/upgrade the GitHub Copilot desktop app, a Tauri
# app shipped as an AppImage on GitHub releases (github/app;
# https://gh.io/copilot-app-linux redirects to the same latest asset).
# lib/appimage.sh does the work: latest AppImage -> ~/Applications, plus an app
# menu entry.
#
#   ./ubuntu/apps/github-copilot.sh            # on its own
#   ./ubuntu/apps/install.sh github-copilot    # via the installer
#
set -euo pipefail
# shellcheck source=lib/appimage.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/appimage.sh"

appimage_install github/app linux-x64.AppImage github-copilot
