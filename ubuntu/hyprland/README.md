# Hyprland

Daily desktop on Ubuntu 26.04: **Hyprland built from source** into `/opt/hyprland`
(Ubuntu's package lags upstream by a few minor versions), "dark minimal" look
(bg `#0b0d12`, surface `#12151c`, text `#d7dae0`, accent `#7aa2f7`).

The shell is **Noctalia** (bar, launcher, control center, notifications): see `../noctalia`.
Other folders: `../rofi` (clipboard picker), `../kitty`. `../waybar` and `../mako` are the
previous bar and notifier, kept only as a fallback. The compositor config is Lua
(`hyprland.lua`, migrated with HyprMod).

## Restore on a new machine

1. Build Hyprland and its libraries from source. Everything goes into the private
   prefix `/opt/hyprland`, nothing in `/usr` (resumable, re-run it to upgrade):

   ```bash
   mkdir -p ~/hyprland-build && cp ubuntu/hyprland/build.sh ~/hyprland-build/
   ~/hyprland-build/build.sh
   ```

   Uses gcc-16 (Hyprland needs C++26) and Ubuntu 26.04's apt packages for the rest.
   The wayland, wayland-protocols and re2 apt versions are too old, so it builds those too.

2. Install the helper apps (kept from apt): `hypridle hyprlock hyprpaper
   rofi kitty hyprpolkitagent network-manager-gnome blueman pavucontrol cliphist hyprpicker
   nautilus nwg-displays nwg-look grim slurp wl-clipboard brightnessctl playerctl papirus-icon-theme`.
   Mask the user services the packages enable globally, since Hyprland starts them itself:

   ```bash
   systemctl --user mask hypridle.service hyprpaper.service hyprpolkitagent.service
   ```

3. Config files (paths under `~/.config`):

   ```bash
   mkdir -p ~/.config/{hypr,rofi,kitty}
   cp ubuntu/hyprland/{hyprland,monitors,hyprland-gui}.lua ~/.config/hypr/
   cp ubuntu/hyprland/{hyprpaper,hypridle,hyprlock}.conf ~/.config/hypr/
   cp ubuntu/rofi/config.rasi ~/.config/rofi/config.rasi
   mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
   cp ubuntu/gtk/gtk-3.0/settings.ini ~/.config/gtk-3.0/settings.ini
   cp ubuntu/gtk/gtk-4.0/settings.ini ~/.config/gtk-4.0/settings.ini
   gsettings set org.gnome.desktop.wm.preferences button-layout ':'
   cp ubuntu/kitty/kitty.conf ~/.config/kitty/kitty.conf
   ubuntu/hyprland/make-wallpaper.sh
   ```

   `monitors.lua` is separate on purpose: `hyprland.lua` loads it with `require("monitors")`.
   Edit the monitor names and scale there for a different machine. `hyprland-gui.lua` is
   HyprMod's own file (empty until you save something in it); `hyprland.lua` requires it, so
   it must exist.

4. Noctalia (shell) and HyprMod (settings app): follow `../noctalia/README.md`.

5. Overview plugin (Mission Control style grid of spaces, `Super+Tab`):

   ```bash
   ubuntu/hyprland/build-hyprexpo.sh
   ```

   Plugins are tied to the exact Hyprland version, so rebuild this after every Hyprland
   upgrade. The `hl.plugin.load(...)` line in `hyprland.lua` errors on reload until it matches.

6. Add the login session so LightDM can start it (needs sudo):

   ```bash
   sudo tee /usr/share/wayland-sessions/hyprland-src.desktop <<'EOT'
   [Desktop Entry]
   Name=Hyprland (source build)
   Comment=Hyprland built from source in /opt/hyprland
   Exec=/opt/hyprland/bin/hyprland-session
   Type=Application
   DesktopNames=Hyprland
   EOT
   ```

   `hyprland-session` is written by `build.sh`. Pick "Hyprland (source build)" at the login
   screen *after* typing your username, because the greeter resets to your saved default
   session when you submit it.

## Keys

| Keys | Action |
|---|---|
| `Super+Return` | terminal (kitty) |
| Tap `Super`, `Super+Space` or `Super+D` | launcher (Noctalia; tap again to close) |
| `Super+S` / `Super+,` | Noctalia control center (Wi-Fi, Bluetooth, audio) / settings |
| `Super+Tab` or 4-finger swipe up | overview of all spaces (drag windows between them) |
| `Ctrl+Alt+←/→` or 4-finger swipe | switch space (add `Shift` to carry the window) |
| `Super+1..0` / `Super+Shift+1..0` | go to / send window to space 1-10 |
| `Super+N` / `Super+Shift+N` | new empty space (with the window) |
| `Super+Q` `Super+F` `Super+V` | close, fullscreen, float |
| `Super+L` | lock screen (idle: lock 10 min, screens off 15 min) |
| `Super+C` / `Super+P` | clipboard history (cliphist + rofi) / colour picker |
| `Super+E` / `Super+B` / `Super+A` | files / Chrome / volume mixer |

Workspace switching has no animation (`animation = workspaces, 0`); set
`animation = workspaces, 1, 3, smooth, slide` to bring the slide back.

## Notes

- Logitech G502: the middle button opens/closes the overview by sending `Super+Tab` from a
  macro stored on the mouse itself (not in these files). Recreate it with
  `ratbagctl <device> profile 2 button 2 action set macro +KEY_LEFTMETA KEY_TAB -KEY_LEFTMETA`
  (`ratbagctl list` shows the device name; Piper's macro editor does the same). It has to be
  a key press, not a `mouse:274` bind: while the overview is open hyprexpo consumes every
  mouse click and selects the hovered space, but it ignores key presses, so `Super+Tab`
  closes it without switching. Undo with `... action set button 3`.
- Overview speed: the zoom uses Hyprland's `windowsMove` animation (`speed = 2` in
  `hyprland.lua`, lower is faster). It also speeds up window move/resize.

- Window buttons (minimize/maximize/close) are hidden in GTK and libadwaita apps with
  `button-layout ':'` (gsettings) plus `gtk-decoration-layout=:` in the two `ubuntu/gtk`
  files. Close windows with `Super+Q`. Chrome, Firefox and Electron draw their own buttons
  and need their own setting (Chrome: right-click the tab bar, "Use system title bar and
  borders").
- Validate the Lua config without restarting: `Hyprland --verify-config -c ~/.config/hypr/hyprland.lua`.
  A Lua error stops the rest of the file from running, so check it before logging out.
  (It prints "unknown config key plugin.hyprexpo.*" because plugins are not loaded in that
  mode; that is expected.)
- Migrating `.conf` to Lua left `gesture ... dispatcher` and the `Super+Tab` plugin bind
  broken; both are fixed in `hyprland.lua`. In Lua mode `hyprctl dispatch` takes Lua syntax, so
  `hyprctl dispatch hyprexpo:expo toggle` does not work; call the plugin's Lua function
  instead: `hl.plugin.hyprexpo.expo("toggle")`. Test a plugin call without a keypress with
  `hyprctl eval "hl.plugin.hyprexpo.expo('toggle')"`.
- `hyprlock.conf` is written but was never test-locked.
- `xdg-desktop-portal-hyprland` is still the apt build (screen sharing).
- `hyprpm` does not work on this setup (its sudo header install leaves root-owned files
  in its temp dir), which is why the plugin has its own build script.
