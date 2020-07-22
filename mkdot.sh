#!/usr/bin/env bash
# Wrapper script used to generate my dotfiles.

set -e
trap "exit 100" INT

export TMPL_BASE_DIR='src'
export TMPL_BLOCK_END_STR='%}'
export TMPL_BLOCK_START_STR='{%'
export TMPL_COMMENT_END_STR='#}'
export TMPL_COMMENT_START_STR='{#'
export TMPL_LOG_FILE='mkdot.log'
export TMPL_LOG_LEVEL='info'
export TMPL_LOG_MODE='overwrite'
export TMPL_OUTPUT="$HOME/.config"
export TMPL_VAR_END_STR='}}'
export TMPL_VAR_START_STR='{{'

if [ "$#" -lt 1 ]; then
    echo "USAGE: ./mkdot.sh <template configuration file>|clean [...]"
    exit 0
fi

if [ "$1" == "clean" ]; then
    rm -f mkdot.log
    exit 0
elif [ ! -f "$1" ]; then
    echo "Error: Specified template configuration file doesn't exist!"
    exit 1
fi

if [ -f ./tmpl-binary ]; then
    tmpl='./tmpl-binary'
else
    tmpl='tmpl'
fi

if [ "$#" -gt 1 ]; then
    $tmpl "$1" "${@:2:$#}"
else
    $tmpl "$1"
fi

if which doom >/dev/null 2>&1; then
    if [ -d "$HOME/.emacs.d" ]; then
        pushd "$HOME/.emacs.d" >/dev/null
        git pull
        doom update && doom clean && doom sync && doom -y compile
        popd >/dev/null
    fi
fi
