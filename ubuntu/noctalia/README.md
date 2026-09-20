# Noctalia + HyprMod

Noctalia v5 is the desktop shell on the Hyprland setup (see `../hyprland/README.md`).
It replaces waybar, mako and the app launcher: bar, launcher, control center (Wi-Fi,
Bluetooth, audio), notifications, wallpaper and theming. Hyprland starts it with
`noctalia --daemon` and drives it with `noctalia msg ...` keybinds.

HyprMod is a GTK settings app for Hyprland (`hyprmod`), used to migrate the config to Lua
and to tweak options with a live preview.

## Noctalia (built from source into `~/.local`)

Noctalia v5 is C++23 and no longer uses Quickshell. Upstream documents Ubuntu in
`BUILDING.md`: <https://github.com/noctalia-dev/noctalia>.

```bash
# libcurl4-gnutls-dev instead of upstream's libcurl4-openssl-dev: libqalculate-dev
# depends on the gnutls one and the two conflict.
sudo apt install meson g++ just \
  libwayland-dev wayland-protocols libegl-dev libgles-dev \
  libfreetype-dev libfontconfig-dev libcairo2-dev libpango1.0-dev libharfbuzz-dev \
  libxkbcommon-dev libglib2.0-dev libsecret-1-dev libsodium-dev \
  libsdbus-c++-dev libpipewire-0.3-dev libwireplumber-0.5-dev libpam0g-dev \
  libpolkit-agent-1-dev libpolkit-gobject-1-dev libcurl4-gnutls-dev libwebp-dev \
  libjxl-dev libsndfile1-dev librsvg2-dev libqalculate-dev libxml2-dev libmd4c-dev \
  libtomlplusplus-dev libical-dev nlohmann-json3-dev libstb-dev libjemalloc-dev \
  upower gnome-keyring

git clone --depth 1 https://github.com/noctalia-dev/noctalia
cd noctalia
just configure release "$HOME/.local"   # prefix ~/.local, so no sudo for install
just build release                      # LTO build, takes a few minutes
just install release                    # ~/.local/bin/noctalia + ~/.local/share/noctalia
```

Upstream also publishes a Debian/Ubuntu apt repo with a build for 26.04
(`https://pkg.noctalia.dev/deb/noctalia-resolute.sources`, found in the upstream docs, not
tried here). It would give `apt upgrade` updates instead of rebuilding by hand.

Uninstall: `just uninstall release` from the same build directory.

### Config

- Hand-written config goes in `~/.config/noctalia/*.toml` (empty so far, defaults are used).
- The settings GUI (`Super+,`) writes `~/.local/state/noctalia/settings.toml`. That file is
  managed by the app and is not tracked here.
- Themes: 10 built-in palettes plus a community gallery (`api.noctalia.dev/palettes`, 100+
  palettes). Pick one in the GUI, or in a `.toml`:
  `[theme] source = "community"`, `community_palette = "Tokyo Night Storm"`.
- The `hyprland` template can push the palette into Hyprland border colors
  (`[theme.templates] enable_builtin_templates = true`, `builtin_ids = ["hyprland"]`).
  Not enabled here.

### Hyprland side

All in `../hyprland/hyprland.lua`: autostart, `noctalia msg` keybinds (launcher, control
center, settings, volume keys), blur/no-animation layer rules for the `noctalia-*`
namespaces and a float rule for its settings window.

## HyprMod

```bash
sudo apt install python3-dev libgirepository-2.0-dev lua5.4   # first two build pycairo/pygobject
curl -LsSf https://raw.githubusercontent.com/BlueManCZ/hyprmod/main/install.sh -o hyprmod-install.sh
less hyprmod-install.sh                                # read it first
sh hyprmod-install.sh                                  # uv tool install + desktop entry
```

`lua5.4` is required at runtime when the Hyprland config is Lua: without it HyprMod opens
a blank white window and logs `LuaReaderError: the lua interpreter is required`.

Project: <https://github.com/BlueManCZ/hyprmod>. It writes only its own
`hyprland-gui.lua`, which `hyprland.lua` loads with `require("hyprland-gui")`. That file is
empty until you save a change in HyprMod. Uninstall: `hyprmod --uninstall` then
`uv tool uninstall hyprmod`.
