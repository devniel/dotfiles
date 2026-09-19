#!/usr/bin/env bash
# Generates the dark gradient wallpaper that hyprpaper.conf and hyprlock.conf point at.
set -euo pipefail
mkdir -p "$HOME/Pictures/wallpapers"
magick -size 3840x2160 radial-gradient:'#161c2b-#0b0d12' -attenuate 0.12 +noise Gaussian \
    -depth 8 -colorspace sRGB -quality 94 "$HOME/Pictures/wallpapers/dark-minimal.jpg"
