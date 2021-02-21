#!/bin/bash
# Simple bash script for generating a lock screen.

set -e

if [ -f "$HOME/.locked.png" ]; then
    rm -f "$HOME/.locked.png"
fi

scrot "$HOME/.locked.png"
notify-send -u low "WM" "Locking screen..." -t 3000 &
convert "$HOME/.locked.png" -quality 10 -scale '10%' -scale '1000%' "$HOME/.locked.png"
#convert "$HOME/.locked.png" "$HOME/.config/scripts/lock50.png" -gravity center -geometry +0,+100 -composite -matte "$HOME/.locked.png"
i3lock --nofork -i "$HOME/.locked.png" --ignore-empty-password --no-unlock-indicator
notify-send -u low "WM" "Welcome back, Harrison :)" -t 3000 &
