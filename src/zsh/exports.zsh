# ZSH Export Statements
# ---------------------
{% do require('bin_paths') %}

export EDITOR='emacs'
export GOPATH="$HOME/.go"
export LANG='en_US.UTF-8'
export LC_CTYPE='en_US.UTF-8'
export PATH="{{ bin_paths|join(':') }}"
