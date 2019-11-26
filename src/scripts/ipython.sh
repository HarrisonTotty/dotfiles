#!/bin/bash
# Simple wrapper script around running IPython
{% do require('font.name') %}

urxvtc +sb \
       -title 'Python Interpreter' \
       -fn 'xft:{{ font.name }}:size=14' \
       -e "$SHELL" \
       -c "ipython --config $HOME/.config/ipy/config.py --no-banner"
