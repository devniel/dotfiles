#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
#
# openpets.sh — install/upgrade OpenPets (https://github.com/OpenPetsHQ/openpets),
# a local-first animated desktop pet with plugin/agent integrations (Claude
# Code, OpenCode, Cursor, Pi, MCP clients), shipped as an Electron AppImage on
# GitHub releases. lib/appimage.sh does the work: latest AppImage ->
# ~/Applications, plus an app menu entry.
#
#   ./ubuntu/apps/openpets.sh            # on its own
#   ./ubuntu/apps/install.sh openpets    # via the installer
#
set -euo pipefail
# shellcheck source=lib/appimage.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/appimage.sh"

appimage_install OpenPetsHQ/openpets linux-x86_64.AppImage openpets
