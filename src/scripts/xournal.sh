#!/usr/bin/env bash
# Wrapper script for writing notes.

if ! pgrep -x xournalpp >/dev/null; then
    xournalpp &
fi
