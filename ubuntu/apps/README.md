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

## Notes

- Ubuntu installs the `fd` binary as `fdfind`; yazi expects `fd`. The installer
  symlinks `~/.local/bin/fd -> fdfind` to bridge this.
- ghostty's `.deb` is release-specific (`amd64_24.04.deb`); the `{UBUNTU}`
  token in its spec is filled from `/etc/os-release` at install time.
- Adding an app: add a `name="method:spec"` entry to the `APPS` map in
  [`install.sh`](install.sh) and a row above. Methods:
  `deb:owner/repo:asset`, `debfile:URL`, `script:URL`, `script-sudo:URL`,
  `flatpak:app.id`, `custom:function`.

## Left out on purpose

- **snap:** firefox, thunderbird — ship with Ubuntu by default, so no need to
  reinstall them.
