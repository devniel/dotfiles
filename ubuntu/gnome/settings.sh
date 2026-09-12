#!/usr/bin/env bash
#
# settings.sh — every gsettings/dconf customization for the "gnome" session.
#
# Run after extensions/install.sh. Safe to re-run (every write is
# idempotent). Extension-specific settings use --schemadir pointed at the
# extension's own compiled schema, so this works even before Shell has ever
# loaded the extension (no need to wait for the first logout/login first) -
# see ../README.md for why that first login is still required regardless.
#
#   ./ubuntu/gnome/settings.sh
#
set -euo pipefail

EXT_DIR="$HOME/.local/share/gnome-shell/extensions"

# --- enabled extensions ------------------------------------------------------

gsettings set org.gnome.shell enabled-extensions "$(python3 -c "print([
    'ubuntu-dock@ubuntu.com',
    'simulate-switching-workspaces-on-active-monitor@micheledaros.com',
    'native-window-placement@gnome-shell-extensions.gcampax.github.com',
    'pop-shell@system76.com',
    'apps-menu@gnome-shell-extensions.gcampax.github.com',
    'light-style@gnome-shell-extensions.gcampax.github.com',
    'places-menu@gnome-shell-extensions.gcampax.github.com',
    'screenshot-window-sizer@gnome-shell-extensions.gcampax.github.com',
    'system-monitor@gnome-shell-extensions.gcampax.github.com',
    'user-theme@gnome-shell-extensions.gcampax.github.com',
    'improved-workspace-indicator@michaelaquilina.github.io',
])")"

# --- custom app launchers (matches i3's $mod+g / $mod+b) --------------------

MEDIA_KEYS=org.gnome.settings-daemon.plugins.media-keys
CUSTOM0=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/
CUSTOM1=/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/

gsettings set $MEDIA_KEYS custom-keybindings "['$CUSTOM0', '$CUSTOM1']"
gsettings set $MEDIA_KEYS.custom-keybinding:$CUSTOM0 name "Ghostty"
gsettings set $MEDIA_KEYS.custom-keybinding:$CUSTOM0 command "ghostty"
gsettings set $MEDIA_KEYS.custom-keybinding:$CUSTOM0 binding "<Super>g"
gsettings set $MEDIA_KEYS.custom-keybinding:$CUSTOM1 name "Google Chrome"
gsettings set $MEDIA_KEYS.custom-keybinding:$CUSTOM1 command "google-chrome"
gsettings set $MEDIA_KEYS.custom-keybinding:$CUSTOM1 binding "<Super>b"

# --- Pop Shell's recommended keybinding migration ---------------------------
#
# This is Pop Shell's own scripts/configure.sh set_keybindings(), applied
# explicitly instead of through its interactive prompt (which
# extensions/install.sh declines). One line skipped on purpose: upstream also
# points <Super>b at settings-daemon's built-in "www" (browser) launcher,
# which would silently double up with the custom Chrome shortcut above on
# the exact same key.
KEYS_GNOME_WM=/org/gnome/desktop/wm/keybindings
KEYS_GNOME_SHELL=/org/gnome/shell/keybindings
KEYS_MUTTER=/org/gnome/mutter/keybindings
KEYS_MEDIA=/org/gnome/settings-daemon/plugins/media-keys
KEYS_MUTTER_WAYLAND_RESTORE=/org/gnome/mutter/wayland/keybindings/restore-shortcuts

