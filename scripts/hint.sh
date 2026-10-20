#!/usr/bin/env bash
# Shows or closes the hint. Run by the status-line trigger from twhich-key.tmux:
#
#   hint.sh <key-table> <client> <window>
#
# Any key table other than root shows that table's keys in a floating pane at
# the bottom of the client's window. root closes the hint.
#
# While a hint is showing, the global option @twhich-key-hint holds
# "<pane> <key-table> <client> <window>".

table=$1
client=$2

hint_state() {
  tmux show -gqv @twhich-key-hint
}

kill_hint_pane() {
  local pane
  read -r pane _ <<< "$(hint_state)"
  if [ -n "$pane" ]; then
    tmux kill-pane -t "$pane"
  fi
}

# --- Back in root: close the hint ---------------------------------------------

if [ "$table" = root ]; then
  # Every client that returns to root runs this, so only close the hint if the
  # client that opened it is gone or is also back in root.
  read -r _ _ owner _ <<< "$(hint_state)"
  owner_table=$(tmux list-clients -F '#{client_key_table}' -f "#{==:#{client_name},$owner}")
  if [ -n "$owner_table" ] && [ "$owner_table" != root ]; then
    exit 0
  fi
  kill_hint_pane
  tmux set -gu @twhich-key-hint
  exit 0
fi

# --- In a key table: show the hint --------------------------------------------

# Wait first (like LazyVim's timeoutlen), so fast key sequences never flash it.
delay_ms=$(tmux show -gqv @twhich-key-delay)
delay_ms=${delay_ms:-300}
sleep "$(( delay_ms / 1000 )).$(printf '%03d' $(( delay_ms % 1000 )))"

# Stop if the client left the table while we waited, or this hint is already up.
# The last field is @twhich-key-hint minus its pane: "<key-table> <client> <window>".
read -r current_table window width height _ shown <<< "$(tmux display -p -c "$client" \
  '#{client_key_table} #{window_id} #{window_width} #{window_height} #{@twhich-key-hint}')"
if [ "$current_table" != "$table" ] || [ "$shown" = "$table $client $window" ]; then
  exit 0
fi

# Lay the keys out in columns about 38 characters wide, with as many rows as
# needed, capped so the pane (rows + a title line + 2 border lines) fits.
keys=$(tmux list-keys -Na -P '' -T "$table")  # -a: include keys without a note
key_count=$(wc -l <<< "$keys")
columns=$(( width / 38 ))
if [ "$columns" -lt 1 ]; then columns=1; fi
rows=$(( (key_count + columns - 1) / columns ))
if [ "$rows" -gt $(( height - 3 )) ]; then rows=$(( height - 3 )); fi

kill_hint_pane
if [ "$rows" -lt 1 ]; then  # window too short to show anything
  tmux set -gu @twhich-key-hint
  exit 0
fi

# pr fills each column top to bottom and truncates entries that don't fit.
listing=$(head -n $(( rows * columns )) <<< "$keys" | pr -t -"$columns" -l "$rows" -w $(( width - 2 )))
body=" $table"$'\n'"$listing"

# -d keeps focus where it is, so the next key still goes to tmux.
# -A keeps the hint above a zoomed pane instead of unzooming the window.
# The pane prints the hint, then waits on cat until hint.sh kills it.
pane_height=$(( rows + 3 ))
pane=$(tmux new-pane -d -A -t "$window" -x "$width" -y "$pane_height" \
  -X 0 -Y $(( height - pane_height )) -P -F '#{pane_id}' \
  sh -c 'printf "%s" "$1"; exec cat' sh "$body") || exit 1
tmux set -g @twhich-key-hint "$pane $table $client $window"
