#!/bin/bash
# Script to autogenerate and reload an entire dotfile configuration.

template_source="$HOME/projects/dotfiles/mkdot/templates"

if [ "$#" -ne 1 ]; then
    echo "USAGE: mkdot-apply.sh YAML_CONFIG_FILE_OR_DIR"
    exit 1
fi
    
if [ -f "$HOME/.config/x/exports.sh" ]; then
    source "$HOME/.config/x/exports.sh"
else
    MKDOT_BLOCK_END_STR='%}'
    MKDOT_BLOCK_START_STR='{%'
    MKDOT_COMMENT_END_STR='#}'
    MKDOT_COMMENT_START_STR='{#'
    MKDOT_EXCLUDE=''
    MKDOT_LOG_FILE="$HOME/.mkdot.log"
    MKDOT_LOG_LVL='info'
    MKDOT_LOG_MODE='append'
    MKDOT_OUTPUT="$HOME/.config"
    MKDOT_RSYNC_PATH='/usr/bin/rsync'
    MKDOT_RUN="chmod +x $HOME/.config/scripts/*.sh"
    MKDOT_VAR_END_STR='}}'
    MKDOT_VAR_START_STR='{{'
    MKDOT_WORKING_DIR='/tmp/mkdot'
fi

notify-send -u low 'MKDOT' 'Generating dotfile configuration...' &

mkdot "$1" "$template_source"
