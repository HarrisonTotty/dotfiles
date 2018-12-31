#!/bin/bash
# Script to switch to the next wallpaper and thusly re-theme the environment.

wal -i "$HOME/.config/wal/wallpapers" --iterative -o "$HOME/.config/scripts/wal-set.sh" >/dev/null 2>&1
notify-send -u low "WM" "Switched wallpaper & theme." &
