# Harrison's Arch Linux Dotfiles

## Summary

The following repo contains the dotfiles for my current Arch Linux setup. This is obviously a fork of my personal dotfiles specifically redesigned for my work computer. In general, the root folder of this repo corresponds to my `~/.config/` directory. From here, I symlink out all of my X11 and zsh stuff to my `$HOME` folder.


## Packages

In order to get things to work, you'll need the following packages installed on your Arch Linux setup:

* `i3-gaps` - Ironically, I don't even use the "gaps" feature. Instead I use this fork because of a few other tweaks (like setting i3bar height, etc).
* `polybar` - My personal favorite as far as status bars are concerned. It has a wide variety of configuration options without being too hacky.
* `dunst` - Super light-weight and configurable. Not to mention it works out of the box with `pywal`.
* `pywal` - Dylan's python3 rewrite is a lot more stable and seems to generate better colors (probably because I was using a super hacked version of his old script last time). Requires `imagemagic`.
* `zsh` - Gotta love it.
* `i3lock-color-git` - Lock screen.
* `scrot` - Used by my screen locking program.


