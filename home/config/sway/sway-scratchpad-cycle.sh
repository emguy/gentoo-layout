#!/bin/sh
tree=$(swaymsg -t get_tree) || exit 1

focused=$(printf '%s\n' "$tree" | jq -r '
  .. | objects
  | select(.focused == true and .type == "con"
           and .floating == "auto_off"
           and .scratchpad_state == "none"
           and .pid != null)
  | .id' | head -n1)

scratchpad=$(printf '%s\n' "$tree" | jq -r '
  .. | objects
  | select(.type == "workspace" and .name == "__i3_scratch")
  | .floating_nodes[]?.id' | head -n1)

[ -n "$focused" ] && [ -n "$scratchpad" ] || exit 0

exec swaymsg "[con_id=$focused] swap container with con_id $scratchpad"
