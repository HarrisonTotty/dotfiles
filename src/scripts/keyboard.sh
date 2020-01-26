#!/usr/bin/env bash
# Script to handle launching/killing the on-screen keyboard program.

if pgrep -x onboard >/dev/null; then
    killall -q onboard
else
    onboard --theme LowContrast &
fi
