#!/bin/bash
# Script to autogenerate and reload an entire dotfile configuration.

template_confs="$HOME/projects/dotfiles/master/yaml"
template_source="$HOME/projects/dotfiles/master/templates"

if [ "$#" -ne 1 ]; then
    configs=$(find "$template_confs" -maxdepth 1 -type f | cut -d '/' -f 8 | sort | paste -sd '|')
    prompt='select template configuration file :'
    choice=$(echo "CANCEL|$configs" | rofi -sep '|' -dmenu -i -only-match -p "$prompt")
    if [ "$choice" == "CANCEL" ]; then
        exit 0
    elif [ "$choice" == "" ]; then
        exit 0
    else
        template_conf="$template_confs/$choice"
    fi
else
    template_conf="$1"
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

if mkdot "$template_conf" "$template_source"; then
    notify-send -u normal 'MKDOT' 'Dotfiles successfully generated.' &
else
    notify-send -u critical 'MKDOT' 'ERROR: Dotfile generation unsuccessful.' &
    exit 1
fi

if [ "$WINDOW_MANAGER" == 'i3' ]; then
    if [ -f "$HOME/.config/scripts/i3-restart-wrapper.sh" ]; then
        $HOME/.config/scripts/i3-restart-wrapper.sh
    fi
elif [ "$WINDOW_MANAGER" == 'herbstluftwm' ]; then
    herbstclient reload
fi
