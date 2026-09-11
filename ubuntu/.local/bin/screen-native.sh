#!/bin/sh
# Switch the connected panel to its native/preferred mode (whatever that is -
# 4K on this machine, but detected rather than assumed) and use the WHOLE
# panel, with 2x UI scaling so things stay the same size as at 1080p.
#
# This is the login default (see ~/.xsessionrc). Run with --reset to drop back
# to 1920x1080 at 1x (same as screen-hd.sh).
#
# Scaling: sets Xft.dpi to 192 (and a 2x cursor) in the X resource database.
# Apps read it when they start, so windows already open keep their old size
# until reopened; i3 picks it up on restart ($mod+Shift+r).
#
# polybar and i3 are bound to the "DP-1-right" logical monitor, so this
# redefines DP-1-right to span the full native-resolution output. Because
# polybar can't scale itself for the higher pixel density, we derive a 2x copy
# of the canonical grayblocks/config.ini (bigger bar + fonts) at launch time
# and run that. The tracked config.ini stays as the 1080p original.
#
# Usage:
#   screen-native.sh          native res, full-screen, 2x scaling, polybar full-width (2x bar/fonts)
#   screen-native.sh --reset  back to 1920x1080 at 1x scaling

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
	# 2x the pixel-sized values (bar height, under/overline, top border, tray
	# icons) and the two font sizes from the 1080p config.
	sed -E \
		-e 's/^height = .*/height = 80/' \
		-e 's/^line-size = .*/line-size = 12/' \
		-e 's/^border-top-size = .*/border-top-size = 8/' \
		-e 's/^tray-maxsize = .*/tray-maxsize = 32/' \
		-e 's/(:size=)10;4/\120;8/' \
		-e 's/(:size=)10;3/\120;6/' \
		"$CFG" > "$CFG4K"
	killall -q polybar 2>/dev/null || true
	while pgrep -u "$(id -u)" -x polybar >/dev/null 2>&1; do sleep 1; done
	setsid -f polybar -q main -c "$CFG4K" >/dev/null 2>&1
}

if [ "$1" = "--reset" ] || [ "$1" = "off" ]; then
	xrandr --output "$OUTPUT" --mode 1920x1080
	printf 'Xft.dpi: 96\nXcursor.size: 24\n' | xrdb -merge
	# right-screen.sh delegates to screen-hd.sh (1080p full-width, 1x polybar).
	if [ -x "$HOME/.local/bin/right-screen.sh" ]; then
		"$HOME/.local/bin/right-screen.sh"
	elif [ -x "$GB/launch.sh" ]; then
		setsid -f "$GB/launch.sh" >/dev/null 2>&1
	fi
	echo "Reset: $OUTPUT at 1920x1080, 1x scaling."
	exit 0
fi

# Native resolution (whatever the currently connected panel's preferred mode
# is), whole panel.
xrandr --output "$OUTPUT" --mode "$MODE"
xrandr --delmonitor "$VNAME" 2>/dev/null || true
xrandr --setmonitor "$VNAME" "${RES_W}/${MM_W}x${RES_H}/${MM_H}+0+0" "$OUTPUT"
printf 'Xft.dpi: 192\nXcursor.size: 48\n' | xrdb -merge
launch_polybar_4k
echo "$OUTPUT at $MODE (native, full panel), 2x scaling; polybar relaunched full-width (2x bar/fonts)."
