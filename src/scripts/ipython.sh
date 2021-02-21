#!/bin/bash
# Simple wrapper script around running IPython
{% do require('font.name', 'terminal_emulator') %}

{% if terminal_emulator == 'urxvt' %}
urxvtc +sb \
       -title 'Python Interpreter' \
       -fn 'xft:{{ font.name }}:size=14' \
       -e "$SHELL" \
       -c "ipython --config $HOME/.config/ipy/config.py --no-banner"
{% endif %}
