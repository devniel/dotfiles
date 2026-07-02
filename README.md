My dotfiles.

## Notes

### Terminal keys emitting garbage like `5;7u`

If the keyboard starts printing sequences like `5;7u0;7u5;7u` instead of the
keys you press, the terminal is stuck in the **kitty keyboard protocol**
("CSI u" mode). A TUI (usually Claude Code) enabled it and didn't restore
state on an abrupt exit.

- **Recover:** run `reset`, or `printf '\e[<u'`. If input is too garbled to
  type, open a new Ghostty tab/window (or use its command palette →
  `Reset`) and close the stuck one.
