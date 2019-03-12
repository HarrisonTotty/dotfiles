#!/bin/bash
# Simple wrapper script around running IPython

urxvtc +sb -title 'Python Interpreter' -fn 'xft:Iosevka SS02:size=14' -e "$SHELL" -c "ipython --config $HOME/.config/ipy/config.py --no-banner"
