#!/bin/bash
# Script to take a screenshot (fullscreen)

if [ ! -d "$HOME/pics/screenshots" ]; then
    mkdir -p "$HOME/pics/screenshots"
fi
notify-send -u low "WM" "Taking screenshot..." &
scrot --delay 3 --silent "$HOME/pics/screenshots/screenshot.%y-%m-%d.%H-%M.png"
notify-send -u low "WM" "Saved screenshot." &
