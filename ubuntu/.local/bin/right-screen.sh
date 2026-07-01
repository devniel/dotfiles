#!/bin/sh
# Carve a logical monitor covering only the right part of a 1920x1080 panel, so
# i3 tiles windows there instead of across the full screen. The physical panel
# still scans the full native resolution (no transform/scaling).
#
# Adjust WIDTH to change the usable (right) width.

WIDTH=1200
PANEL_W=1920
PANEL_H=1080
X=$(( PANEL_W - WIDTH ))            # left offset of the usable area
MMW=$(( 527 * WIDTH / PANEL_W ))    # physical width in mm, for correct DPI

xrandr --delmonitor DP-1-right 2>/dev/null
xrandr --setmonitor DP-1-right "${WIDTH}/${MMW}x${PANEL_H}/296+${X}+0" DP-1
