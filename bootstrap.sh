#!/usr/bin/env bash
# Script to further automate the download and installation of a brand new
# system. It essentially gets everything ready for "building" the system
# configurations using "tmpl".

set -e
trap "exit 100" INT

# ---------- Configuration ----------
dotfiles_url='https://github.com/HarrisonTotty/dotfiles/archive/tmpl.zip'
tmpl_url='https://raw.githubusercontent.com/HarrisonTotty/tmpl/master/tmpl.py'
# -----------------------------------

cd "$HOME"

if [ -f /usr/local/bin/tmpl ]; then
    rm -f /usr/local/bin/tmpl
fi

wget "$tmpl_url" -O /usr/local/bin/tmpl && chmod +x /usr/local/bin/tmpl

pacman -Sy python-jinja python-yaml --noconfirm

if [ -d "$HOME/dotfiles" ]; then
    rm -rf "$HOME/dotfiles"
fi

wget "$dotfiles_url" -O dotfiles.zip \
    && unzip dotfiles.zip \
    && rm -f dotfiles.zip \
    && mv dotfiles-* dotfiles
