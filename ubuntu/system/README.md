# system

Machine-level config that lives *outside* `$HOME` — systemd units in
`/etc/systemd/system` and helper scripts in `/usr/local/sbin`. The top-level
`update.sh` only snapshots `$HOME`, so it doesn't cover any of this.

Direction of flow is like `tools/`, not like `update.sh`: **the repo is the
source of truth** and `install.sh` pushes to the system.

## Install

```sh
./ubuntu/system/install.sh                    # everything applicable to this machine
./ubuntu/system/install.sh e1000e-watchdog    # only the named units
./ubuntu/system/install.sh --force            # skip hardware guards
```

Needs sudo. Idempotent. Units are hardware-guarded — on a machine without the
matching hardware they're **skipped, not installed**, so this is safe to run on
any box these dotfiles land on.

## Units

| Unit | What it does | Guard |
|------|--------------|-------|
| `eno1-offload` | Disables TSO/GSO on `eno1`. The actual fix for the NIC bug below. | onboard Intel I219 on `e1000e` |
| `e1000e-watchdog` | Watches the kernel log for the TX hang and bounces the link. Safety net. | same |

## The e1000e TX hang

The NUC's onboard **Intel I219-V (10)** NIC (`e1000e`, PCI `00:1f.6`) hits a
long-standing Intel erratum: the transmit ring wedges and the card stops
consuming descriptors. In the kernel log:

```
e1000e 0000:00:1f.6 eno1: Detected Hardware Unit Hang:
  TDH <e>                    <- hardware read position, frozen
  TDT <f8>                   <- kernel keeps queueing
  next_to_watch.status <0>   <- card never wrote back "done"
```

Two things make it especially nasty:

- **The driver never resets the adapter.** It logs the hang every 2s forever;
  `tx_timeout_count` stays `0`, so the netdev watchdog never fires.
- **`NIC Link` stays `Up`.** NetworkManager, Tailscale and everything upstream
  see a healthy interface, so nothing fails over. RX still works, so the box
  looks alive while being unreachable from outside.

Observed on the NUC before mitigation:

| Window | Duration | Ended by |
|--------|----------|----------|
| 2026-07-25 22:58 → 07-27 07:58 | **33 h** | unplugging the cable |
| 2026-07-29 09:47 → 09:48 | 88 s | link bounce |
| 2026-07-30 00:58 → 08:46 | **7.8 h** | applying `eno1-offload` |

### Why disabling TSO fixes it

TSO (TCP Segmentation Offload) has the NIC split a big buffer into ~1500-byte
packets in hardware, generating headers and sequence numbers itself. That
engine is what wedges. With TSO/GSO off the kernel hands the card pre-chopped
frames, so the buggy path never runs. Costs a few percent of one core at
1 Gb/s — irrelevant on this machine, and the bridges/veths used by the VMs and
containers aren't touched.

### Checking it

```sh
ethtool -k eno1 | grep segmentation     # both should read "off"
journalctl -k | grep "Hardware Unit Hang"
journalctl -t e1000e-watchdog           # watchdog activity
```

If the machine ever goes unreachable again, check those **before** suspecting
Tailscale or the network.

## Notes

- The watchdog debounces on wall-clock time (120 s), because the hang is logged
  every 2s and `journalctl -f` buffers a backlog while the link bounces.
- `ethtool -K` itself resets the adapter, so applying `eno1-offload` briefly
  bounces the link (~4 s). That's also why it clears a hang in progress.
- `eno1-offload` is bound to `sys-subsystem-net-devices-eno1.device` rather
  than a boot target, so it re-applies whenever the NIC appears — not just at
  boot.
- If TSO-off ever stops holding, the real fix is a USB3 or PCIe NIC; the I219
  erratum has no firmware fix.
- Adding a unit: drop `units/<name>.service` (plus an optional
  `sbin/<name>.sh`) and add a row above. Add a `GUARDS` entry in
  [`install.sh`](install.sh) if it's hardware-specific.
