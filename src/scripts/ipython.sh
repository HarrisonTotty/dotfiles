#!/usr/bin/env bash
# Simple wrapper script around running IPython
{% do require('font.name', 'terminal_emulator') %}
{% set wtitle = 'Python Interpreter' %}

{% if terminal_emulator == 'urxvt' %}
urxvtc +sb \
       -title '{{ wtitle }}' \
       -fn 'xft:{{ font.name }}:size=14' \
       -e "$SHELL" \
       -c "ipython --config $HOME/.config/ipy/config.py --no-banner"
{% elif terminal_emulator == 'alacritty' %}
alacritty \
    --title '{{ wtitle }}' \
    --command /usr/bin/ipython --config "$HOME/.config/ipy/config.py" --no-banner
{% endif %}
