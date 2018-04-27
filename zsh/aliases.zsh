# ~/.config/zsh/aliases.zsh
# Contains custom aliases/functions for zsh

alias ls='ls --color=auto'
alias neofetch='neofetch --w3m'
alias netstat='ss -pantu | column -t'
alias vim='nvim'

# Function to clone a particular repo and store it in a folder with the same branch name
function gcb {
    if [ "$#" -ne 2 ]; then
        echo "Usage: gcb URL BRANCH"
    else
        git clone --depth 1 -b "$2" "$1" $(echo $2 | cut -d '/' -f2) || exit 1
    fi
}
