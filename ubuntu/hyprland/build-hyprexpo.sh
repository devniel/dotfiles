#!/usr/bin/env bash
# Builds the hyprexpo overview plugin (maintained fork) against the source-built
# Hyprland in /opt/hyprland and installs it where hyprland.conf's `plugin =` line expects.
# Plugins are ABI-locked to the exact Hyprland version: rebuild after every Hyprland upgrade,
# and pick a TAG the fork lists as supporting that version (see its README).
# Do not run while the old .so is loaded in a live session you care about: test in a nested
# `Hyprland -c test.conf` first.
set -euo pipefail

TAG="${TAG:-v0.56.2+2}"
SRC="$HOME/hyprland-build/src/hyprexpo-fork"
DEST="$HOME/.local/lib/hyprexpo/hyprexpo.so"

[ -d "$SRC/.git" ] || git clone https://github.com/sandwichfarm/hyprexpo.git "$SRC"
cd "$SRC"
git fetch --tags --quiet
git checkout --quiet "$TAG"

export PKG_CONFIG_PATH=/opt/hyprland/lib/pkgconfig:/opt/hyprland/share/pkgconfig
# ~/.local/bin can hold an older python that breaks Hyprland tooling; keep it off PATH here too.
export PATH="/opt/hyprland/bin:$(printf %s "$PATH" | tr : '\n' | grep -vx "$HOME/.local/bin" | paste -sd:)"

make clean >/dev/null 2>&1 || true
# Hyprland links Lua 5.5, so the plugin must too (its default is 5.4).
make all CXX=g++-16 LUA_PKG_CONFIG=lua5.5 EXTRA_FLAGS=-fno-gnu-unique -j"$(nproc)"

# `install` swaps the file safely; never `cp` over a loaded plugin.
install -D -m 0755 hyprexpo.so "$DEST"
echo "installed $DEST ($TAG)"
