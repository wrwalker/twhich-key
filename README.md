# twhich-key
A plugin for tmux that functions like which key in neovim. What separates this apart is that it doesn't inject it's own opinion on keyboard shortcuts, and works integrated directly with tmux instead of creating its own menu and list of shortcuts. We're exposing the raw tmux list-keys (?) shortcuts in a popup after each button you press.

We trigger off of the conditional status-line trigger.
