#!/bin/bash
# Recover eno1 from the I219-V e1000e TX "Hardware Unit Hang".
#
# The driver logs the hang but never resets the adapter, and the link stays
# UP, so nothing upstream notices. Bouncing the link reinitialises the TX
# ring, which is what an unplug/replug does by hand.

set -uo pipefail

IFACE=eno1
COOLDOWN=120   # seconds to ignore further hangs after a bounce

last=0

journalctl -kf -n0 -o cat | while read -r line; do
    [[ $line == *"$IFACE: Detected Hardware Unit Hang"* ]] || continue

    now=$(date +%s)
    # The hang is logged every 2s, and journalctl buffers a backlog while we
    # bounce. The cooldown uses wall-clock time, so stale lines are dropped.
    (( now - last < COOLDOWN )) && continue
    last=$now

    logger -t e1000e-watchdog "TX hang on $IFACE - bouncing link"
    /usr/sbin/ip link set "$IFACE" down
    sleep 2
    /usr/sbin/ip link set "$IFACE" up
    logger -t e1000e-watchdog "$IFACE link bounced"
done
