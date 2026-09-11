# shellcheck shell=bash
#
# appimage.sh — shared helpers for installing an AppImage from GitHub releases.
# Sourced by the per-app scripts in ubuntu/apps/ (paseo.sh, github-copilot.sh):
#
#   . "$(dirname "${BASH_SOURCE[0]}")/lib/appimage.sh"
#   appimage_install owner/repo asset-substring name
#
# Downloads the latest release's AppImage into ~/Applications under its asset
# name (no version in it, so re-running upgrades in place), makes sure FUSE 2
# is present, and writes ~/.local/share/applications/<name>.desktop from the
# AppImage's own .desktop file and icon, so the app shows up in the rofi
# launcher. Callers are expected to run under `set -euo pipefail`.

APPIMAGE_DIR="$HOME/Applications"
APPIMAGE_ICONS="$HOME/.local/share/icons"
APPIMAGE_MENU="$HOME/.local/share/applications"

appimage_install() {
  local repo="$1" asset="$2" name="$3"
  _appimage_fuse2
  _appimage_download "$repo" "$asset" "$name"
  _appimage_menu_entry "$name" "$APPIMAGE"
}

# AppImages need FUSE 2 to run (libfuse2t64 on 24.04, libfuse2 before that).
_appimage_fuse2() {
  ldconfig -p | grep 'libfuse\.so\.2 ' >/dev/null \
    || sudo apt-get install -y libfuse2t64 || sudo apt-get install -y libfuse2
}

# Latest release AppImage -> $APPIMAGE_DIR. Sets APPIMAGE to the installed path
# (not echoed back via $(...), where bash turns set -e off and a failed
# download would carry on).
_appimage_download() {
  local repo="$1" asset="$2" name="$3" url
  echo ":: $name — resolving latest AppImage from $repo (match: $asset)"
  # Only *.AppImage assets, so updater files like .AppImage.sig don't match.
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 \
        | grep -F "$asset" | grep -E '\.AppImage$' | head -1) || true
  [ -z "$url" ] && { echo "!! $name — no AppImage asset matching '$asset'" >&2; return 1; }
  APPIMAGE="$APPIMAGE_DIR/$(basename "$url")"
  mkdir -p "$APPIMAGE_DIR"
  echo ":: $name — downloading $(basename "$url")"
  curl -fsSL -o "$APPIMAGE.part" "$url"
  chmod +x "$APPIMAGE.part"
  mv "$APPIMAGE.part" "$APPIMAGE"
}

# Extract a path from AppImage $1 into ./squashfs-root, following symlinks
# (.desktop and .DirIcon are often links, sometimes chained, into usr/share);
# prints the real path.
_appimage_extract() {
  local file="$1" p="$2" t d
  "$file" --appimage-extract "$p" >/dev/null
  while [ -L "squashfs-root/$p" ]; do
    t=$(readlink "squashfs-root/$p"); d=$(dirname "$p")
    [ "$d" = . ] && p="$t" || p="$d/$t"
    "$file" --appimage-extract "$p" >/dev/null
  done
  echo "$p"
}

# $APPIMAGE_MENU/<name>.desktop from the AppImage's own .desktop file and icon.
_appimage_menu_entry() {
  local name="$1" file="$2" tmp; tmp="$(mktemp -d)"
  local root="$tmp/squashfs-root" top="" d desktop icon_src ext icon
  ( cd "$tmp" && "$file" --appimage-extract '*.desktop' >/dev/null )
  for d in "$root"/*.desktop; do top="${d##*/}"; break; done
  [ -z "$top" ] && { echo "!! $name — no .desktop file in the AppImage" >&2; rm -rf "$tmp"; return 1; }
  desktop=$(cd "$tmp" && _appimage_extract "$file" "$top")
  icon_src=$(cd "$tmp" && _appimage_extract "$file" .DirIcon)
  case "$icon_src" in *.png|*.svg|*.xpm) ext="${icon_src##*.}" ;; *) ext=png ;; esac
  icon="$APPIMAGE_ICONS/$name.$ext"
  mkdir -p "$APPIMAGE_ICONS" "$APPIMAGE_MENU"
  cp "$root/$icon_src" "$icon"
  # Exec -> the AppImage, keeping its flags (e.g. Electron's --no-sandbox);
  # Icon -> the extracted icon. List values must end in ';' and can't be
  # empty, which not every app's entry gets right.
  sed -E -e "s|^Exec=[^ ]+|Exec=$file|" -e "s|^Icon=.*|Icon=$icon|" -e '/^TryExec=/d' \
    -e '/^Categories=$/d' -e 's/^((MimeType|Categories)=.*[^;])$/\1;/' \
    "$root/$desktop" > "$APPIMAGE_MENU/$name.desktop"
  # Registers the app's link handlers (x-scheme-handler/... in MimeType).
  if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database "$APPIMAGE_MENU"; fi
  rm -rf "$tmp"
  echo ":: $name — menu entry $APPIMAGE_MENU/$name.desktop"
}
