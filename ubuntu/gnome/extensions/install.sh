#!/usr/bin/env bash
#
# install.sh — install every GNOME Shell extension the "gnome" session uses.
#
# Run once before the first login to that session (see ../README.md for why
# a real logout/login is unavoidable under Wayland). Safe to re-run: apt
# packages upgrade in place, the manual extensions are re-downloaded and
# overwritten, and Pop Shell rebuilds from a fresh clone.
#
#   ./ubuntu/gnome/extensions/install.sh
#
set -euo pipefail

# --- apt-packaged extensions -------------------------------------------------

echo ":: apt — gnome-shell-extensions bundle + Ubuntu Dock"
sudo apt-get install -y gnome-shell-extensions gnome-shell-extension-ubuntu-dock

# --- manual extensions (not in Ubuntu's repos) -------------------------------

# Downloads the given extension's current release for this GNOME Shell
# version from extensions.gnome.org and installs it under
# ~/.local/share/gnome-shell/extensions/. Shell only picks up files placed
# there at its own next startup - see ../README.md.
install_manual_extension() {
  local uuid="$1"
  local dir="$HOME/.local/share/gnome-shell/extensions/$uuid"
  local shell_version
  shell_version="$(gnome-shell --version | grep -oE '[0-9]+' | head -1)"

  echo ":: $uuid — resolving current release for GNOME Shell $shell_version"
  local pk
  pk=$(curl -fsSL "https://extensions.gnome.org/extension-query/?search=$uuid" \
       | python3 -c "
import json, sys
uuid = '$uuid'
for e in json.load(sys.stdin).get('extensions', []):
    if e['uuid'] == uuid:
        print(e['pk']); break
")
  [ -z "$pk" ] && { echo "!! $uuid — not found on extensions.gnome.org" >&2; return 1; }

  local version_tag
  version_tag=$(curl -fsSL "https://extensions.gnome.org/extension-info/?pk=$pk" \
       | python3 -c "
import json, sys
d = json.load(sys.stdin)
v = d.get('shell_version_map', {}).get('$shell_version')
print(v['pk'] if v else '')
")
  [ -z "$version_tag" ] && { echo "!! $uuid — no release for Shell $shell_version" >&2; return 1; }

  local tmp; tmp="$(mktemp -d)"
  curl -fsSL "https://extensions.gnome.org/download-extension/${uuid}.shell-extension.zip?version_tag=${version_tag}" \
    -o "$tmp/ext.zip"
  rm -rf "$dir"; mkdir -p "$dir"
  unzip -oq "$tmp/ext.zip" -d "$dir"
  rm -rf "$tmp"

  if [ -d "$dir/schemas" ]; then
    glib-compile-schemas "$dir/schemas/"
  fi
  echo ":: $uuid — installed to $dir"
}

install_manual_extension "improved-workspace-indicator@michaelaquilina.github.io"
install_manual_extension "simulate-switching-workspaces-on-active-monitor@micheledaros.com"

# --- Pop Shell (built from source) ------------------------------------------

# Not on extensions.gnome.org; System76's own current instructions
# (https://system76.com/support/articles/pop-shell/) for a non-Pop!_OS GNOME
# desktop. master_noble is the branch for Ubuntu 24.04/24.10+.
echo ":: pop-shell — installing build dependencies"
sudo apt-get install -y git node-typescript make gnome-shell-extension-prefs

echo ":: pop-shell — cloning master_noble and building"
tmp="$(mktemp -d)"
git clone --branch master_noble --depth 1 https://github.com/pop-os/shell.git "$tmp/shell"
(
  cd "$tmp/shell"
  # local-install's own configure step interactively asks whether to override
  # a batch of default GNOME shortcuts. Answer no here - settings.sh applies
  # our own curated version of that same migration explicitly, so it's all
  # in one auditable place instead of split between this prompt and our own
  # overrides. `|| true`: the very last step (`gnome-extensions enable`)
  # always fails before the first login, same as every extension here - see
  # ../README.md.
  yes n | make local-install || true
)
rm -rf "$tmp"

echo ":: done — log out and back into the GNOME session, then run ../settings.sh"
