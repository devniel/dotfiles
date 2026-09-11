#!/usr/bin/env bash
#
# install.sh — install apps that don't come from the stock Ubuntu repos.
#
# These aren't config files, so update.sh (which snapshots $HOME -> repo)
# doesn't cover them. This script is the record of *which* apps a fresh
# machine needs and how each is installed. It's idempotent: re-running
# upgrades to whatever's current.
#
#   ./ubuntu/apps/install.sh                 # install/upgrade everything
#   ./ubuntu/apps/install.sh yazi ghostty    # only the named apps
#
# Each app maps to "method:spec":
#   deb:owner/repo:asset-substring   latest GitHub .deb release ({UBUNTU} -> 24.04)
#   debfile:URL                      direct .deb download (may redirect)
#   script:URL                       vendor curl|sh installer (self-sudos)
#   script-sudo:URL                  vendor curl|sudo bash installer
#   flatpak:app.id                   Flathub app
#   appimage:owner/repo:asset-substring
#                                    latest GitHub AppImage -> ~/Applications + app menu entry
#   custom:function                  bespoke installer defined below
#
set -euo pipefail

. /etc/os-release  # provides $VERSION_ID (24.04) and $VERSION_CODENAME (noble)

declare -A APPS=(
  # terminal / CLI
  [ghostty]="deb:mkasberg/ghostty-ubuntu:amd64_{UBUNTU}.deb"
  [yazi]="deb:sxyazi/yazi:x86_64-unknown-linux-gnu.deb"
  [glow]="deb:charmbracelet/glow:amd64.deb"
  # networking / KVM
  [tailscale]="script:https://tailscale.com/install.sh"
  [deskflow]="flatpak:org.deskflow.deskflow"
  [trayscale]="flatpak:dev.deedles.Trayscale"
  [input-leap]="flatpak:io.github.input_leap.input-leap"
  # dev / desktop
  [docker]="script:https://get.docker.com"
  [azure-cli]="script-sudo:https://aka.ms/InstallAzureCLIDeb"
  [terraform]="custom:install_terraform"
  [vscode]="debfile:https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
  [google-chrome]="debfile:https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"
  [paseo]="appimage:getpaseo/paseo:x86_64.AppImage"
)

# dpkg may fail on missing deps; apt -f resolves them (yazi pulls fd/rg/fzf/...).
dpkg_install() { sudo dpkg -i "$1" || sudo apt-get install -f -y; }

# Download URL of the first asset in a repo's latest GitHub release whose name
# contains the given substring.
latest_asset_url() {
  curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 \
    | grep -F "$2" | head -1
}

install_deb() {
  local name="$1" repo="$2" match="${3//\{UBUNTU\}/$VERSION_ID}"
  echo ":: $name — resolving latest .deb from $repo (match: $match)"
  local url
  url=$(latest_asset_url "$repo" "$match")
  [ -z "$url" ] && { echo "!! $name — no asset matching '$match'; skipping" >&2; return 1; }
  local tmp; tmp="$(mktemp -d)"
  echo ":: $name — downloading $(basename "$url")"
  curl -fsSL -o "$tmp/pkg.deb" "$url"; dpkg_install "$tmp/pkg.deb"; rm -rf "$tmp"
}

install_debfile() {
  local name="$1" url="$2" tmp; tmp="$(mktemp -d)"
  echo ":: $name — downloading direct .deb"
  curl -fsSL -o "$tmp/pkg.deb" "$url"; dpkg_install "$tmp/pkg.deb"; rm -rf "$tmp"
}

install_script()      { echo ":: $1 — running $2"; curl -fsSL "$2" | sh; }
install_script_sudo() { echo ":: $1 — running $2 (sudo)"; curl -fsSL "$2" | sudo bash; }

install_flatpak() {
  local name="$1" appid="$2"
  command -v flatpak >/dev/null 2>&1 || { echo ":: installing flatpak"; sudo apt-get install -y flatpak; }
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  echo ":: $name — flatpak install $appid"
  flatpak install -y --noninteractive flathub "$appid"
}

