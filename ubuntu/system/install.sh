#!/usr/bin/env bash
#
# install.sh — install machine-level systemd units and their helper scripts.
#
# Unlike the top-level update.sh (which snapshots configs out of $HOME), this
# covers config that lives outside $HOME entirely: /etc/systemd/system and
# /usr/local/sbin. The repo is the source of truth; this pushes it to the
# system. Needs sudo. Idempotent — re-running refreshes and re-enables.
#
#   ./ubuntu/system/install.sh                    # install everything applicable
#   ./ubuntu/system/install.sh e1000e-watchdog    # only the named units
#   ./ubuntu/system/install.sh --force            # skip hardware guards
#
# These units are hardware-specific (see the GUARDS map). On a machine without
# the matching hardware they're skipped rather than installed, so this is safe
# to run on any box the dotfiles land on.
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# unit -> guard function. A unit with no entry installs unconditionally.
declare -A GUARDS=(
  [eno1-offload]="have_i219"
  [e1000e-watchdog]="have_i219"
)

# The TX-hang workaround only applies to the NUC's onboard Intel I219-V on
# e1000e. Installing it elsewhere would disable offloads on an unrelated NIC.
have_i219() {
  [ -e /sys/class/net/eno1 ] || return 1
  [ "$(basename "$(readlink -f /sys/class/net/eno1/device/driver)" 2>/dev/null)" = e1000e ] || return 1
  lspci -nn 2>/dev/null | grep -qi "I219"
}

install_unit() {
  local name="$1" guard="${GUARDS[$1]:-}"

  if [ -n "$guard" ] && ! "$guard"; then
    echo ":: $name — hardware not present, skipping (--force to override)"
    return 0
  fi

  # A unit may ship a same-named helper script in sbin/.
  if [ -f "$here/sbin/$name.sh" ]; then
    echo ":: $name — installing /usr/local/sbin/$name.sh"
    sudo install -m 0755 "$here/sbin/$name.sh" "/usr/local/sbin/$name.sh"
  fi

  echo ":: $name — installing /etc/systemd/system/$name.service"
  sudo install -m 0644 "$here/units/$name.service" "/etc/systemd/system/$name.service"
  NEED_RELOAD=1
}

main() {
  local force=0 targets=()
  for arg in "$@"; do
    case "$arg" in
      --force) force=1 ;;
      *)       targets+=("$arg") ;;
    esac
  done
  [ "$force" = 1 ] && GUARDS=()

  if [ ${#targets[@]} -eq 0 ]; then
    for u in "$here"/units/*.service; do targets+=("$(basename "$u" .service)"); done
  fi

  NEED_RELOAD=0
  for name in "${targets[@]}"; do
    [ -f "$here/units/$name.service" ] || { echo "!! unknown unit: $name" >&2; continue; }
    install_unit "$name"
  done

  if [ "$NEED_RELOAD" = 1 ]; then
    sudo systemctl daemon-reload
    for name in "${targets[@]}"; do
      [ -f "/etc/systemd/system/$name.service" ] || continue
      sudo systemctl enable --now "$name.service"
    done
  fi
  echo ":: done"
}

main "$@"
