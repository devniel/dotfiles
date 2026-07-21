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
)

# dpkg may fail on missing deps; apt -f resolves them (yazi pulls fd/rg/fzf/...).
dpkg_install() { sudo dpkg -i "$1" || sudo apt-get install -f -y; }

install_deb() {
  local name="$1" repo="$2" match="${3//\{UBUNTU\}/$VERSION_ID}"
  echo ":: $name — resolving latest .deb from $repo (match: $match)"
  local url
  url=$(curl -fsSL "https://api.github.com/repos/$repo/releases/latest" \
        | grep -oE '"browser_download_url": *"[^"]+"' | cut -d'"' -f4 \
        | grep -F "$match" | head -1)
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
  local name="$1" spec="${APPS[$1]}" method="${spec%%:*}" rest="${spec#*:}"
  case "$method" in
    deb)         install_deb         "$name" "${rest%%:*}" "${rest#*:}" ;;
    debfile)     install_debfile     "$name" "$rest" ;;
    script)      install_script      "$name" "$rest" ;;
    script-sudo) install_script_sudo "$name" "$rest" ;;
    flatpak)     install_flatpak     "$name" "$rest" ;;
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
