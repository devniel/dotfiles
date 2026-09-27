# Chrome on the nuc

Chrome's dialogs (file picker, print preview, permission prompts, JS alert/confirm)
render detached from the browser under native Wayland: the page dims as if a modal is
open, but the dialog itself appears somewhere else (or not visibly at all). Hyprland
doesn't correctly implement dialog centering for Wayland clients — it advertises the
wrong `xdg-dialog-v1` global name and its fallback "smart placement" drops new windows
in a screen corner instead of over their parent
([hyprwm/Hyprland#9498](https://github.com/hyprwm/Hyprland/issues/9498),
[#2830](https://github.com/hyprwm/Hyprland/issues/2830),
[#3335](https://github.com/hyprwm/Hyprland/issues/3335)).

XWayland's mature transient-for window parenting sidesteps the bug entirely (Hyprland
handles it correctly there), so `google-chrome-stable` (the wrapper below) launches
Chrome with `--ozone-platform=x11`.

Ruled out first: this isn't the same eGPU/nvidia-wedge issue Cursor hits
(`../cursor/README.md`) — Chrome's GPU process here was idle and using the Intel iGPU
render node, not blocked on `nvkms_*`.

## Install

```bash
mkdir -p ~/.local/bin ~/.local/share/applications
cp ubuntu/chrome/google-chrome-stable ~/.local/bin/google-chrome-stable
chmod +x ~/.local/bin/google-chrome-stable
cp ubuntu/chrome/google-chrome.desktop ~/.local/share/applications/google-chrome.desktop
update-desktop-database ~/.local/share/applications
```

`~/.local/bin` must be ahead of `/usr/bin` in `$PATH` (already true on this machine) so
the wrapper shadows the real binary for bare `google-chrome-stable` invocations — the
Hyprland `Super+B` bind included. The `.desktop` override covers launches through
Noctalia's dock/launcher, which resolve the app by its absolute `Exec` path rather than
`$PATH`. Noctalia caches `.desktop` entries, so restart it
(`pkill -x noctalia && noctalia --daemon`) after installing this for the first time.

The `.desktop` file's `Exec` lines hardcode `/home/devniel/.local/bin/...` — update the
username if restoring on a different account.

## Check

```bash
command -v google-chrome-stable   # should resolve to ~/.local/bin/google-chrome-stable
ps -eo args | grep -o 'ozone-platform=[a-z0-9]*' | sort -u   # x11, once Chrome is running
```
