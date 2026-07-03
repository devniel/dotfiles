#!/bin/sh
# Switch DP-1 to native 4K (3840x2160) and use the WHOLE panel.
#
# Not persistent. Your login default (see ~/.xsessionrc -> right-screen.sh) is a
# 1920x1080 panel with a carved right-side logical monitor. Run this when you
# want the full 4K screen instead; run with --reset to return to that default.
#
# polybar and i3 are bound to the "DP-1-right" logical monitor, so this
# redefines DP-1-right to span the full 4K output, then relaunches polybar.
#
# Usage:
#   screen-4k.sh          4K, full-screen, polybar full-width
#   screen-4k.sh --reset  back to login default (1080p + right-side strip)

set -e

OUTPUT="DP-1"
VNAME="DP-1-right"
RATE=60
LAUNCH="$HOME/.config/polybar/grayblocks/launch.sh"

relaunch_polybar() {
	[ -x "$LAUNCH" ] && setsid -f "$LAUNCH" >/dev/null 2>&1
}

if [ "$1" = "--reset" ] || [ "$1" = "off" ]; then
	xrandr --output "$OUTPUT" --mode 1920x1080 --rate "$RATE"
	# right-screen.sh re-carves DP-1-right at 1080p and relaunches polybar.
	if [ -x "$HOME/.local/bin/right-screen.sh" ]; then
		"$HOME/.local/bin/right-screen.sh"
	else
		relaunch_polybar
	fi
	echo "Reset: $OUTPUT at 1920x1080, right-side strip restored."
	exit 0
fi

# Native 4K, whole panel.
xrandr --output "$OUTPUT" --mode 3840x2160 --rate "$RATE"
# Redefine the logical monitor polybar/i3 use to cover the ENTIRE 4K panel.
xrandr --delmonitor "$VNAME" 2>/dev/null || true
xrandr --setmonitor "$VNAME" "3840/621x2160/341+0+0" "$OUTPUT"
relaunch_polybar
echo "$OUTPUT at 3840x2160 (full 4K); polybar relaunched full-width."
