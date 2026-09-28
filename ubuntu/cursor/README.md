# Cursor on the nuc

Two local fixes: the agent sandbox AppArmor profile (below) and a launcher that survives eGPU unplugs
([further down](#cursor-launcher-gray-window--no-window-after-unplugging-the-egpu)).

## Sandbox AppArmor fix

Cursor's agent terminal sandbox (`cursorsandbox`: Landlock + seccomp + bubblewrap/user
namespaces) does not start on Ubuntu 26.04 (AppArmor 4): "Terminal sandbox could not start".
The profile Cursor ships in `/etc/apparmor.d/cursor-sandbox` is incomplete. Three edits fix it:

- uncomment `userns,` (all three profiles)
- add `capability dac_override,` (all three; `newuidmap`/`newgidmap` are denied it otherwise,
  see `sudo journalctl -k | grep cursor_sandbox`)
- widen the `cursor_sandbox_agent_cli` path so it also matches the copy of the helper that
  Cursor's agent-worker extension installs under
  `~/.config/Cursor/User/globalStorage/anysphere.cursor-agent-worker/agent-cli/.local/share/cursor-agent/`.
  The shipped pattern only covers `~/.local/share/cursor-agent/`, so the worker's helper ran
  under Ubuntu's generic `unprivileged_userns` profile, which denies `net_admin`
  ("loopback setup failed ... Operation not permitted").

The Cursor package overwrites that file on every upgrade (it is not a dpkg conffile), so
`cursor-apparmor-fix` reapplies the edits and an apt hook runs it after every dpkg run.
It is idempotent: it only rewrites the file and reloads the profile when an edit is missing,
and does nothing if Cursor ever ships a fixed profile.

### Install (needs sudo)

```bash
sudo install -m 0755 ubuntu/cursor/cursor-apparmor-fix /usr/local/sbin/cursor-apparmor-fix
sudo install -m 0644 ubuntu/cursor/99cursor-apparmor-fix /etc/apt/apt.conf.d/99cursor-apparmor-fix
sudo cursor-apparmor-fix        # apply now (silent if already patched)
```

Also make sure Cursor's apt repo is enabled after a release upgrade:
`/etc/apt/sources.list.d/cursor.sources` must not say `Enabled: no`.

### Check

```bash
grep -n 'userns\|dac_override' /etc/apparmor.d/cursor-sandbox     # 3x userns, 3x dac_override
grep -c 'agent-cli/}' /etc/apparmor.d/cursor-sandbox                # 2 (worker path, header + rule)
H=/usr/share/cursor/resources/app/resources/helpers/cursorsandbox
echo '{"sandbox":{"type":"workspace_readonly","cwd":"/tmp"},"networkPolicyStrict":false}' > /tmp/p.json
$H --preflight-only --policy /tmp/p.json -- true; echo $?          # 0 = sandbox works
```

### Uninstall

```bash
sudo rm /usr/local/sbin/cursor-apparmor-fix /etc/apt/apt.conf.d/99cursor-apparmor-fix
```

## Cursor launcher: gray window / no window after unplugging the eGPU

Symptom: Cursor starts (processes run) but shows no window under Wayland, or a gray,
"unresponsive" window under XWayland. It happens even with a fresh profile, and `--disable-gpu` makes it go away.

Cause: after the eGPU (RTX 3060) is unplugged, the nvidia modules stay loaded but wedged
(`dmesg` repeats `nvidia-modeset: ERROR: GPU:0: Error while waiting for GPU progress`).
Chromium's GPU process opens every EGL/Vulkan driver at startup, and opening nvidia's blocks
forever in `nvkms_open_common` (`cat /proc/<gpu-process-pid>/wchan`). The renderer waits on
the GPU process, so the workbench never loads. Hiding only nvidia's EGL vendor isn't enough;
Vulkan has to be restricted too.

`cursor` (install to `~/.local/bin`, which comes before `/usr/bin` in `PATH`) hides the
nvidia EGL/GLX/Vulkan drivers so Cursor always renders on the Intel iGPU, and runs it under
XWayland (`--ozone-platform=x11`). `cursor agent ...` is passed through untouched.
`cursor.desktop` is the shipped entry with `Exec` pointed at the wrapper, so app launchers
use it too.

### Install

```bash
install -m 0755 ubuntu/cursor/cursor ~/.local/bin/cursor
install -m 0644 ubuntu/cursor/cursor.desktop ~/.local/share/applications/cursor.desktop
rehash                                   # in already-open zsh shells
noctalia --daemon                        # restart Noctalia: it caches .desktop entries
```

`cursor.desktop` is a copy of `/usr/share/applications/cursor.desktop`. If a Cursor update
changes the shipped entry, re-copy it and point both `Exec=` lines at `/home/devniel/.local/bin/cursor`.

### Check

```bash
ps -eo args | grep -m1 -- '--type=gpu-process.*ozone-platform=x11'   # launched via the wrapper
for p in $(pgrep -f 'cursor --type=gpu-process'); do cat /proc/$p/wchan; echo; done   # not nvkms_*
```

If Cursor still won't open, check for a leftover windowless instance: processes exist but
`hyprctl clients | grep 'class: cursor'` is empty. New launches just hand off to it, so kill it
first. Other apps that start while nvidia is wedged can hang the same way; unload the modules
(`sudo modprobe -r nvidia_drm nvidia_modeset nvidia_uvm nvidia`) or reboot.
