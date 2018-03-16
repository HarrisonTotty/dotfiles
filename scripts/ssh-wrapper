#!/bin/bash
# ~/.config/scripts/ssh-wrapper
# A wrapper script to set TERM because rofy doesn't like "=" signs >_>

if [[ $1 = *"{"*"}"* ]]; then
    eval cssh --quiet $1
else
    TERM=rxvt ssh $1
fi
