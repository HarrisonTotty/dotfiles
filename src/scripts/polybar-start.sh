#!/usr/bin/env bash
# Polybar launch script.
{% do require('monitors.left', 'monitors.right') %}

# Terminate already running bar instances.
killall -q polybar

# Wait until the processes have been shut down.
while pgrep -x polybar >/dev/null; do sleep 1; done

# Launch polybar for the main display.
polybar primary &

# Launch polybar for the two other monitors, if they are active
AVAILABLE_MONITORS=$(polybar --list-monitors)
if echo $AVAILABLE_MONITORS | grep -q '{{ monitors.left }}'; then
	polybar left &
fi
if echo $AVAILABLE_MONITORS | grep -q '{{ monitors.right }}'; then
	polybar right &
fi
