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

print_sec "Creating & mounting filesystems..."

{% for fs in installer.filesystems %}


{# ----- Check some stuff ----- #}

{% if not fs.name is defined %}
{% do raise('one or more filesystems does not specify a name') %}
{% endif %}

{% if not fs.kind is defined %}
{% do raise(fs.name + ' filesystem does not specify a filesystem kind') %}
{% endif %}

{% if not fs.partition is defined %}
{% do raise(fs.name + ' filesystem does not specify a reference partition') %}
{% endif %}


{# ----- Create the filesystem ----- #}

print_subsec "[{{ fs.kind }}] Creating \"{{ fs.name }}\" filesystem..."

{% if fs.partition_encrypted is defined and fs.partition_encrypted %}
{% set partition_path = '/dev/mapper/' + fs.partition %}
{% else %}
{% set partition_path = '/dev/disk/by-partlabel/' + fs.partition %}
{% endif %}

{% if fs.kind == 'btrfs' %}
if ! mkfs.btrfs --force --label "{{ fs.name }}" "{{ partition_path }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'fat32' %}
if ! mkfs.vfat -F 32 -n "{{ fs.name }}" "{{ partition_path }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'swap' %}
if ! mkswap --label "{{ fs.name }}" "{{ partition_path }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create filesystem - {{ n0ec }}"
    exit $EC
fi
{% else %}
{% do raise(fs.name + ' filesystem specifies an unknown filesystem kind') %}
{% endif %}


{# ----- Mount the filesystem ----- #}

{% if fs.mountpoint is defined or fs.kind == 'swap' %}

print_subsec "[{{ fs.kind }}] Mounting \"{{ fs.name }}\" filesystem..."

{% if fs.mountpoint is defined %}
if [ -d "{{ fs.mountpoint }}" ]; then
    rm -rf "{{ fs.mountpoint }}" >> install-arch.log 2>&1
fi
if ! mkdir -p "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create filesystem mount directory - {{ n0ec }}"
    exit $EC
fi
{% endif %}

{% if fs.kind == 'btrfs' %}
if ! mount -t btrfs "LABEL={{ fs.name }}" "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to mount filesystem - {{ n0ec }}"
    exit $EC
fi
{% if not fs.subvolumes is defined %}
{% do raise(fs.name + ' btrfs filesystem does not specify subvolumes') %}
{% endif %}
print_subsec "[{{ fs.kind }}] Creating \"{{ fs.name }}\" subvolumes..."
{% for sv in fs.subvolumes %}
{% if not sv.name is defined %}
{% do raise('subvolume does not specify a name') %}
{% endif %}
if ! btrfs subvolume create "{{ path_join(fs.mountpoint, sv.name) }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create subvolume \"{{ sv.name }}\" - {{ n0ec }}"
    exit $EC
fi
{% endfor %}
print_subsec "[{{ fs.kind }}] Mounting \"{{ fs.name }}\" filesystem subvolumes..."
if ! umount -R "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to unmount subvolume owner - {{ n0ec }}"
    exit $EC
fi
{% for sv in fs.subvolumes %}
{% if sv.mountpoint is defined %}
if [ -d "{{ sv.mountpoint }}" ]; then
    rm -rf "{{ sv.mountpoint }}" >> install-arch.log 2>&1
fi
if ! mkdir -p "{{ sv.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to create filesystem subvolume mount directory - {{ n0ec }}"
    exit $EC
fi
mountcmd="mount -t btrfs -o subvol={{ sv.name }},{{ sv.mount_options|default('defaults', true) }}"
if ! $mountcmd "LABEL={{ fs.name }}" "{{ sv.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to mount subvolume \"{{ sv.name }}\" - {{ n0ec }}"
    exit $EC
fi
{% endif %}
{% endfor %}
{% elif fs.kind == 'fat32' %}
if ! mount "LABEL={{ fs.name }}" "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to mount filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'swap' %}
if ! swapon -L "{{ fs.name }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to mount filesystem - {{ n0ec }}"
    exit $EC
fi
{% endif %}

{% endif %}

{% endfor %}

# ----------------------------



# ------ Install System ------

EC=6

print_sec "Installing system packages..."

if ! pacstrap /mnt {{ installer.packages|join(' ') }} >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to install system packages - {{ n0ec }}"
    exit $EC
fi

# ----------------------------
