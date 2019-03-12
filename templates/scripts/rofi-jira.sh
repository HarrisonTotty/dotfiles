#!/bin/bash
# Simple wrapper script around "rofi-jira.py".

yaml="$HOME/projects/rofi-jira/master/rofi-jira.yaml"

/usr/local/bin/rofi-jira -c $yaml $@
