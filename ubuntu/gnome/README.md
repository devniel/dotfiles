# gnome

An alternative login session to `ubuntu/i3/`, installed side by side with it —
nothing here touches i3/polybar/picom, and nothing there touches this. LightDM
offers both at the login screen (the session picker next to the password
field); pick "i3" or "GNOME" per login, switch back any time.

## Why

The i3 setup drives 4K + 2x scaling by hand (`Xft.dpi`, a virtual XRandR
monitor, doubled polybar configs — see `../i3/` and `screen-native.sh`).
GNOME/Mutter does real per-output scaling natively, which is worth having on
tap without giving up i3 day to day.

## Install

```sh
./ubuntu/gnome/extensions/install.sh   # apt packages + manual extensions + Pop Shell
./ubuntu/gnome/settings.sh             # all gsettings/dconf customization
```

Run `install.sh` first — `settings.sh` sets preferences that live inside each
extension's own schema, which has to already be on disk. Then **log out and
back into the GNOME session once** before any of it does anything visible:
GNOME Shell only scans `~/.local/share/gnome-shell/extensions/` for new
extensions at its own startup. Under Wayland there is no equivalent of X11's
"Alt+F2, r" shell restart — `Meta.restart()` is disabled there by design — so
a fresh extension never appears without a real logout/login, no matter what
`gnome-extensions enable` or `gsettings` says in the meantime. `settings.sh`
still runs fine before that first login; it just won't have a visible effect
until Shell has actually loaded the extensions once.

## What's here

- **`extensions/install.sh`** — installs everything: the official
  `gnome-shell-extensions` bundle + Ubuntu Dock via `apt`, three manually
  packaged extensions from extensions.gnome.org (not in Ubuntu's repos), and
  Pop Shell built from source (also not packaged for non-Pop!_OS systems).
- **`settings.sh`** — every `gsettings`/`dconf` customization made on top:
  which extensions are enabled, custom app-launcher shortcuts, the keybinding
  set that makes Pop Shell's tiling comfortable, and a couple of
  extension-specific preferences that needed hand-tuning to avoid conflicts
  (see inline comments — two of them fix real bugs hit while setting this up,
  not just taste).

## Extensions installed

| Extension | Source | Why |
|---|---|---|
| [gnome-shell-extensions](https://gitlab.gnome.org/GNOME/gnome-shell-extensions) bundle | `apt` | Official GNOME extras: apps-menu, places-menu, system-monitor, user-theme, native-window-placement, etc. |
| [Ubuntu Dock](https://gitlab.gnome.org/GNOME/gnome-shell-extensions) | `apt` (`gnome-shell-extension-ubuntu-dock`) | Persistent dock — vanilla GNOME only shows one inside the Activities overview. `multi-monitor` is turned on so it shows on every screen. |
| [Improved Workspace Indicator](https://extensions.gnome.org/extension/3968/improved-workspace-indicator/) | manual (extensions.gnome.org) | Top-bar workspace indicator styled like i3/sway — shows current *and* in-use workspaces, not just a bare number. |
| [Switch workspaces on active monitor](https://extensions.gnome.org/extension/4586/switch-workspaces-on-active-monitor/) | manual (extensions.gnome.org) | GNOME's native multi-monitor modes are "every screen switches together" or "secondary screens are frozen" — neither is what you want. This one fakes independent per-monitor switching by reassigning windows on the active monitor to a different workspace slot, without touching the real global workspace index. Bound to `Ctrl+Alt+Left/Right` to match the mouse's Piper profile (see `../mouse/`). |
| [Pop Shell](https://github.com/pop-os/shell) | built from source (`master_noble` branch) | Real automatic tiling window manager — the actual "Amethyst for GNOME" ask. Not on extensions.gnome.org; System76's own install path for non-Pop!_OS GNOME. Community-maintained, not actively developed by System76 any more, but this is their own current official instructions. |

### Deliberately not installed

- **Multi Monitor Bar** (top bar mirrored onto every screen) — tried it, but
  its own `force-workspaces-on-all-displays` preference (default `true`)
  silently fights `org.gnome.mutter workspaces-only-on-primary` every time
  the extension (re)initializes, undoing independent per-monitor workspace
  switching behind your back. Removed rather than keep fighting it.
- **GNOME Workspace Islands** — the one extension that does *real* native
  per-monitor workspaces (not the simulate/reassign trick above). Needs GNOME
  Shell 50; this machine is on 46, and there's no official upgrade path from
  Ubuntu 24.04 available yet. Revisit if that changes.

## Two real bugs hit setting this up (see `settings.sh` comments)

- **`simulate-switching-workspaces-on-active-monitor`'s default shortcuts
  (`Ctrl+Alt+Q`/`Ctrl+Alt+A`) never fired reliably** until the *exact same*
  `Ctrl+Alt+Left`/`Ctrl+Alt+Right` accelerators were removed from GNOME's own
  built-in `switch-to-workspace-left`/`switch-to-workspace-right` — two
  keybinding consumers claiming the identical accelerator is exactly as
  broken here as it is in i3/polybar. Pop Shell's own keybinding migration
  (applied below) clears those to empty anyway, so this stays fixed as long
  as both scripts are applied in order.
- **A libratbag/ratbagd quirk**: changing a mouse button's action from a
  plain passthrough to a macro can leave a stray copy of the *old* macro on a
  neighboring button index (hit this going from "button 3 → macro" and
  finding button 2 silently carrying the leftover macro afterward). Always
  re-run `ratbagctl <device> profile N get` after changing a button and check
  every button, not just the one you touched.

## Mouse profiles

See `../mouse/` — the Piper/libratbag profile used while in this session
(workspace switching, overview-toggle, copy/paste) is tracked there alongside
the i3 one, since both live on the same physical mouse.
