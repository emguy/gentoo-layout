#!/bin/sh

PID=$(pgrep -u "$USER" -x sway | sort -n | head -1)
SOCK="$XDG_RUNTIME_DIR/sway-ipc.$UID.$PID.sock"
if [ -S "$SOCK" ] && swaymsg -s "$SOCK" -t get_tree | jq -e '..|select(.focused?).app_id == "firefox"' >/dev/null 2>&1; then
  wtype -M ctrl v
else
  wtype -M logo v
fi
