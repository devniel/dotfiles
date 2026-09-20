#!/usr/bin/env bash
#
# g502-hero-profiles.sh — onboard profile setup for the Logitech G502 HERO,
# via libratbag/ratbagd (Piper's CLI companion, same device state either
# tool edits). Two of the mouse's five onboard profiles are used:
#
#   Profile 1 - gnome  (../gnome/)
#   Profile 2 - i3     (../i3/)
#
# Both share the same base button layout; only the workspace-switch buttons
# and one of the two remaining main buttons differ, matching each session's
# own workspace-switching mechanism. Profiles 0, 3 and 4 are left
# disabled/unconfigured - the mouse's button 8 (profile-cycle-up) can land on
# one of these by mistake; if workspace-switching or copy/paste suddenly stop
# doing anything, check `ratbagctl <device> profile active get`.
#
# `ratbagctl <device> profile active get` is only trustworthy right after
# restarting ratbagd, and *not* trustworthy again once you've since called
# `profile active set` yourself without restarting it: a stale read
# (reporting the pre-switch profile as still active) is what made an already
# -fixed button mapping look broken all over again while building this.
# `sudo systemctl restart ratbagd` before trusting `active get`; don't
# restart it again immediately after your own `active set` if you want that
# specific value trusted.
#
# button indices 1 and 2 (the physical buttons between the wheel and the
# forward/back side buttons) don't obviously correspond to "middle" and
# "right" from ratbagctl's own output - this was fixed empirically by
# swapping which of the two got the macro after physical testing showed the
# wrong one had it, not by reasoning about the device's layout. If a future
# edit here seems to land on the wrong physical button, swap button 1 and
# button 2's actions rather than assuming which index means what.
#
# Safe to re-run (every ratbagctl call sets an absolute value). Needs the
# mouse plugged in.
#
#   ./ubuntu/mouse/g502-hero-profiles.sh
#
set -euo pipefail

MOUSE="$(ratbagctl list | grep 'G502 HERO' | cut -d: -f1)"
[ -z "$MOUSE" ] && { echo "!! G502 HERO not found - is it plugged in?" >&2; exit 1; }
echo ":: found device: $MOUSE"

# Shared base layout: plain passthrough for the three main buttons, a
# "second mode" shift button, copy/paste macros, profile-cycle, and tilt
# wheel. Applied identically to both profiles; the two of them then diverge
# below.
set_base_layout() {
  local p="$1"
  ratbagctl "$MOUSE" profile "$p" resolution 0 dpi set 2400
  ratbagctl "$MOUSE" profile "$p" resolution default set 0
  ratbagctl "$MOUSE" profile "$p" rate set 500

  ratbagctl "$MOUSE" profile "$p" button 0 action set button 1
  # buttons 1 and 2 are set per-profile below - see the note above on why
  # which-index-means-which-physical-button isn't assumed here.
  ratbagctl "$MOUSE" profile "$p" button 5 action set special second-mode
  ratbagctl "$MOUSE" profile "$p" button 6 action set macro \
    +KEY_LEFTCTRL +KEY_C -KEY_C -KEY_LEFTCTRL
  ratbagctl "$MOUSE" profile "$p" button 7 action set macro \
    +KEY_LEFTCTRL +KEY_V -KEY_V -KEY_LEFTCTRL
  ratbagctl "$MOUSE" profile "$p" button 8 action set special profile-cycle-up
  ratbagctl "$MOUSE" profile "$p" button 9 action set special wheel-right
  ratbagctl "$MOUSE" profile "$p" button 10 action set special wheel-left

  ratbagctl "$MOUSE" profile "$p" led 0 set mode on
  ratbagctl "$MOUSE" profile "$p" led 0 set color ffffff
  ratbagctl "$MOUSE" profile "$p" led 1 set mode on
  ratbagctl "$MOUSE" profile "$p" led 1 set color ffffff
}

# Workspace-switch buttons: previous/next on the same two buttons in both
# profiles, so the physical gesture feels identical everywhere. Left = button
# 3 (bottom side button), Right = button 4 (top side button).
set_workspace_switch_buttons() {
  local p="$1"
  ratbagctl "$MOUSE" profile "$p" button 3 action set macro \
    +KEY_LEFTCTRL +KEY_LEFTALT +KEY_LEFT -KEY_LEFT -KEY_LEFTCTRL -KEY_LEFTALT
  ratbagctl "$MOUSE" profile "$p" button 4 action set macro \
    +KEY_LEFTCTRL +KEY_LEFTALT +KEY_RIGHT -KEY_RIGHT -KEY_LEFTCTRL -KEY_LEFTALT
}

ratbagctl "$MOUSE" profile 1 enable
set_base_layout 1
set_workspace_switch_buttons 1
# button 1: plain middle click (empirically the one that should NOT carry
# the macro below - see the button-index note above).
ratbagctl "$MOUSE" profile 1 button 1 action set button 2
# button 2: opens the GNOME Activities overview. NOT a bare Super tap
# (+KEY_LEFTMETA -KEY_LEFTMETA): GNOME/Mutter's bare-modifier-tap detection
# doesn't reliably fire for a mouse's synthetic keypress even though it's a
# genuine HID keyboard report, only for real keyboard input. Ctrl+Super+A is
# a normal combo instead, matched by ../gnome/settings.sh adding it as a
# second accelerator for toggle-overview alongside plain Super.
ratbagctl "$MOUSE" profile 1 button 2 action set macro \
  +KEY_LEFTCTRL +KEY_LEFTMETA +KEY_A -KEY_A -KEY_LEFTMETA -KEY_LEFTCTRL

set_base_layout 2
set_workspace_switch_buttons 2
# Both buttons 1 and 2 stay plain clicks here - i3/X11's standard
# middle-click-paste (primary selection) convention needs the real middle
# button to keep sending a real middle-click, and there's no GNOME-overview
# equivalent to repurpose the other one for under i3.
ratbagctl "$MOUSE" profile 2 button 1 action set button 2
ratbagctl "$MOUSE" profile 2 button 2 action set button 3

echo ":: verifying every button on both profiles (catches the reindex quirk"
echo "   noted above - re-check after any future edit, not just the button"
echo "   you touched):"
ratbagctl "$MOUSE" profile 1 get
ratbagctl "$MOUSE" profile 2 get
