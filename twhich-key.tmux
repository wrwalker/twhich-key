#!/usr/bin/env bash
case $(tmux -V) in *" "[0-2].*|*" 3."[0-7]|*" 3."[0-7][!0-9]*) exec tmux display-message "twhich-key needs tmux 3.8+" ;; esac
dir=$(cd "$(dirname "$0")" && pwd)
# Runs hint.sh when the client's key table or window changes, and while a hint is open (to close it back in root).
t="#{?#{||:#{!=:#{client_key_table},root},#{@twhich-key-hint}},#('$dir/scripts/hint.sh' #{client_key_table} #{client_name} #{window_id}),}"
r=$(tmux show -gv status-right)
case $r in *"$t"*) ;; *) tmux set -g status-right "$t$r" ;; esac
