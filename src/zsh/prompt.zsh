#!/usr/bin/env zsh
# ZSH Prompt Configuration
# ------------------------

# Set window title
case $TERM in
  (*xterm* | rxvt* | alacritty)

    # Write some info to terminal title.
    # This is seen when the shell prompts for input.
    function precmd {
      print -Pn "\e]0;Terminal : %~\a"
    }

    # Write command and args to terminal title.
    # This is seen while the shell waits for a command to complete.
    function preexec {
      printf "\033]0;Terminal : %s\a" "$1"
    }

  ;;
esac


PROMPT='%F{blue}%~%f  >  '
