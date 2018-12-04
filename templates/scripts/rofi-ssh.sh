#!/bin/bash
# Simple wrapper for rofi's ssh mode.

rofi -show ssh -ssh-command 'urxvtc +sb -letsp 1 -title "SSH : {host}" -e /home/harrisont/.config/scripts/ssh-wrapper.sh {host}'
