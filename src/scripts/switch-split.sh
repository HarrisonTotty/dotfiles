#!/usr/bin/env bash
i3-msg layout toggle split
notify-send -u low 'WM' 'Switched to split layout.' &
