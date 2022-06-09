#!/usr/bin/env zsh
# ZSH Aliases
# -----------
{% do require('terminal_emulator') %}

alias emacs='emacs -nw'
alias ls='ls --color=auto'
{% if terminal_emulator == 'urxvt' %}
alias neofetch='neofetch --w3m'
{% elif terminal_emulator == 'alacritty' %}
{% endif %}
alias netstat='ss -pantu | column -t'
