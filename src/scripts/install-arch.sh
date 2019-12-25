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



# ----- Disk Partitioning ----

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

{% for p in installer.partitions %}
{% if not p.name is defined %}
{% do raise('one or more partitions does not specify a name') %}
{% endif %}
print_subsec "Creating \"{{ p.name }}\" partition..."
{% if p.size is defined and p.size != '0' %}
{% set psize = '+' + p.size %}
{% else %}
{% set psize = '0' %}
{% endif %}
if ! sgdisk --new={{ loop.index }}:0:{{ psize }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create new partition - {{ n0ec }}"
    exit $EC
fi
if ! sgdisk --typecode={{ loop.index }}:{{ p.typecode|default('8300', true) }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to set partition type - {{ n0ec }}"
    exit $EC
fi
{% if p.encrypted is defined and p.encrypted %}
{% if not system_encrypted is defined %}
{% set system_encrypted = True %}
{% endif %}
{% set pname = p.name + '-encrypted' %}
{% else %}
{% set pname = p.name %}
{% endif %}
if ! sgdisk --change-name={{ loop.index }}:{{ pname }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to set partition name - {{ n0ec }}"
    exit $EC
fi
{% endfor %}

# ----------------------------



# ----- Encryption Setup -----

EC=4

cryptcmd='cryptsetup luksFormat --align-payload=8192'
cryptswapcmd='cryptsetup open --type plain --key-file /dev/urandom'

{% if system_encrypted is defined and system_encrypted %}

print_sec "Encrypting partitions..."

{% for p in installer.partitions %}
{% if p.encrypted is defined and p.encrypted %}
print_subsec "Encrypting \"{{ p.name }}\" partition..."
{% if p.typecode is defined and p.typecode == '8200' %}
if ! $cryptswapcmd "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}" "{{ p.name }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to encrypt swap partition - {{ n0ec }}"
    exit $EC
fi
{% else %}
cipher="{{ p.cipher|default('aes-xts-plain64', true) }}"
keysize="{{ p.keysize|default('256', true) }}"
if ! $cryptcmd --cipher $cipher --key-size $keysize "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}"; then
    print_nosubsec_err "Unable to encrypt partition - {{ n0ec }}"
    exit $EC
fi
if ! cryptsetup open "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}" "{{ p.name }}"; then
    print_nosubsec_err "Unable to unseal encrypted partition - {{ n0ec }}"
    exit $EC
fi
{% endif %}
{% endif %}
{% endfor %}

{% endif %}

# ----------------------------



# ----- Filesystem Setup -----

EC=5

print_sec "Creating filesystems..."

{% for fs in installer.filesystems %}
{% if not fs.name is defined %}
{% do raise('one or more filesystems does not specify a name') %}
{% endif %}
{% if not fs.kind is defined %}
{% do raise('one or more filesystems does not specify a filesystem kind') %}
{% endif %}
print_subsec "Creating \"{{ fs.name }}\" filesystem..."
{% if fs.kind == 'fat32' %}
mkfs.vfat -F 32 -n "{{ fs.name }}" "/dev/disk/by-partlabel/{{ fs.partition }}"
{% endif %}
{% endfor %}

# ----------------------------
