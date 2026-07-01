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
   ```

3. i3 launches it via `exec_always --no-startup-id ~/.config/polybar/grayblocks/launch.sh`.

## What was customized (vs upstream)

- **`grayblocks/config.ini`** — added a `[module/i3]` block and put `i3` in
  `modules-left` (upstream ships without an i3 workspaces module).
- **`grayblocks/colors.ini`** — `primary = #546e7a` (upstream: `#e53935`).
- **`grayblocks/scripts/rofi/colors.rasi`** — accent `ac` set to `#546e7aFF`
  to match the primary color.
