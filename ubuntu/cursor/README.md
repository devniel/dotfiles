# Cursor sandbox AppArmor fix

Cursor's agent terminal sandbox (`cursorsandbox`: Landlock + seccomp + bubblewrap/user
namespaces) does not start on Ubuntu 26.04 (AppArmor 4): "Terminal sandbox could not start".
The profile Cursor ships in `/etc/apparmor.d/cursor-sandbox` is incomplete. Two edits fix it,
applied to all three profiles in that file:

- uncomment `userns,`
- add `capability dac_override,` (`newuidmap`/`newgidmap` are denied it otherwise; see
  `sudo journalctl -k | grep cursor_sandbox`)

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
H=/usr/share/cursor/resources/app/resources/helpers/cursorsandbox
echo '{"sandbox":{"type":"workspace_readonly","cwd":"/tmp"},"networkPolicyStrict":false}' > /tmp/p.json
$H --preflight-only --policy /tmp/p.json -- true; echo $?          # 0 = sandbox works
```

## Uninstall

```bash
sudo rm /usr/local/sbin/cursor-apparmor-fix /etc/apt/apt.conf.d/99cursor-apparmor-fix
```
