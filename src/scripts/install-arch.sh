#!/usr/bin/env bash
# Script to install and configure Arch Linux on a new machine.
# Partially based on:
# https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install
{% do require('aur_packages', 'packages') %}

trap "exit 100" INT

# ------ Configuration ------

efivars_dir="/sys/firmware/efi/efivars"

mirrorlist_url="https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on"

dotfiles_repo="https://github.com/HarrisonTotty/dotfiles.git"

trizen_repo="https://aur.archlinux.org/trizen.git"

aur_packages="{{ aur_packages|join(' ') }}"

packages="{{ packages|join(' ') }}"

kernel_parameters="verbose"

timezone="{{ timezone|default('America/Chicago', true) }}"

# ---------------------------



# ----- Helper Functions -----

print_sec() { echo "$(tput setaf 4)::$(tput sgr0) $@"; }
print_nosec() { echo "   $@"; }
print_nosec_err() { echo "   $(tput setaf 1)$@$(tput sgr0)" 1>&2; }
print_subsec() { echo "  $(tput setaf 4)-->$(tput sgr0) $@"; }
print_nosubsec() { echo "      $@"; }
print_nosubsec_err() { echo "      $(tput setaf 1)$@$(tput sgr0)" 1>&2; }

# ----------------------------



# ------ Initial Setup -------

EC=2

print_sec "Verifying UEFI mode..."
if [ ! -d "$efivars_dir" ]; then
    print_nosec_err "Unable to verify UEFI mode - \"$efivars_dir\" does not exist."
    exit $EC
elif [ -z "$(ls -A $efivars_dir)" ]; then
    print_nosec_err "Unable to verify UEFI mode - \"$efivars_dir\" is empty."
    exit $EC
fi

print_sec "Verifying internet connection..."
if ! host "archlinux.org" 2>&1 >/dev/null; then
    print_nosec_err "Unable to verify internet connection - host lookup for \"archlinux.org\" failed."
    exit $EC
elif ! wget -q --spider "archlinux.org"; then
    print_nosec_err "Unable to verify internet connection - connection to \"archlinux.org\" failed."
    exit $EC
fi

print_sec "Updating system clock..."
if ! timedatectl set-ntp true 2>&1 >/dev/null; then
    print_nosec_err "Unable to update system clock - process returned non-zero exit code."
    exit $EC
fi

print_sec "Generating pacman mirror list..."
print_subsec "Backing-up previous mirror list..."
if ! cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup 2>&1 >/dev/null; then
    print_nosubsec_err "Unable to back-up previous mirror list."
    exit $EC
fi
print_subsec "Installing rankmirrors package..."
if ! pacman -Sy pacman-contrib --noconfirm 2>&1 >/dev/null; then
    print_nosubsec_err "Unable to install rankmirrors package."
    exit $EC
fi
print_subsec "Fetching and ranking fastest mirrors..."
if ! curl -s "$mirrorlist_url" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - 2>/dev/null > /etc/pacman.d/mirrorlist; then
    print_nosubsec_err "Unable to generate pacman mirrorlist - process returned non-zero exit code."
    exit $EC
fi

# ----------------------------



# ----- Filesystem Setup -----

EC=3



# ----------------------------

