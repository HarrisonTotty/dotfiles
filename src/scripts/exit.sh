#!/bin/bash
# A simple wrapper around rofi for exiting the window manager.

options="Cancel|Logout|Restart|Shutdown"
prompt="What would you like to do?"

result=$(echo "$options" | rofi -sep "|" -dmenu -i -only-match -l 4 -p "$prompt")

if [ "$result" == "Cancel" ]; then
    exit 0
elif [ "$result" == "Logout" ]; then
    if [ "$WINDOW_MANAGER" == "i3" ]; then
        i3-msg exit
    elif [ "$WINDOW_MANAGER" == "herbstluftwm" ]; then
        herbstclient quit
    fi
elif [ "$result" == "Restart" ]; then
    systemctl reboot
elif [ "$result" == "Shutdown" ]; then
    systemctl poweroff
else
    echo "Unknown option."
    exit 1
fi