dconf write ${KEYS_MUTTER_WAYLAND_RESTORE} "@as []"
dconf write ${KEYS_GNOME_WM}/minimize "@as ['<Super>comma']"
# open-application-menu no longer exists as a schema key in GNOME 46 (dropped
# upstream); upstream's dconf write to it is a harmless no-op, skipped here.
dconf write ${KEYS_GNOME_SHELL}/toggle-message-tray "@as ['<Super>v']"
dconf write ${KEYS_GNOME_WM}/switch-to-workspace-left "@as []"
dconf write ${KEYS_GNOME_WM}/switch-to-workspace-right "@as []"
dconf write ${KEYS_GNOME_WM}/maximize "@as []"
dconf write ${KEYS_GNOME_WM}/unmaximize "@as []"
dconf write ${KEYS_GNOME_WM}/move-to-monitor-up "@as []"
dconf write ${KEYS_GNOME_WM}/move-to-monitor-down "@as []"
dconf write ${KEYS_GNOME_WM}/move-to-monitor-left "@as []"
dconf write ${KEYS_GNOME_WM}/move-to-monitor-right "@as []"
dconf write ${KEYS_GNOME_WM}/move-to-workspace-down "@as []"
dconf write ${KEYS_GNOME_WM}/move-to-workspace-up "@as []"
dconf write ${KEYS_GNOME_WM}/switch-to-workspace-down "['<Primary><Super>Down','<Primary><Super>j']"
dconf write ${KEYS_GNOME_WM}/switch-to-workspace-up "['<Primary><Super>Up','<Primary><Super>k']"
dconf write ${KEYS_MUTTER}/toggle-tiled-left "@as []"
dconf write ${KEYS_MUTTER}/toggle-tiled-right "@as []"
dconf write ${KEYS_GNOME_WM}/toggle-maximized "['<Super>m']"
dconf write ${KEYS_MEDIA}/screensaver "['<Super>Escape']"
dconf write ${KEYS_MEDIA}/home "['<Super>f']"
dconf write ${KEYS_MEDIA}/email "['<Super>e']"
dconf write ${KEYS_MEDIA}/terminal "['<Super>t']"
dconf write ${KEYS_MEDIA}/rotate-video-lock-static "@as []"
dconf write ${KEYS_GNOME_WM}/close "['<Super>q', '<Alt>F4']"

# The migration above clears toggle-overview along with everything else
# (Pop Shell wants the bare Super key free for its own gestures), which
# breaks tapping Super to open the Activities overview - including from a
# mouse-button macro simulating that tap: GNOME/Mutter's bare-modifier-tap
# detection doesn't reliably recognize synthetic key events from a mouse's
# onboard macro engine, even though it's a real HID keyboard report. Restore
# the normal Super tap for the keyboard, and add a real combo alternative
# that a macro can trigger reliably (see ../mouse/ - the middle button on the
# gnome Piper profile targets this combo, not a bare Super tap).
gsettings set org.gnome.shell.keybindings toggle-overview "['<Super>', '<Control><Super>a']"

# --- per-extension preferences ----------------------------------------------

# simulate-switching-workspaces-on-active-monitor: match the Piper profile's
# Ctrl+Alt+Left/Right (see ../mouse/) instead of the default Ctrl+Alt+Q/A.
SIM_UUID="simulate-switching-workspaces-on-active-monitor@micheledaros.com"
SIM_SCHEMA="org.gnome.shell.extensions.simulate-switching-workspaces-on-active-monitor"
gsettings --schemadir "$EXT_DIR/$SIM_UUID/schemas/" set $SIM_SCHEMA \
  switch-to-next-workspace-on-active-monitor "['<Control><Alt>Right']"
gsettings --schemadir "$EXT_DIR/$SIM_UUID/schemas/" set $SIM_SCHEMA \
  switch-to-previous-workspace-on-active-monitor "['<Control><Alt>Left']"

# Also remove the same accelerator from GNOME's own built-in workspace-switch
# keys - two consumers claiming an identical accelerator means one of them
# doesn't fire reliably. Pop Shell's migration above already clears both to
# empty, so this is only needed if that migration is ever skipped.
# (left as a comment/reference; nothing to run - see README's "bugs hit" note)

# Pop Shell's own toggle-floating defaults to <Super>g, colliding with the
# Ghostty launcher above. Move it out of the way.
POP_UUID="pop-shell@system76.com"
gsettings --schemadir "$EXT_DIR/$POP_UUID/schemas" set org.gnome.shell.extensions.pop-shell \
  toggle-floating "['<Super><Shift>g']"

# Ubuntu Dock on every monitor, not just the primary one.
gsettings set org.gnome.shell.extensions.dash-to-dock multi-monitor true

# --- mutter -------------------------------------------------------------

# Workspaces-per-monitor behavior. true = each monitor has its own active
# workspace at the mutter level (still not the same as fully independent
# per-monitor workspace *stacks* - see README's "GNOME Workspace Islands"
# note); false = workspaces span every display together. This machine
# currently runs true, working alongside the simulate-switching extension
# above rather than through it.
gsettings set org.gnome.mutter workspaces-only-on-primary true

echo ":: done. Log out and back into the GNOME session if you haven't since"
echo "   running extensions/install.sh, so everything above actually loads."
