# apps

Apps that don't come from the stock Ubuntu repos. Their *configs* (when they
have one worth tracking) are snapshotted by the top-level `update.sh` — e.g.
`ubuntu/yazi/`, `ubuntu/ghostty/`. This dir records *which* apps a fresh
machine needs and *how* each is installed.

## Install

```sh
./ubuntu/apps/install.sh                 # install/upgrade everything
./ubuntu/apps/install.sh yazi ghostty    # only the named apps
```

Idempotent — re-running upgrades each app to its current release.

## Apps

| App | What it is | Method | Config |
|-----|------------|--------|--------|
| [ghostty](https://ghostty.org/) | GPU-accelerated terminal emulator. | GitHub `.deb` ([mkasberg/ghostty-ubuntu](https://github.com/mkasberg/ghostty-ubuntu)) | `ubuntu/ghostty/` |
| [yazi](https://yazi-rs.github.io/) | Terminal file manager. Pulls in `fd`, `ripgrep`, `fzf`, `ffmpeg`, `imagemagick`, `zoxide`. | GitHub `.deb` | `ubuntu/yazi/` |
| [glow](https://github.com/charmbracelet/glow) | Render & page Markdown in the terminal. | GitHub `.deb` | — |
| [tailscale](https://tailscale.com/) | WireGuard-based mesh VPN (client + daemon). | vendor script → apt repo | — |
| [trayscale](https://github.com/DeedleFake/trayscale) | GTK tray GUI for the Tailscale client. | Flatpak | — |
| [deskflow](https://deskflow.org/) | Share one keyboard/mouse across machines (KVM). | Flatpak | — |
| [input-leap](https://github.com/input-leap/input-leap) | KVM software (deskflow's predecessor). | Flatpak | — |
| [docker](https://docs.docker.com/engine/) | Container engine (`docker-ce` + compose/buildx plugins). | `get.docker.com` script | — |
| [terraform](https://www.terraform.io/) | Infrastructure as code. | HashiCorp apt repo | — |
| [azure-cli](https://learn.microsoft.com/cli/azure/) | Azure command line (`az`). | `aka.ms` script → apt repo | — |
| [vscode](https://code.visualstudio.com/) | Editor. | direct `.deb` (MS) | — |
| [google-chrome](https://www.google.com/chrome/) | Browser. | direct `.deb` (Google) | — |
| [cursor](https://cursor.com/) | AI code editor. | `custom:install_cursor` — resolves the current `.deb` via Cursor's download API | — |
| [nwg-displays](https://github.com/nwg-piotr/nwg-displays) | Monitor layout GUI (Hyprland/sway). | `custom:install_nwg_displays` — latest GitHub tag via `pipx` into `~/.local`, replacing the apt build | `ubuntu/hyprland/monitors.lua` |
| [paseo](https://github.com/getpaseo/paseo) | Paseo desktop app (Electron). | own script, [`paseo.sh`](paseo.sh): GitHub AppImage → `~/Applications` + app menu entry | — |
| [github-copilot](https://github.com/github/app) | GitHub Copilot desktop app (Tauri). | own script, [`github-copilot.sh`](github-copilot.sh): GitHub AppImage → `~/Applications` + app menu entry | — |

## Notes

- Ubuntu installs the `fd` binary as `fdfind`; yazi expects `fd`. The installer
  symlinks `~/.local/bin/fd -> fdfind` to bridge this.
- ghostty's `.deb` is release-specific (`amd64_24.04.deb`); the `{UBUNTU}`
  token in its spec is filled from `/etc/os-release` at install time.
- cursor's `.deb` asset URL is content-hashed and changes every release, so it
  can't use `debfile:` like vscode/chrome. `install_cursor` asks
  `cursor.com/api/download` for the current one instead.
- nwg-displays comes from GitHub, not apt: Ubuntu's 0.3.x only writes
  `monitors.conf`, which Hyprland's Lua config never reads, so Apply silently
  does nothing. 0.4.3+ writes `~/.config/hypr/monitors.lua`. It is installed
  with `pipx --system-site-packages` so it reuses the apt GTK/PyGObject/i3ipc
  bindings, and the apt package is removed so the two don't clash.
- Apps that need more than one step get their own script in this directory,
  wired in with `local:file.sh`. Each one also runs on its own
  (e.g. `./ubuntu/apps/paseo.sh`).
- AppImage apps ([`paseo.sh`](paseo.sh), [`github-copilot.sh`](github-copilot.sh))
  are one `appimage_install owner/repo asset name` call into the shared
  [`lib/appimage.sh`](lib/appimage.sh). It puts the AppImage in
  `~/Applications` under the release asset's name, so re-running replaces the
  old version in place, and makes sure FUSE 2 (`libfuse2t64`) is present, which
  AppImages need to run. It then writes `~/.local/share/applications/<name>.desktop`
  from the AppImage's own `.desktop` file and icon (following symlinks inside
  the AppImage), keeping its launch flags such as Electron's `--no-sandbox`, so
  the app shows up in the rofi launcher (**≡** on the bar).
- Adding an app: add a `name="method:spec"` entry to the `APPS` map in
  [`install.sh`](install.sh) and a row above. Methods:
  `deb:owner/repo:asset`, `debfile:URL`, `script:URL`, `script-sudo:URL`,
  `flatpak:app.id`, `local:file.sh`, `custom:function`.

## Left out on purpose

- **snap:** firefox, thunderbird — ship with Ubuntu by default, so no need to
  reinstall them.
