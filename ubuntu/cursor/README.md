# Cursor sandbox AppArmor fix

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

## Install (needs sudo)

```bash
sudo install -m 0755 ubuntu/cursor/cursor-apparmor-fix /usr/local/sbin/cursor-apparmor-fix
sudo install -m 0644 ubuntu/cursor/99cursor-apparmor-fix /etc/apt/apt.conf.d/99cursor-apparmor-fix
sudo cursor-apparmor-fix        # apply now (silent if already patched)
```

Also make sure Cursor's apt repo is enabled after a release upgrade:
`/etc/apt/sources.list.d/cursor.sources` must not say `Enabled: no`.

## Check

```bash
grep -n 'userns\|dac_override' /etc/apparmor.d/cursor-sandbox     # 3x userns, 3x dac_override
grep -c 'agent-cli/}' /etc/apparmor.d/cursor-sandbox                # 2 (worker path, header + rule)
H=/usr/share/cursor/resources/app/resources/helpers/cursorsandbox
echo '{"sandbox":{"type":"workspace_readonly","cwd":"/tmp"},"networkPolicyStrict":false}' > /tmp/p.json
$H --preflight-only --policy /tmp/p.json -- true; echo $?          # 0 = sandbox works
```

## Uninstall

```bash
sudo rm /usr/local/sbin/cursor-apparmor-fix /etc/apt/apt.conf.d/99cursor-apparmor-fix
```
