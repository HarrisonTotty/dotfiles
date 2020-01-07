#!/usr/bin/env bash
rofi -show ssh -ssh-command "urxvtc +sb -letsp 1 -title 'SSH : {host}' -e $HOME/.config/scripts/ssh-wrapper.sh {host}"
