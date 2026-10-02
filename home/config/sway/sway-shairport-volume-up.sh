#!/bin/sh
fifo="${XDG_RUNTIME_DIR:-/tmp}/wob.fifo"

idx=$(pactl -f json list sink-inputs \
    | jq -r '.[] | select(.properties["application.name"] == "Shairport Sync") | .index' \
    | head -n1)

[ -z "$idx" ] && exit 0

pactl set-sink-input-volume "$idx" +5%

vol=$(pactl -f json list sink-inputs \
    | jq -r --argjson i "$idx" \
        '.[] | select(.index == $i) | .volume["front-left"].value_percent | rtrimstr("%")')

if [ -n "$vol" ] && [ -p "$fifo" ]; then
    timeout 1 sh -c 'printf "%s\n" "$1" > "$2"' _ "$vol" "$fifo" 2>/dev/null
fi
