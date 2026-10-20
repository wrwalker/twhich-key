#!/usr/bin/env bash
# hint.sh <table> <client> [window]: show <table>'s keys in a floating pane on <client>'s window; root closes it.
# @twhich-key-hint is "<pane> <table> <client> <window>" while a hint is showing.
if [ "$1" = root ]; then
  read -r pane _ owner _ <<< "$(tmux show -gqv @twhich-key-hint)"
  # Keep it while its own client is still in a key table.
  case $(tmux list-clients -F '#{client_key_table}' -f "#{==:#{client_name},$owner}") in ""|root) ;; *) exit 0 ;; esac
  [ -n "$pane" ] && tmux kill-pane -t "$pane"
  exec tmux set -gu @twhich-key-hint
fi
d=$(tmux show -gqv @twhich-key-delay)
sleep "$((${d:-300} / 1000)).$(printf %03d $((${d:-300} % 1000)))"
read -r table win w h pane shown <<< "$(tmux display -p -c "$2" '#{client_key_table} #{window_id} #{window_width} #{window_height} #{@twhich-key-hint}')"
[ "$table" = "$1" ] && [ "$shown" != "$1 $2 $win" ] || exit 0
[ -n "$pane" ] && tmux kill-pane -t "$pane"
keys=$(tmux list-keys -Na -P '' -T "$1")
cols=$(( w / 38 > 1 ? w / 38 : 1 ))
rows=$(( ($(wc -l <<< "$keys") + cols - 1) / cols ))
rows=$(( rows < h - 3 ? rows : h - 3 ))
body=" $1"$'\n'$(head -n $((rows * cols)) <<< "$keys" | pr -t -$cols -l $rows -w $((w - 2)))
pane=$(tmux new-pane -dA -t "$win" -x "$w" -y $((rows + 3)) -X 0 -Y $((h - rows - 3)) -P -F '#{pane_id}' sh -c 'printf %s "$0"; exec cat' "$body") &&
  tmux set -g @twhich-key-hint "$pane $1 $2 $win"
