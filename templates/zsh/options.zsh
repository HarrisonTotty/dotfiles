# ~/.config/zsh/options.zsh
# Contains various workflow options

# History settings
HISTFILE="$HOME/.zsh-history.log"
if [ ! -f $HISTFILE ]; then
    touch "$HISTFILE"
fi
HISTSIZE=50000
SAVEHIST=50000

# Record timestamp in histrory file.
setopt extended_history

# Delete duplicates first from the history file.
setopt hist_ignore_dups

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

# Setup zsh keybindings.
[[ -n "${terminfo[khome]}" ]] && bindkey "${terminfo[khome]}" beginning-of-line
[[ -n "${terminfo[kend]}"  ]] && bindkey "${terminfo[kend]}"  end-of-line
[[ -n "${terminfo[kich1]}" ]] && bindkey "${terminfo[kich1]}" overwrite-mode
[[ -n "${terminfo[kdch1]}" ]] && bindkey "${terminfo[kdch1]}" delete-char
[[ -n "${terminfo[kcuu1]}" ]] && bindkey "${terminfo[kcuu1]}" up-line-or-history
[[ -n "${terminfo[kcud1]}" ]] && bindkey "${terminfo[kcud1]}" down-line-or-history
[[ -n "${terminfo[kcub1]}" ]] && bindkey "${terminfo[kcub1]}" backward-char
[[ -n "${terminfo[kcuf1]}" ]] && bindkey "${terminfo[kcuf1]}" forward-char
