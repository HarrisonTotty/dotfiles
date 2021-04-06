#!/bin/bash
# Simple wrapper script for rofi-bw

notify-send -u low "WM" "Fetching password database..." &

output=$(rofi-bw)

if [ "$output" = "ERROR" ]; then
    notify-send -u normal "WM" "Encountered runtime error." &
elif [ "$output" = "CANCEL" ]; then
    notify-send -u normal "WM" "Action cancelled." &
elif [ "$output" = "" ]; then
    notify-send -u normal "WM" "Action cancelled." &
elif [ "$output" = "LOGOUT" ]; then
    notify-send -u normal "WM" "Successfully logged-out." &
else
    echo -n "$output" | xclip -sel clip
    notify-send -u normal "WM" "Password copied to clipboard." &
fi
