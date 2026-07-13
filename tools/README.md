# tools

Small command-line utilities I reuse across machines. Each tool is a
standalone executable in [`bin/`](bin/) — a shell script today, or a compiled
binary (Go/Rust) later, with no change to how it's invoked.

## Install

```sh
./tools/install.sh
```

Symlinks everything in `tools/bin/` into `~/bin` (already on `PATH` via
[`zsh/.zshrc`](../zsh/.zshrc)). The repo stays the source of truth, so edits
here take effect immediately.

## Tools

| Tool | What it does |
|------|--------------|
| [`pem-inspect`](bin/pem-inspect) | Inspect a PEM key or certificate; auto-repairs flattened/single-line PEM first. `--fix` prints the re-wrapped PEM, `--write` fixes the file in place. Prefers [`step`](https://smallstep.com/cli/), falls back to `openssl`. |

## Adding a tool

1. Drop an executable in `bin/` (keep it POSIX-portable so it works on macOS + Linux).
2. Add a row to the table above.
3. Run `./tools/install.sh`.

When a tool outgrows a shell script, replace `bin/<tool>` with a compiled
binary of the same name — everything else stays the same.
