# ~/.config/zsh/options.zsh
# Contains various workflow options

# History settings
HISTFILE=~/.cache/zsh/history
HISTSIZE=100000
SAVEHIST=100000

# Automatically change directories if input corresponds to a valid directory
setopt autocd

# Print errors if a filename doesn't match correctly
setopt nomatch

# Disable beeping
unsetopt beep

# Enable extended globbing
setopt extendedglob

# Enable autocompletion
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# Enable comments
set -k

# Setup zsh keybindings
bindkey -e
bindkey "${terminfo[khome]}" beginning-of-line
bindkey "${terminfo[kend]}" end-of-line

# Enable command-not-found hook
[ -f /usr/share/doc/pkgfile/command-not-found.zsh ] && source /usr/share/doc/pkgfile/command-not-found.zsh
