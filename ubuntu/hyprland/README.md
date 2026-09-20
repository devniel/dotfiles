# Hyprland

Daily desktop on Ubuntu 26.04: **Hyprland built from source** into `/opt/hyprland`
(Ubuntu's package lags upstream by a few minor versions), "dark minimal" look
(bg `#0b0d12`, surface `#12151c`, text `#d7dae0`, accent `#7aa2f7`).

Related folders: `../waybar`, `../rofi`, `../mako`, `../kitty` (all launched by Hyprland).

## Restore on a new machine

1. Build Hyprland and its libraries from source. Everything goes into the private
   prefix `/opt/hyprland`, nothing in `/usr` (resumable, re-run it to upgrade):

   ```bash
   mkdir -p ~/hyprland-build && cp ubuntu/hyprland/build.sh ~/hyprland-build/
   ~/hyprland-build/build.sh
   ```

   Uses gcc-16 (Hyprland needs C++26) and Ubuntu 26.04's apt packages for the rest.
   The wayland, wayland-protocols and re2 apt versions are too old, so it builds those too.

2. Install the helper apps (kept from apt): `waybar mako-notifier hypridle hyprlock hyprpaper
   rofi kitty hyprpolkitagent network-manager-gnome blueman pavucontrol cliphist hyprpicker
   nautilus nwg-displays nwg-look grim slurp wl-clipboard brightnessctl playerctl papirus-icon-theme`.
   Mask the user services the packages enable globally, since Hyprland starts them itself:

   ```bash
   systemctl --user mask waybar.service hypridle.service hyprpaper.service hyprpolkitagent.service
   ```

3. Config files (paths under `~/.config`):

   ```bash
   mkdir -p ~/.config/{hypr,waybar,rofi,mako,kitty}
   cp ubuntu/hyprland/{hyprland,monitors,hyprpaper,hypridle,hyprlock}.conf ~/.config/hypr/
   cp ubuntu/waybar/* ~/.config/waybar/
   cp ubuntu/rofi/config.rasi ~/.config/rofi/config.rasi
   cp ubuntu/mako/config ~/.config/mako/config
   cp ubuntu/kitty/kitty.conf ~/.config/kitty/kitty.conf
   ubuntu/hyprland/make-wallpaper.sh
   ```

   `monitors.conf` is separate on purpose: `nwg-displays` writes to it, and `hyprland.conf`
   sources it. Edit the monitor names and scale there for a different machine.

4. Overview plugin (Mission Control style grid of spaces, `Super+Tab`):

   ```bash
   ubuntu/hyprland/build-hyprexpo.sh
   ```

   Plugins are tied to the exact Hyprland version, so rebuild this after every Hyprland
   upgrade. The `plugin = ...` line in `hyprland.conf` errors on reload until it matches.

5. Add the login session so LightDM can start it (needs sudo):

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
| Tap `Super`, `Super+Space` or `Super+D` | launcher (rofi, DarkBlue theme + Papirus-Dark icons) |
| `Super+Tab` or 4-finger swipe up | overview of all spaces (drag windows between them) |
| `Ctrl+Alt+←/→` or 4-finger swipe | switch space (add `Shift` to carry the window) |
| `Super+1..0` / `Super+Shift+1..0` | go to / send window to space 1-10 |
| `Super+N` / `Super+Shift+N` | new empty space (with the window) |
| `Super+Q` `Super+F` `Super+V` | close, fullscreen, float |
| `Super+L` | lock screen (idle: lock 10 min, screens off 15 min) |
| `Super+C` / `Super+P` | clipboard history / colour picker |
| `Super+E` / `Super+A` | files / volume mixer |

Workspace switching has no animation (`animation = workspaces, 0`); set
`animation = workspaces, 1, 3, smooth, slide` to bring the slide back.

## Notes

- `hyprlock.conf` is written but was never test-locked.
- `xdg-desktop-portal-hyprland` is still the apt build (screen sharing).
- `hyprpm` does not work on this setup (its sudo header install leaves root-owned files
  in its temp dir), which is why the plugin has its own build script.
