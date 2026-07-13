#!/usr/bin/env bash
#
# install.sh — symlink every tool in tools/bin/ into ~/bin (already on PATH).
#
# Unlike the repo's top-level update.sh (which snapshots configs from $HOME
# into the repo), tools flow the other way: the repo is the source of truth
# and ~/bin points back at it, so edits here are live immediately.
#
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${HOME}/bin"
mkdir -p "$dest"

for tool in "$here"/bin/*; do
  [ -f "$tool" ] || continue
  chmod +x "$tool"
  name="$(basename "$tool")"
  ln -sf "$tool" "$dest/$name"
  echo "linked $dest/$name -> $tool"
done

case ":$PATH:" in
  *":$dest:"*) ;;
  *) echo "note: $dest is not on your PATH — add 'export PATH=\$HOME/bin:\$PATH' to your shell rc" >&2 ;;
esac
