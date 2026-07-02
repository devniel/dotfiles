# polybar

The bar is the **grayblocks** theme from [adi1090x/polybar-themes](https://github.com/adi1090x/polybar-themes)
(the `simple` variant). Only the files I customized are tracked here — everything
else is unmodified upstream and should be restored from the theme pack.

## Restore on a new machine

1. Install the theme pack (this drops the full grayblocks theme into
   `~/.config/polybar/`):

   ```bash
   git clone https://github.com/adi1090x/polybar-themes.git
   cd polybar-themes && ./setup.sh   # choose the "simple" style
   ```

2. Overlay the customized files from this repo:

   ```bash
   cp ubuntu/polybar/grayblocks/config.ini              ~/.config/polybar/grayblocks/config.ini
   cp ubuntu/polybar/grayblocks/colors.ini              ~/.config/polybar/grayblocks/colors.ini
   cp ubuntu/polybar/grayblocks/scripts/rofi/colors.rasi ~/.config/polybar/grayblocks/scripts/rofi/colors.rasi
   cp ubuntu/polybar/setup-1400.sh                       ~/.config/polybar/setup-1400.sh
   chmod +x ~/.config/polybar/setup-1400.sh
   ```

3. i3 launches the full-width bar via `exec_always --no-startup-id ~/.config/polybar/grayblocks/launch.sh`.

## Narrow (1400px) bar

`config.ini` targets a 1400px-wide bar via `monitor = DP-1-right` — a virtual
monitor. Run **`~/.config/polybar/setup-1400.sh`** to create that virtual
monitor (1400px, right-flush at x=520) and (re)launch polybar into it;
`setup-1400.sh --reset` removes it and falls back to the full-width 1920px bar.

Why a virtual monitor: under i3, dock bars are stretched to the output width, so
a narrow bar needs a narrow output. `monitor = DP-1-right` also makes polybar lay
out its modules for 1400px — without it the right-side modules (clock, tray) are
computed for 1920px and get clipped off the visible edge. It's a manual script,
not wired into i3 autostart; if the virtual monitor is absent polybar just
renders full-width.

## What was customized (vs upstream)

- **`grayblocks/config.ini`** — added a `[module/i3]` block and put `i3` in
  `modules-left` (upstream ships without an i3 workspaces module); set
  `monitor = DP-1-right`, `fixed-center = false`, and `pin-workspaces = false`
  to support the 1400px virtual-monitor bar (see above) without clipping modules.
- **`grayblocks/colors.ini`** — `primary = #546e7a` (upstream: `#e53935`).
- **`grayblocks/scripts/rofi/colors.rasi`** — accent `ac` set to `#546e7aFF`
  to match the primary color.
- **`setup-1400.sh`** — creates the `DP-1-right` virtual monitor and launches the
  1400px bar (`--reset` reverts to full-width).
