#!/usr/bin/env bash
# End-to-end test of the hint, run against throwaway tmux servers.
#
# tmux only shows the hint to a real attached client, so an "outer" server runs
# a terminal with a client attached to the "inner" server under test. Keys are
# typed into the outer server and land in that client, like a real keyboard.
#
# The inner server loads a copy of the plugin whose hint.sh is wrapped to log
# every run, so we can check the trigger stays quiet while idle.

socket=twk-test-$$
tmp=$(mktemp -d)
failed=0

inner() { tmux -L "$socket" "$@"; }
outer() { tmux -L "$socket-out" "$@"; }

cleanup() {
  local socket_path
  socket_path=$(inner display -p '#{socket_path}')
  outer kill-server
  inner kill-server
  rm -rf "$tmp" "$socket_path" "$socket_path-out"
}
trap cleanup EXIT

# check <description> <command>: run the command and print ok or FAIL.
check() {
  if eval "$2"; then
    echo "ok   $1"
  else
    echo "FAIL $1"
    failed=1
  fi
}

# on_screen <text>: the outer terminal currently shows <text>.
on_screen() { outer capture-pane -p | grep -q "$1"; }

# pane_count_is <n>: the inner server has exactly <n> panes in total.
pane_count_is() { [ "$(inner list-panes -a | wc -l)" -eq "$1" ]; }

# --- Setup ---------------------------------------------------------------------

# Copy the plugin and wrap hint.sh so every run is logged to $tmp/runs.
cd "$(dirname "$0")/.." || exit 1
cp -R twhich-key.tmux scripts "$tmp"
mv "$tmp/scripts/hint.sh" "$tmp/scripts/real-hint.sh"
cat > "$tmp/scripts/hint.sh" <<EOF
#!/bin/sh
echo >> "$tmp/runs"
exec "$tmp/scripts/real-hint.sh" "\$@"
EOF
chmod +x "$tmp/scripts/hint.sh"
echo "run-shell $tmp/twhich-key.tmux" > "$tmp/tmux.conf"

outer -f /dev/null new -d -x 150 -y 42 "TERM=xterm-256color tmux -L $socket -f $tmp/tmux.conf new -s test sh"
sleep 1

# --- Tests ---------------------------------------------------------------------

outer send-keys C-b
sleep 1
check 'C-b and a pause shows the prefix hint' \
  'pane_count_is 2 && on_screen "│ prefix  " && on_screen "│ Tab     Switch to a window"'

outer send-keys g
sleep 1
check 'g switches it to the move table' \
  'pane_count_is 2 && on_screen "│ move  " && on_screen "Move pane to top  "'

outer send-keys Escape
sleep 1
check 'the hint closes back in root' \
  'pane_count_is 1 && [ -z "$(inner show -gqv @twhich-key-hint)" ]'

outer send-keys C-b c
sleep 1
check 'a fast C-b c creates a window and shows no hint' \
  'pane_count_is 2 && ! on_screen "│ prefix"'

inner split-window
outer send-keys C-b
sleep 1
outer send-keys z
sleep 1
check 'C-b z still zooms the active pane, and closing the hint keeps the zoom' \
  'pane_count_is 3 && [ "$(inner display -p "#{window_zoomed_flag}")" = 1 ]'

inner source-file "$tmp/tmux.conf"
inner source-file "$tmp/tmux.conf"
check 're-sourcing does not duplicate the trigger' \
  '[ "$(inner show -gv status-right | grep -o hint.sh | wc -l)" -eq 1 ]'

# Redraw the status line every second and churn windows, without the prefix.
: > "$tmp/runs"
inner set -g status-interval 1
for _ in 1 2 3; do
  inner new-window
  inner select-window -t :0
  sleep 1
done
check 'idle produces no runs' '[ ! -s "$tmp/runs" ]'

exit $failed
