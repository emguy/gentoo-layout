#!/bin/sh
# usage: sway-ff-clip.sh copy|paste
case "$1" in
  copy)  key=c ;;
  paste) key=v ;;
  *) exit 1 ;;
esac

app=$(swaymsg -t get_tree | jq -r \
  '.. | objects | select(.focused == true) | .app_id // .window_properties.class // empty' | head -n1)

if [ "${app}" = "firefox" ]; then
  exec wtype -s 50 -M ctrl -k "$key" -m ctrl
else
  exec wtype -s 50 -M ctrl -k "$key" -m logo
fi
