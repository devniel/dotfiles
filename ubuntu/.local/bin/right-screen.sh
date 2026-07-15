#!/bin/sh
# Login default: use the whole HD panel (DP-2, 1920x1080), no carve/gap.
#
# This used to carve a 1400px-wide "DP-1-right" virtual monitor and leave a
# ~520px gap on the left (for a since-abandoned 4K docking setup on DP-1).
# polybar's config.ini now targets DP-2 directly and full-width, so there's
# nothing left to carve - just delegate to screen-hd.sh, which is the single
# source of truth for "drive this HD monitor".

exec "$HOME/.local/bin/screen-hd.sh"
