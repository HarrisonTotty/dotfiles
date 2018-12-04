#!/bin/bash
# A script to appropriately configure xrandr at boot.

connected=$(xrandr -q | grep ' connected')

if echo "$connected" | grep -q 'eDP1'; then
    if echo "$connected" | grep -q 'HDMI1' && echo "$connected" | grep -q 'DP2'; then
        xrandr \
            --output VIRTUAL1 --off \
            --output eDP1 --primary --mode 1920x1080 --pos 1680x0 --rotate normal \
            --output DP1 --off \
            --output HDMI2 --off \
            --output HDMI1 --mode 1680x1050 --pos 3600x0 --rotate normal \
            --output DP2 --mode 1680x1050 --pos 0x0 --rotate normal
    else
        xrandr \
            --output VIRTUAL1 --off \
            --output eDP1 --primary --mode 1920x1080 --pos 0x0 --rotate normal \
            --output DP1 --off \
            --output HDMI2 --off \
            --output HDMI1 --off \
            --output DP2 --off
    fi
else
    echo "Primary display is not connected..."
    exit 1
fi

