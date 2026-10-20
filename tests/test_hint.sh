#!/usr/bin/env bash
# An outer tmux server runs a real client of an inner server that loads a copy of the plugin whose hint.sh counts its runs.
s=twk-test-$$ d=$(mktemp -d) fail=0
trap 'tmux -L $s-out kill-server; tmux -L $s kill-server; rm -rf "$d"' EXIT
cd "$(dirname "$0")/.." && cp -R twhich-key.tmux scripts "$d" && mv "$d/scripts/hint.sh" "$d/scripts/real.sh"
printf '#!/bin/sh\necho >> %s/runs; exec %s/scripts/real.sh "$@"\n' "$d" "$d" > "$d/scripts/hint.sh" && chmod +x "$d/scripts/hint.sh"
echo "run-shell $d/twhich-key.tmux" > "$d/conf"
I() { tmux -L $s "$@"; }
O() { tmux -L $s-out "$@"; }
ok() { if eval "$2"; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi; }
screen() { O capture-pane -p | grep -q "$1"; }
panes() { [ "$(I list-panes -a | wc -l)" -eq "$1" ]; }

O -f /dev/null new -d -x 150 -y 42 "TERM=xterm-256color tmux -L $s -f $d/conf new -s t sh"; sleep 1
O send-keys C-b; sleep 1
ok 'C-b and a pause shows the prefix hint' 'panes 2 && screen "│ prefix  " && screen "│ Tab     Switch to a window"'
O send-keys g; sleep 1
ok 'g switches it to the move table' 'panes 2 && screen "│ move  " && screen "Move pane to top  "'
O send-keys Escape; sleep 1
ok 'the hint closes back in root' 'panes 1 && [ -z "$(I show -gqv @twhich-key-hint)" ]'
O send-keys C-b c; sleep 1
ok 'a fast C-b c creates a window and shows no hint' 'panes 2 && ! screen "│ prefix"'
I split-window; O send-keys C-b; sleep 1; O send-keys z; sleep 1
ok 'C-b z still zooms the active pane, and closing the hint keeps the zoom' 'panes 3 && [ "$(I display -p "#{window_zoomed_flag}")" = 1 ]'
I source-file "$d/conf"; I source-file "$d/conf"
ok 're-sourcing does not duplicate the trigger' '[ "$(I show -gv status-right | grep -o hint.sh | wc -l)" -eq 1 ]'
: > "$d/runs"; I set -g status-interval 1
for _ in 1 2 3; do I new-window; I select-window -t :0; sleep 1; done
ok 'idle produces no runs' '[ ! -s "$d/runs" ]'
exit $fail
