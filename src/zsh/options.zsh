#!/usr/bin/env zsh
# ZSH Options
# -----------

# History settings
export HISTFILE="$HOME/.zsh-history.log"
if [ ! -f $HISTFILE ]; then
    touch "$HISTFILE"
fi
export HISTSIZE=50000
export SAVEHIST=50000
export HISTTIMEFORMAT="[%F %T] "

# Record timestamp in histrory file.
setopt extended_history

# Ignore duplicates when running CTRL+F.
setopt hist_find_no_dups

# Ignore commands that start with a space.
setopt hist_ignore_space

# Add commands to the history file in order of execution.
setopt inc_append_history

# Share the history file across all terminals.
setopt share_history

# Automatically change directories if input corresponds to a valid directory.
setopt autocd

# Print errors if a filename doesn't match correctly.
setopt nomatch

# Disable beeping.
unsetopt beep

# Enable extended globbing.
setopt extendedglob

# Enable autocompletion.
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Enable comments.
set -k
