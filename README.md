# twhich-key

[which-key](https://github.com/folke/which-key.nvim) for tmux: press the prefix (or a key like `C-b g`), pause, and a floating pane lists every key you can press next. No opinions: it shows tmux's own `list-keys`, live, and tmux still handles every key.

Requires tmux 3.8 with the status line on.

## Install

Load it after anything that sets `status-right`, such as a theme.

With [TPM](https://github.com/tmux-plugins/tpm):

```tmux
set -g @plugin 'wrwalker/twhich-key'
```

Manually:

```tmux
run-shell ~/path/to/twhich-key/twhich-key.tmux
```

## Options

```tmux
set -g @twhich-key-delay 300 # ms to wait before showing the hint
```

## Known issues

With the hint on screen:

- `C-b o` from the last pane cycles into the hint pane.
- `C-b C-o` / `M-o` (rotate) swap the hint into the tiled layout and leave a real pane floating.

## Possible features

- `F1` in copy mode opens a popup of copy-mode keys.
- A title showing the key sequence so far (`C-b g` instead of `move`).

## Development

```sh
./run_tests.sh
```
