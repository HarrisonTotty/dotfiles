#!/bin/bash
# A wrapper script to set TERM because rofi doesn't like "=" signs >_>

if [[ $1 = *"{"*"}"* ]]; then
    eval cssh --quiet $1
else
    TERM=xterm-256color ssh $1
fi
