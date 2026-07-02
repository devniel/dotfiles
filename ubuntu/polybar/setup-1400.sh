#!/usr/bin/env bash
#
# Configure DP-1 as a 1400px-wide virtual monitor (right-flush) and launch
# polybar to match. Under i3, dock bars are stretched to the output width, so a
# narrow bar needs a narrow virtual output. grayblocks/config.ini is set with
# `monitor = DP-1-right` so polybar lays out modules for the 1400px width (this
# is what keeps the right-side modules, e.g. the clock, from being clipped).
#
# If this virtual monitor does not exist (e.g. plain login without this script),
# polybar falls back to the physical DP-1 and just renders full-width (1920px).
#
# Usage:
#   setup-1400.sh          apply the 1400px setup + launch polybar
#   setup-1400.sh --reset  remove the virtual monitor + relaunch polybar full-width

set -e

OUTPUT="DP-1"           # physical output
VNAME="DP-1-right"      # virtual monitor name
THEME="grayblocks"      # polybar theme (launch.sh flag)

# Geometry: 1400px wide, flush to the right edge of a 1920px screen (offset 520).
WIDTH=1400
HEIGHT=1080
OFFSET_X=520
OFFSET_Y=0
MM_W=384               # reported physical width  (cosmetic)
MM_H=296               # reported physical height (cosmetic)

launch_dir="$HOME/.config/polybar"

if [[ "$1" == "--reset" ]]; then
	xrandr --delmonitor "$VNAME" 2>/dev/null || true
	echo "Removed virtual monitor $VNAME (if it existed)."
else
	# Idempotent: drop any stale definition first, then (re)create it.
	xrandr --delmonitor "$VNAME" 2>/dev/null || true
	xrandr --setmonitor "$VNAME" \
		"${WIDTH}/${MM_W}x${HEIGHT}/${MM_H}+${OFFSET_X}+${OFFSET_Y}" "$OUTPUT"
	echo "Created virtual monitor $VNAME (${WIDTH}x${HEIGHT}+${OFFSET_X}+${OFFSET_Y})."
fi

# (Re)launch polybar so it re-reads the current monitor layout.
"$launch_dir/launch.sh" "--$THEME" >/dev/null 2>&1 &

echo "Polybar relaunched (theme: $THEME)."
