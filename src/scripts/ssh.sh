#!/usr/bin/env bash
{% do require('terminal_emulator') %}

{% if terminal_emulator == 'urxvt' %}
rofi -show ssh -ssh-command "urxvtc +sb -letsp 1 -title 'SSH : {host}' -e $HOME/.config/scripts/ssh-wrapper.sh {host}"
{% endif %}
