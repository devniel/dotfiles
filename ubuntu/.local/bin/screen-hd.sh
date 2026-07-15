#!/bin/sh
# Ensure the connected HD panel (native 1920x1080) is set correctly and
# polybar is running at 1x sizing.
#
# Unlike screen-4k.sh (which needs a virtual monitor carve + 2x polybar config
# because polybar can't scale itself), this panel is already native 1920x1080
# and polybar's config.ini binds to the primary output (monitor = empty), full
# width. So there's no carving and no config scaling to do here - just (re)apply
# the native mode on the detected output and make sure polybar is up.
#
# Usage:
#   screen-hd.sh    force the connected output to native 1920x1080, relaunch polybar

set -e

# Detect the connected output instead of hardcoding it (the panel shows up as
# DP-1 or DP-2 depending on port/cable). Prefer the primary, else first connected.
OUTPUT=$(xrandr | awk '/ connected primary/{print $1; exit}')
[ -z "$OUTPUT" ] && OUTPUT=$(xrandr | awk '/ connected/{print $1; exit}')
RATE=60
GB="$HOME/.config/polybar/grayblocks"
CFG="$GB/config.ini"

xrandr --output "$OUTPUT" --mode 1920x1080 --rate "$RATE"

# Clean up any stale carved virtual monitor from older setups (leftover
# "*-right" carve leaves a gap since the real monitor is DP-2 full-width).
xrandr --delmonitor DP-1-right >/dev/null 2>&1 || true
xrandr --delmonitor DP-2-right >/dev/null 2>&1 || true

killall -q polybar 2>/dev/null || true
while pgrep -u "$(id -u)" -x polybar >/dev/null 2>&1; do sleep 1; done
setsid -f polybar -q main -c "$CFG" >/dev/null 2>&1

echo "$OUTPUT at 1920x1080 (native HD); polybar relaunched."
