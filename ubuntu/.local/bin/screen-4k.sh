#!/bin/sh
# Switch the connected panel to its native/preferred mode (whatever that is -
# 4K on this machine, but detected rather than assumed) and use the WHOLE
# panel.
#
# Not persistent. Your login default (see ~/.xsessionrc -> right-screen.sh) is
# the panel at 1920x1080. Run this when you want the full native-resolution
# screen instead; run with --reset to return to that default.
#
# polybar and i3 are bound to the "DP-1-right" logical monitor, so this
# redefines DP-1-right to span the full native-resolution output. Because
# polybar can't scale itself for the higher pixel density, we derive a 2x copy
# of the canonical grayblocks/config.ini (bigger bar + fonts) at launch time
# and run that. The tracked config.ini stays as the 1080p original.
#
# Usage:
#   screen-4k.sh          native res, full-screen, polybar full-width (2x bar/fonts)
#   screen-4k.sh --reset  back to login default (1080p + right-side strip)

set -e

# Detect the connected output (panel enumerates as DP-1 or DP-2 depending on
# port/cable). Prefer the primary, else first connected.
XR=$(xrandr)
OUTPUT=$(echo "$XR" | awk '/ connected primary/{print $1; exit}')
[ -z "$OUTPUT" ] && OUTPUT=$(echo "$XR" | awk '/ connected/{print $1; exit}')

# Native/preferred mode (marked "+" by xrandr) and physical size (mm) of the
# panel that's actually plugged in right now, instead of a resolution and
# monitor geometry baked in for one specific screen.
MODE=$(echo "$XR" | awk -v out="$OUTPUT" '
	$0 ~ "^"out" connected" {found=1; next}
	found && /^[A-Za-z]/ {found=0}
	found && /\+/ {print $1; exit}
')
[ -z "$MODE" ] && MODE=$(echo "$XR" | awk -v out="$OUTPUT" '
	$0 ~ "^"out" connected" {found=1; next}
	found && /^[A-Za-z]/ {found=0}
	found {print $1; exit}
')
MM_W=$(echo "$XR" | awk -v out="$OUTPUT" '$0 ~ "^"out" connected"{for(i=1;i<=NF;i++) if($i ~ /^[0-9]+mm$/){print $i+0; exit}}')
MM_H=$(echo "$XR" | awk -v out="$OUTPUT" '$0 ~ "^"out" connected"{n=0; for(i=1;i<=NF;i++) if($i ~ /^[0-9]+mm$/){n++; if(n==2){print $i+0; exit}}}')
RES_W=${MODE%x*}
RES_H=${MODE#*x}
VNAME="DP-1-right"
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
	xrandr --output "$OUTPUT" --mode 1920x1080
	# right-screen.sh re-carves DP-1-right at 1080p and relaunches polybar.
	if [ -x "$HOME/.local/bin/right-screen.sh" ]; then
		"$HOME/.local/bin/right-screen.sh"
	elif [ -x "$GB/launch.sh" ]; then
		setsid -f "$GB/launch.sh" >/dev/null 2>&1
	fi
	echo "Reset: $OUTPUT at 1920x1080, right-side strip restored."
	exit 0
fi

# Native resolution (whatever the currently connected panel's preferred mode
# is), whole panel.
xrandr --output "$OUTPUT" --mode "$MODE"
xrandr --delmonitor "$VNAME" 2>/dev/null || true
xrandr --setmonitor "$VNAME" "${RES_W}/${MM_W}x${RES_H}/${MM_H}+0+0" "$OUTPUT"
launch_polybar_4k
echo "$OUTPUT at $MODE (native, full panel); polybar relaunched full-width (2x bar/fonts)."
