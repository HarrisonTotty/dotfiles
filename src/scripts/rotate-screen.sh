#!/usr/bin/env bash
# Script to handle screen rotations.
{% do require('monitors.primary') %}

rotate_screen() {
    xrandr --output "{{ monitors.primary }}" --rotate "$1"
    $HOME/.config/scripts/polybar-start.sh
}

if xrandr -q | grep ' connected' | grep -q '{{ monitors.primary }}'; then
    prompt='switch screen mode :'
    choice=$(echo 'Laptop|Tablet (Portrait)|Tablet (Landscape)' | rofi -sep '|' -dmenu -i -no-custom -p "$prompt")
    if [ "$choice" == "" ]; then
        notify-send -u low 'WM' 'Action cancelled.' &
    elif [ "$choice" == "Laptop" ]; then
        rotate_screen normal
        notify-send -u low 'WM' 'Screen Mode: Laptop' &
    elif [ "$choice" == "Tablet (Portait)" ]; then
        rotate_screen left
        notify-send -u low 'WM' 'Screen Mode: Tablet (Portrait)' &
    elif [ "$choice" == "Tablet (Landscape)" ]; then
        rotate_screen inverted
        notify-send -u low 'WM' 'Screen Mode: Tablet (Landscape)' &
    fi
else
    notify-send -u normal 'WM' 'Primary display is not connected.' &
    exit 1
fi

    
