#!/bin/sh
# Switch DP-1 to native 4K (3840x2160) and use the WHOLE panel.
#
# Not persistent. Your login default (see ~/.xsessionrc -> right-screen.sh) is a
# 1920x1080 panel with a carved right-side logical monitor. Run this when you
# want the full 4K screen instead; run with --reset to return to that default.
#
# polybar and i3 are bound to the "DP-1-right" logical monitor, so this
# redefines DP-1-right to span the full 4K output. Because polybar can't scale
# itself for the higher pixel density, we derive a 2x copy of the canonical
# grayblocks/config.ini (bigger bar + fonts) at launch time and run that. The
# tracked config.ini stays as the 1080p original.
#
# Usage:
#   screen-4k.sh          4K, full-screen, polybar full-width (2x bar/fonts)
#   screen-4k.sh --reset  back to login default (1080p + right-side strip)

set -e

# Detect the connected output (panel enumerates as DP-1 or DP-2 depending on
# port/cable). Prefer the primary, else first connected.
OUTPUT=$(xrandr | awk '/ connected primary/{print $1; exit}')
[ -z "$OUTPUT" ] && OUTPUT=$(xrandr | awk '/ connected/{print $1; exit}')
VNAME="DP-1-right"
RATE=60
GB="$HOME/.config/polybar/grayblocks"
CFG="$GB/config.ini"
CFG4K="${XDG_RUNTIME_DIR:-/tmp}/polybar-grayblocks-4k.ini"

launch_polybar_4k() {
	# 2x the bar height and the two font sizes from the 1080p config.
	sed -E \
		-e 's/^height = .*/height = 80/' \
		-e 's/(:size=)10;4/\120;8/' \
		-e 's/(:size=)10;3/\120;6/' \
		"$CFG" > "$CFG4K"
	killall -q polybar 2>/dev/null || true
	while pgrep -u "$(id -u)" -x polybar >/dev/null 2>&1; do sleep 1; done
	setsid -f polybar -q main -c "$CFG4K" >/dev/null 2>&1
}

if [ "$1" = "--reset" ] || [ "$1" = "off" ]; then
	xrandr --output "$OUTPUT" --mode 1920x1080 --rate "$RATE"
	# right-screen.sh re-carves DP-1-right at 1080p and relaunches polybar.
	if [ -x "$HOME/.local/bin/right-screen.sh" ]; then
		"$HOME/.local/bin/right-screen.sh"
	elif [ -x "$GB/launch.sh" ]; then
		setsid -f "$GB/launch.sh" >/dev/null 2>&1
	fi
	echo "Reset: $OUTPUT at 1920x1080, right-side strip restored."
	exit 0
fi

# Native 4K, whole panel.
xrandr --output "$OUTPUT" --mode 3840x2160 --rate "$RATE"
xrandr --delmonitor "$VNAME" 2>/dev/null || true
xrandr --setmonitor "$VNAME" "3840/621x2160/341+0+0" "$OUTPUT"
launch_polybar_4k
echo "$OUTPUT at 3840x2160 (full 4K); polybar relaunched full-width (2x bar/fonts)."
