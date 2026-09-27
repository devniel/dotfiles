# Chrome on the nuc

`google-chrome-stable` (the wrapper below) works around two separate issues.

## Dialogs render detached from the browser

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
handles it correctly there), so the wrapper adds `--ozone-platform=x11`.

## Windows come up fully transparent

With only `--ozone-platform=x11` (no GPU vendor override), Chrome windows mapped but
rendered fully transparent — visible chrome (toolbar/tabs) but no page content ever
painted. Same underlying cause as the eGPU/nvidia-wedge issue Cursor hits
(`../cursor/README.md`): after the eGPU is unplugged, the nvidia driver stays loaded but
wedged (`dmesg`: `nvidia-modeset: ERROR: GPU:0: Error while waiting for GPU progress`,
`nvidia-smi`: `No devices were found` despite the card still showing in `lspci`).
libglvnd prefers nvidia's EGL vendor file by default (`10_nvidia.json` sorts before
`50_mesa.json` in `/usr/share/glvnd/egl_vendor.d/`), so without hiding it Chrome's GPU
process picks nvidia and the GL context never actually renders. The wrapper hides the
nvidia EGL/GLX/Vulkan drivers the same way `~/.local/bin/cursor` does, so Chrome renders
on the Intel iGPU instead.

(Checked and ruled out first, before finding this: Chrome's GPU process itself was idle
at the time, not blocked in `nvkms_*` the way Cursor's was — the wedge only bites once a
GL context is actually initialized, which happens on window creation.)

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

Open a new window and confirm it actually paints (not just a bare toolbar with a
transparent page area) before trusting the fix.
