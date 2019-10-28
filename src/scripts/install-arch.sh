#!/usr/bin/env bash
# Script to install and configure Arch Linux on a new machine.
# Partially based on:
# https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install
{%
  do require(
    'installer.aur_packages',
    'installer.drive',
    'installer.filesystems',
    'installer.packages',
    'installer.partitions'
  )
%}
{% set n0ec = 'subprocess returned non-zero exit code.' %}

trap "exit 100" INT

# ------ Configuration ------

aur_packages="{{ installer.aur_packages|join(' ') }}"

dotfiles_url="{{ installer.dotfiles_url|default('https://github.com/HarrisonTotty/dotfiles/archive/master.zip', true) }}"

efivars_dir="/sys/firmware/efi/efivars"

kernel_parameters="verbose"

mirrorlist_url="https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on"

packages="{{ installer.packages|join(' ') }}"

timezone="{{ installer.timezone|default('America/Chicago', true) }}"

tmpl_url="{{ installer.tmpl_url|default('https://raw.githubusercontent.com/HarrisonTotty/tmpl/master/tmpl.py', true) }}"

trizen_repo="https://aur.archlinux.org/trizen.git"

# ---------------------------



# ----- Helper Functions -----

print_sec() { echo "$(tput setaf 4)::$(tput sgr0) $@"; echo "$@" >> install-arch.log; }
print_nosec() { echo "   $@"; echo "$@" >> install-arch.log; }
print_nosec_err() { echo "   $(tput setaf 1)$@$(tput sgr0)" 1>&2; echo "$@" >> install-arch.log; }
print_subsec() { echo "  $(tput setaf 4)-->$(tput sgr0) $@"; echo "$@" >> install-arch.log; }
print_nosubsec() { echo "      $@"; echo "$@" >> install-arch.log; }
print_nosubsec_err() { echo "      $(tput setaf 1)$@$(tput sgr0)" 1>&2; echo "$@" >> install-arch.log; }

# ----------------------------



# ------ Initial Setup -------

echo -n '' > install-arch.log

EC=2

print_sec "Performing initial setup..."

{% if not installer.disable_uefi is defined or not installer.disable_uefi %}
print_subsec "Verifying UEFI mode..."
if [ ! -d "$efivars_dir" ]; then
    print_nosubsec_err "Unable to verify UEFI mode - \"$efivars_dir\" does not exist."
    exit $EC
elif [ -z "$(ls -A $efivars_dir)" ]; then
    print_nosubsec_err "Unable to verify UEFI mode - \"$efivars_dir\" is empty."
    exit $EC
fi
{% endif %}

print_subsec "Verifying internet connection..."
if ! host "archlinux.org" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to verify internet connection - host lookup for \"archlinux.org\" failed."
    exit $EC
elif ! wget -q --spider "archlinux.org"; then
    print_nosubsec_err "Unable to verify internet connection - connection to \"archlinux.org\" failed."
    exit $EC
fi

print_subsec "Updating system clock..."
if ! timedatectl set-ntp true >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to update system clock - {{ n0ec }}"
    exit $EC
fi

print_subsec "Backing-up previous pacman mirror list..."
if ! cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to back-up previous pacman mirror list - {{ n0ec }}"
    exit $EC
fi

print_subsec "Installing rankmirrors package..."
if ! pacman -Sy pacman-contrib --noconfirm >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to install rankmirrors package - {{ n0ec }}"
    exit $EC
fi

print_subsec "Fetching and ranking fastest mirrors..."
if ! curl -s "$mirrorlist_url" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - >/etc/pacman.d/mirrorlist 2>/dev/null; then
    print_nosubsec_err "Unable to generate pacman mirrorlist - {{ n0ec }}"
    exit $EC
fi

# ----------------------------



# ----- Filesystem Setup -----

EC=3

print_sec "Partitioning {{ installer.drive }}..."

if [ -d '/mnt' ]; then
    print_subsec "Cleaning mount points from previous runs..."
    umount -R /mnt >> install-arch.log 2>&1
    rm -rf /mnt >> install-arch.log 2>&1
fi

print_subsec "Cleaning partition table..."
if ! sgdisk --zap-all "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to zap partition table - {{ n0ec }}"
    exit $EC
fi
if ! sgdisk --clear "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to clear partition table - {{ n0ec }}"
    exit $EC
fi

{% for partition in installer.partitions %}
{% if not partition.name is defined %}
{% do raise('One or more partitions do not specify a name') %}
{% endif %}
print_subsec "Creating \"{{ partition.name }}\" partition..."
if ! sgdisk --new={{ loop.index }}:0:+{{ partition.size|default('0', true) }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create new partition - {{ n0ec }}"
    exit $EC
fi
if ! sgdisk --typecode={{ loop.index }}:{{ partition.typecode|default('8300', true) }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to set partition type - {{ n0ec }}"
    exit $EC
fi
if ! sgdisk --change-name={{ loop.index }}:{{ partition.name }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to set partition name - {{ n0ec }}"
    exit $EC
fi
{% endfor %}

# ----------------------------

