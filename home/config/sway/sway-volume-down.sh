#!/bin/sh
fifo="${XDG_RUNTIME_DIR:-/tmp}/wob.fifo"

pactl set-sink-volume @DEFAULT_SINK@ -5%

vol=$(pactl -f json list sinks \
    | jq -r --arg s "$(pactl get-default-sink)" \
        '.[] | select(.name == $s) | .volume["front-left"].value_percent | rtrimstr("%")')

if [ -n "$vol" ] && [ -p "$fifo" ]; then
    timeout 1 sh -c 'printf "%s\n" "$1" > "$2"' _ "$vol" "$fifo" 2>/dev/null
fi
