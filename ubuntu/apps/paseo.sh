#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR
#
# paseo.sh — install/upgrade the Paseo desktop app (https://github.com/getpaseo/paseo),
# an Electron app shipped as an AppImage on GitHub releases. lib/appimage.sh
# does the work: latest AppImage -> ~/Applications, plus an app menu entry.
#
#   ./ubuntu/apps/paseo.sh            # on its own
#   ./ubuntu/apps/install.sh paseo    # via the installer
#
set -euo pipefail
# shellcheck source=lib/appimage.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib/appimage.sh"

appimage_install getpaseo/paseo x86_64.AppImage paseo
