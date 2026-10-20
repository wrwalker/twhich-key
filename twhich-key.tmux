#!/usr/bin/env bash
# twhich-key setup, run once when tmux loads the plugin (by TPM or run-shell).
#
# tmux has no hook for key presses. But pressing the prefix (or entering any key
# table) redraws the status line, and a status-line #() job re-runs as soon as
# its expanded command changes. So we add a hidden job to status-right whose
# command includes #{client_key_table}: it runs hint.sh the moment the key table
# changes. The job prints nothing, so the status line looks the same.

plugin_dir=$(cd "$(dirname "$0")" && pwd)

# The hint is drawn in a floating pane, which needs tmux 3.8.
version=$(tmux -V)         # e.g. "tmux 3.8", "tmux 3.8a", "tmux next-3.9"
version=${version##*[ -]}  # "3.8a"
major=${version%%.*}
minor=${version#*.}
minor=${minor%%[!0-9]*}
if [ "$major" -lt 3 ] || { [ "$major" -eq 3 ] && [ "$minor" -lt 8 ]; }; then
  tmux display-message "twhich-key needs tmux 3.8 or newer"
  exit 0
fi

# Only expand the job while it's useful: while the client is in a key table, or
# while a hint is open (so the run back in root can close it). Idle, nothing runs.
in_key_table='#{!=:#{client_key_table},root}'
hint_open='#{@twhich-key-hint}'
run_hint="#('$plugin_dir/scripts/hint.sh' #{client_key_table} #{client_name} #{window_id})"
trigger="#{?#{||:$in_key_table,$hint_open},$run_hint,}"

# Prepend it so status-right-length can't cut it off, unless an earlier load
# (re-sourcing tmux.conf) already added it.
status_right=$(tmux show -gv status-right)
case $status_right in
  *"$trigger"*) ;;
  *) tmux set -g status-right "$trigger$status_right" ;;
esac
