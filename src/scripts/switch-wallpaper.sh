#!/usr/bin/env bash
# Script to select a wallpaper via rofi

images="$(find $HOME/.config/wal/wallpapers -maxdepth 1 -type f | cut -d '/' -f 7 | sort | paste -sd '|')"
prompt="select wallpaper :"
choice=$(echo $images | rofi -sep '|' -dmenu -i -no-custom -p "$prompt")

if [ "$choice" == "" ]; then
    exit 0
else
    wal -i "$HOME/.config/wal/wallpapers/$choice" -o "$HOME/.config/scripts/wal-set.sh" >/dev/null 2>&1
    notify-send -u low "WM" "Switched wallpaper & theme." &
fi
