#!/bin/bash
# A script to appropriately configure xrandr at boot.

connected=$(xrandr -q | grep ' connected')

if echo "$connected" | grep -q 'eDP'; then
    if echo "$connected" | grep -q 'HDMI-1' && echo "$connected" | grep -q 'DP-2'; then
        xrandr \
            --output VIRTUAL1 --off \
            --output eDP-1 --primary --mode 1920x1080 --pos 1920x0 --rotate normal \
            --output DP-1 --off \
            --output HDMI-2 --off \
            --output HDMI-1 --mode 1920x1080 --pos 3840x0 --rotate normal \
            --output DP-2 --mode 1920x1080 --pos 0x0 --rotate normal
    else
        xrandr \
            --output VIRTUAL1 --off \
            --output eDP-1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
            --output DP-1 --off \
            --output HDMI-2 --off \
            --output HDMI-1 --off \
            --output DP-2 --off
    fi
else
    echo "Primary display is not connected..."
    exit 1
fi