# Latest GitHub AppImage into ~/Applications under its release asset name
# (versionless, so re-running upgrades in place), plus an app menu entry.
install_appimage() {
  local name="$1" repo="$2" match="$3"
  echo ":: $name — resolving latest AppImage from $repo (match: $match)"
  local url
  url=$(latest_asset_url "$repo" "$match")
  [ -z "$url" ] && { echo "!! $name — no asset matching '$match'; skipping" >&2; return 1; }
  # AppImages need FUSE 2 to run (libfuse2t64 on 24.04, libfuse2 before that).
  ldconfig -p | grep 'libfuse\.so\.2 ' >/dev/null \
    || sudo apt-get install -y libfuse2t64 || sudo apt-get install -y libfuse2
  local dir="$HOME/Applications" file
  file="$dir/$(basename "$url")"
  mkdir -p "$dir"
  echo ":: $name — downloading $(basename "$url")"
  curl -fsSL -o "$file.part" "$url"; chmod +x "$file.part"; mv "$file.part" "$file"
  appimage_menu_entry "$name" "$file"
}

# Build ~/.local/share/applications/<name>.desktop from the AppImage's own
# .desktop file and icon, with Exec pointed at the AppImage (keeping its flags,
# e.g. Electron's --no-sandbox) so it shows up in rofi/app menus.
appimage_menu_entry() {
  local name="$1" file="$2" tmp; tmp="$(mktemp -d)"
  local root="$tmp/squashfs-root" icons="$HOME/.local/share/icons" apps="$HOME/.local/share/applications"
  ( cd "$tmp" && "$file" --appimage-extract '*.desktop' >/dev/null && "$file" --appimage-extract .DirIcon >/dev/null )
  # .DirIcon is usually a symlink into usr/share/icons; extract its target too.
  local icon_src icon
  if [ -L "$root/.DirIcon" ]; then
    icon_src=$(readlink "$root/.DirIcon")
    ( cd "$tmp" && "$file" --appimage-extract "$icon_src" >/dev/null )
    icon="$icons/$name.${icon_src##*.}"
    icon_src="$root/$icon_src"
  else
    icon_src="$root/.DirIcon"
    icon="$icons/$name.png"
  fi
  local desktops=("$root"/*.desktop)
  mkdir -p "$icons" "$apps"
  cp "$icon_src" "$icon"
  sed -E -e "s|^Exec=[^ ]+|Exec=$file|" -e "s|^Icon=.*|Icon=$icon|" -e '/^TryExec=/d' \
    "${desktops[0]}" > "$apps/$name.desktop"
  if command -v update-desktop-database >/dev/null 2>&1; then update-desktop-database "$apps"; fi
  rm -rf "$tmp"
  echo ":: $name — menu entry $apps/$name.desktop"
}

# HashiCorp apt repo (terraform, and any other hashicorp tool).
install_terraform() {
  echo ":: terraform — configuring HashiCorp apt repo"
  curl -fsSL https://apt.releases.hashicorp.com/gpg \
    | sudo gpg --dearmor --yes -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSION_CODENAME main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  sudo apt-get update && sudo apt-get install -y terraform
}

install_app() {
  # spec must be its own `local`: words in one `local` are all expanded before
  # any is assigned, so method/rest would read an unset spec (fatal under set -u).
  local name="$1" spec="${APPS[$1]}"
  local method="${spec%%:*}" rest="${spec#*:}"
  case "$method" in
    deb)         install_deb         "$name" "${rest%%:*}" "${rest#*:}" ;;
    debfile)     install_debfile     "$name" "$rest" ;;
    script)      install_script      "$name" "$rest" ;;
    script-sudo) install_script_sudo "$name" "$rest" ;;
    flatpak)     install_flatpak     "$name" "$rest" ;;
    appimage)    install_appimage    "$name" "${rest%%:*}" "${rest#*:}" ;;
    custom)      "$rest" ;;
    *)           echo "!! $name — unknown method '$method'" >&2; return 1 ;;
  esac
}

# Ubuntu ships the `fd` binary as `fdfind`; yazi looks for `fd`. Bridge it.
link_fd() {
  if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    echo ":: linked ~/.local/bin/fd -> $(command -v fdfind)"
  fi
}

main() {
  local targets=("$@")
  [ ${#targets[@]} -eq 0 ] && targets=("${!APPS[@]}")
  for name in "${targets[@]}"; do
    [ -z "${APPS[$name]:-}" ] && { echo "!! unknown app: $name (known: ${!APPS[*]})" >&2; continue; }
    install_app "$name"
  done
  link_fd
  echo ":: done"
}

main "$@"
