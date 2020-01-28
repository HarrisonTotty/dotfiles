#!/usr/bin/env bash
# Script to handle screen rotations.
{% do require('monitors.primary') %}

wacom_devices=$(xsetwacom --list devices | sed 's/\s*id:.*//')

rotate_screen() {
    xrandr --output "{{ monitors.primary }}" --rotate "$1"
    while read -r wacom_device; do
        xsetwacom --set "$wacom_device" rotate "$2"
    done <<< "$wacom_devices"
    $HOME/.config/scripts/polybar-start.sh
    if [ "$1" != "normal" ]; then
        polybar tablet &
    fi
}

if xrandr -q | grep ' connected' | grep -q '{{ monitors.primary }}'; then
    prompt='switch screen mode :'
    choice=$(echo 'Laptop|Tablet (Landscape)|Tablet (Portrait)' | rofi -sep '|' -dmenu -i -l 3 -no-custom -p "$prompt")
    if [ "$choice" == "" ]; then
        notify-send -u low 'WM' 'Action cancelled.' &
    elif [ "$choice" == "Laptop" ]; then
        killall -q onboard
        rotate_screen normal none
        notify-send -u low 'WM' 'Screen Mode: Laptop' &
    elif [ "$choice" == "Tablet (Portrait)" ]; then
        rotate_screen left ccw
        notify-send -u low 'WM' 'Screen Mode: Tablet (Portrait)' &
    elif [ "$choice" == "Tablet (Landscape)" ]; then
        rotate_screen inverted half
        notify-send -u low 'WM' 'Screen Mode: Tablet (Landscape)' &
    fi
else
    notify-send -u normal 'WM' 'Primary display is not connected.' &
    exit 1
fi

    
