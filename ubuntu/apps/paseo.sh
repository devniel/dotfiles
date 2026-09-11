#!/usr/bin/env bash
#
# paseo.sh — install/upgrade the Paseo desktop app (https://github.com/getpaseo/paseo).
#
# Paseo ships as an AppImage on GitHub releases. This downloads the latest one
# into ~/Applications under its release asset name (no version in it, so
# re-running upgrades in place) and adds an app menu entry built from the
# AppImage's own .desktop file and icon, so it shows up in the rofi launcher.
#
#   ./ubuntu/apps/paseo.sh            # on its own
#   ./ubuntu/apps/install.sh paseo    # via the installer
#
set -euo pipefail

REPO="getpaseo/paseo"
ASSET="x86_64.AppImage"  # substring of the release asset name
NAME="paseo"             # menu entry / icon file name

DIR="$HOME/Applications"
ICONS="$HOME/.local/share/icons"
MENU="$HOME/.local/share/applications"

# AppImages need FUSE 2 to run (libfuse2t64 on 24.04, libfuse2 before that).
ensure_fuse2() {
  ldconfig -p | grep 'libfuse\.so\.2 ' >/dev/null \
    || sudo apt-get install -y libfuse2t64 || sudo apt-get install -y libfuse2
}

# Latest release AppImage -> $DIR. Sets APPIMAGE to the installed path (not
# echoed back via $(...), where bash turns set -e off and a failed download
# would carry on).
download() {
  echo ":: paseo — resolving latest AppImage from $REPO (match: $ASSET)"
  local url
  url=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
        | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 \
        | grep -F "$ASSET" | head -1) || true
  [ -z "$url" ] && { echo "!! paseo — no asset matching '$ASSET'" >&2; return 1; }
  APPIMAGE="$DIR/$(basename "$url")"
  mkdir -p "$DIR"
  echo ":: paseo — downloading $(basename "$url")"
  curl -fsSL -o "$APPIMAGE.part" "$url"
  chmod +x "$APPIMAGE.part"
  mv "$APPIMAGE.part" "$APPIMAGE"
}

# $MENU/$NAME.desktop from the AppImage's own .desktop file and icon, with Exec
# pointed at the AppImage (keeping its flags, e.g. Electron's --no-sandbox).
menu_entry() {
  local file="$1" tmp; tmp="$(mktemp -d)"
  local root="$tmp/squashfs-root"
  ( cd "$tmp" && "$file" --appimage-extract '*.desktop' >/dev/null && "$file" --appimage-extract .DirIcon >/dev/null )
  # .DirIcon is usually a symlink into usr/share/icons; extract its target too.
  local icon_src icon
  if [ -L "$root/.DirIcon" ]; then
    icon_src=$(readlink "$root/.DirIcon")
    ( cd "$tmp" && "$file" --appimage-extract "$icon_src" >/dev/null )
    icon="$ICONS/$NAME.${icon_src##*.}"
    icon_src="$root/$icon_src"
  else
    icon_src="$root/.DirIcon"
    icon="$ICONS/$NAME.png"
  fi
  local desktops=("$root"/*.desktop)
  mkdir -p "$ICONS" "$MENU"
  cp "$icon_src" "$icon"
  sed -E -e "s|^Exec=[^ ]+|Exec=$file|" -e "s|^Icon=.*|Icon=$icon|" -e '/^TryExec=/d' \
    "${desktops[0]}" > "$MENU/$NAME.desktop"
  # Registers the paseo:// link handler from the entry's MimeType.
  if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database "$MENU"; fi
  rm -rf "$tmp"
  echo ":: paseo — menu entry $MENU/$NAME.desktop"
}

ensure_fuse2
download
menu_entry "$APPIMAGE"
