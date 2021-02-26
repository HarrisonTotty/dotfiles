#!/usr/bin/env bash
# Script to ensure that certain initialization sub-scripts don't get into a race-condition.

# Setup monitor configuration
$HOME/.config/scripts/setup-monitors.sh

# Re-launch pywal, this time allowing it to set the background, and execute wal-set afterwards
wal -R -o "$HOME/.config/scripts/wal-set.sh"

# Send a welcome message
sleep 1
notify-send -u normal 'WM' 'Initialization complete. Hello, Harrison :)' &
