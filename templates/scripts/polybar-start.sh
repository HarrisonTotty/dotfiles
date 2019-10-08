#!/bin/bash
# Polybar launch script.

# Terminate already running bar instances.
killall -q polybar

# Wait until the processes have been shut down.
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch polybar for the main display.
polybar bar-primary &

# Launch polybar for the two other monitors, if they are active
AVAILABLE_MONITORS=$(polybar --list-monitors)
if echo $AVAILABLE_MONITORS | grep -q 'DP-2'; then
	polybar bar-left &
fi
if echo $AVAILABLE_MONITORS | grep -q 'HDMI-1'; then
	polybar bar-right &
fi
