#!/usr/bin/env bash
# Simple rofi wrapper around netctl.

profiles="$(find /etc/netctl -maxdepth 1 -type f | cut -d '/' -f 4 | sort | paste -sd '|')"
prompt="switch network profile :"
choice=$(echo "CANCEL|DISABLE|$profiles" | rofi -sep '|' -dmenu -i -only-match -p "$prompt")

if [ "$choice" == "CANCEL" ]; then
    exit 0
elif [ "$choice" == "" ]; then
    exit 0
elif [ "$choice" == "DISABLE" ]; then
    if ! sudo netctl stop-all; then
        notify-send -u normal "NET" "Unable to stop all network profiles." &
        exit 1
    else
        notify-send -u normal "NET" "Successfully stopped all network profiles." &
        exit 0
    fi
else
    notify-send -u low "NET" "Starting network profile..." &
    sudo netctl stop-all
    if ! sudo netctl start "$choice"; then
        notify-send -u normal "NET" "Unable to start network profile." &
        exit 1
    else
        notify-send -u normal "NET" "Successfully started network profile." &
        exit 0
    fi
fi
