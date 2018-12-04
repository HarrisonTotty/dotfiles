#!/bin/bash
# Wrapper script for restarting i3 in-place

if [ -f "$HOME/.cache/wal/colors.sh" ]; then
    source "$HOME/.cache/wal/colors.sh"
fi

rofi -e "[!] The window manager will now restart." -width -44
killall -q polybar >/dev/null 2>&1
i3-msg reload >/dev/null 2>&1
$HOME/.config/polybar/launch.sh
notify-send -u low "WM" "Successfully restarted window manager..." &
