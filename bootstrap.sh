#!/usr/bin/env bash
# Script to further automate the download and installation of a brand new
# system. It essentially builds the appropriate system installation script using
# "tmpl". The specified template configuration file is relative to the "tmpl"
# subdirectory of the repository.

set -e
trap "exit 100" INT

export TMPL_BLOCK_END_STR='%}'
export TMPL_BLOCK_START_STR='{%'
export TMPL_COMMENT_END_STR='#}'
export TMPL_COMMENT_START_STR='{#'
export TMPL_LOG_FILE='mkdot.log'
export TMPL_LOG_LEVEL='info'
export TMPL_LOG_MODE='overwrite'
export TMPL_VAR_END_STR='}}'
export TMPL_VAR_START_STR='{{'

# ---------- Configuration ----------
dotfiles_url='https://github.com/HarrisonTotty/dotfiles/archive/master.zip'
tmpl_url='https://github.com/HarrisonTotty/tmpl/archive/master.zip'
# -----------------------------------

cd "$HOME"

if [ "$#" -ne 1 ]; then
    echo "USAGE: ./bootstrap.sh <template conf>"
    echo "EXAMPLE: ./bootstrap.sh personal-laptop.yaml"
    exit 0
fi

echo 'Installing required packages...'
pacman -Sy pacman-contrib python-pip python-poetry unzip --noconfirm >/dev/null

echo 'Cleaning package cache...'
paccache -rk0 >/dev/null

if [ ! -d "$HOME/tmpl" ]; then
    echo 'Downloading tmpl source...'
    wget -q "$tmpl_url" -O tmpl.zip

    echo 'Extracting tmpl source...'
    unzip tmpl.zip >/dev/null
    rm -f tmpl.zip
    mv tmpl-* tmpl

    pushd "$HOME/tmpl" >/dev/null

    echo 'Building tmpl...'
    poetry --no-interaction build >/dev/null

    echo 'Installing tmpl...'
    pip3 --no-cache-dir --no-input install dist/*.whl >/dev/null

    popd >/dev/null
fi

if [ -d "$HOME/dotfiles" ]; then
    rm -rf "$HOME/dotfiles"
fi

echo 'Downloading dotfile templates...'
wget -q "$dotfiles_url" -O dotfiles.zip

echo 'Extracting dotfile templates...'
unzip dotfiles.zip >/dev/null
rm -f dotfiles.zip
mv dotfiles-* dotfiles

if [ -f "$HOME/install-arch.sh" ]; then
    rm -f "$HOME/install-arch.sh"
fi

conf_path="$HOME/dotfiles/tmpl/$1"
script_path="$HOME/dotfiles/src/scripts/install-arch.sh"

echo 'Rendering installer script...'
cat "$script_path" | tmpl "$conf_path" --stdin > "$HOME/install-arch.sh"

chmod +x "$HOME/install-arch.sh"
