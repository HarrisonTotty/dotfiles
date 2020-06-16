#!/usr/bin/env bash
# Script to install and configure Arch Linux on a new machine.
# Partially based on:
# https://wiki.archlinux.org/index.php/User:Altercation/Bullet_Proof_Arch_Install
{%
  do require(
    'installer.aur_packages',
    'installer.bootloader',
    'installer.drive',
    'installer.filesystems',
    'installer.hostname',
    'installer.packages',
    'installer.partitions',
    'installer.shell',
    'installer.username',
    'installer.user_directories',
  )
%}
{% set n0ec = 'subprocess returned non-zero exit code.' %}

trap "exit 100" INT

# ------ Configuration ------

dotfiles_url="{{ installer.dotfiles_url|default('https://github.com/HarrisonTotty/dotfiles/archive/master.zip', true) }}"

efivars_dir="/sys/firmware/efi/efivars"

kernel_parameters="verbose"

mirrorlist_url="https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on"

tmpl_url="{{ installer.tmpl_url|default('https://raw.githubusercontent.com/HarrisonTotty/tmpl/master/tmpl.py', true) }}"

trizen_repo="https://aur.archlinux.org/trizen.git"

# ---------------------------



# ----- Helper Functions -----

finish_installation() {
    EC=20
    print_sec "Finishing installation..."

    print_subsec "Unmounting filesystems..."
    if ! umount -R /mnt >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to unmount filesystems - {{ n0ec }}"
        exit $EC
    fi

{% for p in installer.partitions %}
{% if p.encrypted is defined and p.encrypted %}
    print_subsec "Closing encrypted container of \"{{ p.name }}\" partition..."
    if ! cryptsetup close "{{ p.name }}" >> install-arch.log 2>&1; then
        print_nosubsec_err "Warning: Unable to close encrypted container - {{ n0ec }}"
    fi
{% endif %}
{% endfor %}
}

mount_installation() {
    EC=30
    print_sec "Mounting existing installation..."

    {% if installer.system_encrypted is defined and installer.system_encrypted %}
    {% for p in installer.partitions %}
    {% if p.encrypted is defined and p.encrypted %}
    {% if not p.typecode is defined or p.typecode != '8200' %}
    print_subsec "Decrypting \"{{ p.name }}\" partition..."
    if ! cryptsetup open "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}" "{{ p.name }}"; then
        print_nosubsec_err "Error: Unable to unseal encrypted partition - {{ n0ec }}"
        exit $EC
    fi
    {% endif %}
    {% endif %}
    {% endfor %}
    {% endif %}

    {% for fs in installer.filesystems %}
    {% if fs.kind != 'swap' %}
    print_subsec "[{{ fs.kind }}] Mounting \"{{ fs.name }}\" filesystem..."
    {% if fs.kind == 'btrfs' %}
    {% if fs.subvolumes is defined %}
    {% for sv in fs.subvolumes %}
    {% if sv.mountpoint is defined %}
    if [ -d "{{ sv.mountpoint }}" ]; then
        rm -rf "{{ sv.mountpoint }}" >> install-arch.log 2>&1
    fi
    if ! mkdir -p "{{ sv.mountpoint }}" >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to create filesystem subvolume mount directory - {{ n0ec }}"
        exit $EC
    fi
    print_subsec "[{{ fs.kind }}] Mounting \"{{ sv.name }}\" subvolume of \"{{ fs.name }}\" filesystem..."
    mountcmd="mount -t btrfs -o subvol={{ sv.name }},{{ sv.mount_options|default('defaults', true) }}"
    if ! $mountcmd "LABEL={{ fs.name }}" "{{ sv.mountpoint }}" >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to mount subvolume \"{{ sv.name }}\" - {{ n0ec }}"
        exit $EC
    fi
    {% endif %}
    {% endfor %}
    {% endif %}
    {% elif fs.kind == 'ext4' or fs.kind == 'fat32' %}
    if ! mount "LABEL={{ fs.name }}" "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to mount filesystem - {{ n0ec }}"
        exit $EC
    fi
    {% endif %}
    {% endif %}
    {% endfor %}

    print_subsec "Establishing chroot environment..."
    arch-chroot /mnt
}

print_log() { echo "$@" >> install-arch.log; }

print_sec() { echo "$(tput setaf 4)::$(tput sgr0) $@"; echo "$@" >> install-arch.log; }
print_nosec() { echo "   $@"; echo "$@" >> install-arch.log; }
print_nosec_err() { echo "   $(tput setaf 1)$@$(tput sgr0)" 1>&2; echo "$@" >> install-arch.log; }
print_subsec() { echo "  $(tput setaf 4)-->$(tput sgr0) $@"; echo "$@" >> install-arch.log; }
print_nosubsec() { echo "      $@"; echo "$@" >> install-arch.log; }
print_nosubsec_err() { echo "      $(tput setaf 1)$@$(tput sgr0)" 1>&2; echo "$@" >> install-arch.log; }

show_help() {
    echo "Harrison's Arch Linux installer script."
    echo 'Usage: install-arch.sh [...]'
    echo
    echo "OPTIONS:"
    echo "--finish              Unmount any partitions and close encrypted devices for reboot."
    echo "--mount               Mount & chroot an existing filesystem instead of installing."
    echo "-b, --no-bootloader   Don't install/configure the bootloader. Implies \"-f\" and \"-P\"."
    echo "-f, --no-filesystems  Don't setup partition filesystems (or encryption). Implies \"-P\"."
    echo "-h, --help            Show help and usage information."
    echo "-i, --no-initramfs    Don't configure the Initial RAM Filesystem. Implies \"-f\" and \"-P\"."
    echo "-m, --no-rankmirrors  Don't rank pacman mirrorlist during setup stage."
    echo "-p, --no-packages     Don't install packages. Implies \"-f\" and \"-P\"."
    echo "-P, --no-partitions   Don't setup partitions."
    echo "-u, --no-users        Don't setup user accounts (or root's password)."
}

# ----------------------------



# ------ Parse Arguments -----

EC=10

short_options="b,f,h,i,m,p,P,u"
long_options="finish,mount,no-bootloader,no-filesystems,help,no-initramfs,no-rankmirrors,no-packages,no-partitions,no-users"

getopt --test > /dev/null
if [ "$?" -ne 4 ]; then
    print_nosec_err "Unable to parse command-line arguments - enhanced getopt does not exist on the system."
    exit $EC
fi

args=$(getopt --options=$short_options --longoptions=$long_options --name "install-arch.sh" -- "$@")
if [ "$?" -ne 0 ]; then
    exit $EC
fi

eval set -- "$args"
while true; do
    case "$1" in
        -b|--no-bootloader)
            do_bootloader=false
            shift
            ;;
        -f|--no-filesystems)
            do_filesystems=false
            shift
            ;;
        --finish)
            finish_installation
            exit 0
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--no-initramfs)
            do_initramfs=false
            shift
            ;;
        --mount)
            mount_installation
            exit 0
            ;;
        -m|--no-rankmirrors)
            do_rankmirrors=false
            shift
            ;;
        -p|--no-packages)
            do_packages=false
            shift
            ;;
        -P|--no-partitions)
            do_partitions=false
            shift
            ;;
        -u|--no-users)
            do_users=false
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            print_nosec_err "Unable to parse command-line arguments - encountered * in argument case."
            exit $EC
            ;;
    esac
done

# Blank the log file.
echo -n '' > install-arch.log

print_log "----- CLI Options -----"
if [ "$do_bootloader" != "false" ]; then print_log "Configure bootloader: true"; else print_log "Configure bootloader: false"; fi
if [ "$do_filesystems" != "false" ]; then print_log "Configure filesystems: true"; else print_log "Configure filesystems: false"; fi
if [ "$do_initramfs" != "false" ]; then print_log "Configure initramfs: true"; else print_log "Configure initramfs: false"; fi
if [ "$do_rankmirrors" != "false" ]; then print_log "Rank mirrorlist: true"; else print_log "Rank mirrorlist: false"; fi
if [ "$do_packages" != "false" ]; then print_log "Install packages: true"; else print_log "Install packages: false"; fi
if [ "$do_partitions" != "false" ]; then print_log "Configure partitions: true"; else print_log "Configure partitions: false"; fi
if [ "$do_users" != "false" ]; then print_log "Configure users: true"; else print_log "Configure users: false"; fi
print_log "-----------------------"

# ----------------------------



# ------ Initial Setup -------

EC=2

print_sec "Performing initial setup..."

print_subsec "Verifying root privileges..."
curr_user=$(whoami)
if [ "$curr_user" != "root" ]; then
    print_nosubsec_err "Error: This script must be run as root."
    exit $EC
fi

{% if not installer.disable_uefi is defined or not installer.disable_uefi %}
print_subsec "Verifying UEFI mode..."
if [ ! -d "$efivars_dir" ]; then
    print_nosubsec_err "Error: Unable to verify UEFI mode - \"$efivars_dir\" does not exist."
    exit $EC
elif [ -z "$(ls -A $efivars_dir)" ]; then
    print_nosubsec_err "Error: Unable to verify UEFI mode - \"$efivars_dir\" is empty."
    exit $EC
fi
{% endif %}

print_subsec "Verifying internet connection..."
if ! host "archlinux.org" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to verify internet connection - host lookup for \"archlinux.org\" failed."
    exit $EC
elif ! wget -q --spider "archlinux.org"; then
    print_nosubsec_err "Error: Unable to verify internet connection - connection to \"archlinux.org\" failed."
    exit $EC
fi

print_subsec "Updating system clock..."
if ! timedatectl set-ntp true >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to update system clock - {{ n0ec }}"
    exit $EC
fi

if [ "$do_rankmirrors" != "false" ]; then
    print_subsec "Backing-up previous pacman mirror list..."
    if ! cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to back-up previous pacman mirror list - {{ n0ec }}"
        exit $EC
    fi
     
    print_subsec "Installing rankmirrors package..."
    if ! pacman -Sy pacman-contrib --noconfirm >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to install rankmirrors package - {{ n0ec }}"
        exit $EC
    fi
     
    print_subsec "Fetching and ranking fastest mirrors..."
    if ! curl -s "$mirrorlist_url" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - >/etc/pacman.d/mirrorlist 2>/dev/null; then
        print_nosubsec_err "Error: Unable to generate pacman mirrorlist - {{ n0ec }}"
        exit $EC
    fi
fi

print_subsec "Disabling swap..."
swapoff --all >/dev/null 2>&1

# ----------------------------



# ----- Disk Partitioning ----

EC=3

if [ "$do_bootloader" != "false" ] && [ "$do_filesystems" != "false" ] && [ "$do_initramfs" != "false" ] && [ "$do_packages" != "false" ] && [ "$do_partitions" != "false" ]; then

print_sec "Partitioning {{ installer.drive }}..."

if [ -d '/mnt' ]; then
    print_subsec "Cleaning mount points from previous runs..."
    umount -R /mnt >> install-arch.log 2>&1
    rm -rf /mnt >> install-arch.log 2>&1
fi

print_subsec "Probing existing disk partitions..."
if ! partprobe "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to probe existing disk partitions - {{ n0ec }}"
    exit $EC
fi

print_subsec "Cleaning partition table..."
if ! sgdisk --zap-all "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to zap partition table - {{ n0ec }}"
    exit $EC
fi
if ! sgdisk --clear "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to clear partition table - {{ n0ec }}"
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
    print_nosubsec_err "Error: Unable to create new partition - {{ n0ec }}"
    exit $EC
fi
if ! sgdisk --typecode={{ loop.index }}:{{ p.typecode|default('8300', true) }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to set partition type - {{ n0ec }}"
    exit $EC
fi
{% if p.encrypted is defined and p.encrypted %}
{% set pname = p.name + '-encrypted' %}
{% else %}
{% set pname = p.name %}
{% endif %}
if ! sgdisk --change-name={{ loop.index }}:{{ pname }} "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to set partition name - {{ n0ec }}"
    exit $EC
fi
{% endfor %}

print_subsec "Informing kernel of partition changes..."
if ! partprobe "{{ installer.drive }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to inform kernel of partition changes - {{ n0ec }}"
    exit $EC
fi

fi

# ----------------------------



# ----- Encryption Setup -----

EC=4

if [ "$do_bootloader" != "false" ] && [ "$do_filesystems" != "false" ] && [ "$do_initramfs" != "false" ] && [ "$do_packages" != "false" ]; then

cryptcmd='cryptsetup luksFormat --align-payload=8192 --verify-passphrase'
cryptswapcmd='cryptsetup open --type plain --key-file /dev/urandom'

{% if installer.system_encrypted is defined and installer.system_encrypted %}

print_sec "Encrypting partitions..."

{% for p in installer.partitions %}
{% if p.encrypted is defined and p.encrypted %}
print_subsec "Encrypting \"{{ p.name }}\" partition..."
if [ -e "/dev/mapper/{{ p.name }}" ]; then
    cryptsetup close "{{ p.name }}" >/dev/null 2>&1
    cryptsetup erase "{{ p.name }}" >/dev/null 2>&1
fi
{% if p.typecode is defined and p.typecode == '8200' %}
if ! $cryptswapcmd "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}" "{{ p.name }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to encrypt swap partition - {{ n0ec }}"
    exit $EC
fi
{% else %}
cipher="{{ p.cipher|default('aes-xts-plain64', true) }}"
keysize="{{ p.keysize|default('256', true) }}"
if ! $cryptcmd --cipher $cipher --key-size $keysize "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}"; then
    print_nosubsec_err "Error: Unable to encrypt partition - {{ n0ec }}"
    exit $EC
fi
if ! cryptsetup open "/dev/disk/by-partlabel/{{ p.name + '-encrypted' }}" "{{ p.name }}"; then
    print_nosubsec_err "Error: Unable to unseal encrypted partition - {{ n0ec }}"
    exit $EC
fi
{% endif %}
{% endif %}
{% endfor %}

{% endif %}

fi

# ----------------------------



# ----- Filesystem Setup -----

EC=5

if [ "$do_bootloader" != "false" ] && [ "$do_filesystems" != "false" ] && [ "$do_initramfs" != "false" ] && [ "$do_packages" != "false" ]; then

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
    print_nosubsec_err "Error: Unable to create filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'ext4' %}
if ! mkfs.ext4 "{{ partition_path }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to create filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'fat32' %}
if ! mkfs.vfat -F 32 -n "{{ fs.name }}" "{{ partition_path }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to create filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'swap' %}
if ! mkswap --label "{{ fs.name }}" "{{ partition_path }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to create filesystem - {{ n0ec }}"
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
    print_nosubsec_err "Error: Unable to create filesystem mount directory - {{ n0ec }}"
    exit $EC
fi
{% endif %}
{% if fs.kind == 'btrfs' %}
if ! mount -t btrfs "LABEL={{ fs.name }}" "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to mount filesystem - {{ n0ec }}"
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
    print_nosubsec_err "Error: Unable to create subvolume \"{{ sv.name }}\" - {{ n0ec }}"
    exit $EC
fi
{% endfor %}
print_subsec "[{{ fs.kind }}] Mounting \"{{ fs.name }}\" filesystem subvolumes..."
if ! umount -R "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to unmount subvolume owner - {{ n0ec }}"
    exit $EC
fi
{% for sv in fs.subvolumes %}
{% if sv.mountpoint is defined %}
if [ -d "{{ sv.mountpoint }}" ]; then
    rm -rf "{{ sv.mountpoint }}" >> install-arch.log 2>&1
fi
if ! mkdir -p "{{ sv.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to create filesystem subvolume mount directory - {{ n0ec }}"
    exit $EC
fi
mountcmd="mount -t btrfs -o subvol={{ sv.name }},{{ sv.mount_options|default('defaults', true) }}"
if ! $mountcmd "LABEL={{ fs.name }}" "{{ sv.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to mount subvolume \"{{ sv.name }}\" - {{ n0ec }}"
    exit $EC
fi
{% endif %}
{% endfor %}
{% elif fs.kind == 'ext4' %}
if ! mount "LABEL={{ fs.name }}" "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to mount filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'fat32' %}
if ! mount "LABEL={{ fs.name }}" "{{ fs.mountpoint }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to mount filesystem - {{ n0ec }}"
    exit $EC
fi
{% elif fs.kind == 'swap' %}
if ! swapon -L "{{ fs.name }}" >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to mount filesystem - {{ n0ec }}"
    exit $EC
fi
{% endif %}
{% endif %}
{% endfor %}

fi

# ----------------------------



# ------ Install System ------

EC=6

if [ "$do_packages" != "false" ]; then
    print_sec "Installing system packages..."
    if ! pacstrap /mnt {{ installer.packages|join(' ') }} >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to install system packages - {{ n0ec }}"
        exit $EC
    fi
fi
    
# ----------------------------



# --- System Configuration ---

EC=7

print_sec "Configuring system..."

chroot='arch-chroot /mnt'

print_subsec "Generating filesystem table..."
if ! genfstab -U /mnt >> /mnt/etc/fstab 2>>install-arch.log; then
    print_nosubsec_err "Error: Unable to generate filesystem table - {{ n0ec }}"
    exit $EC
fi

print_subsec "Configuring filesystem table..."
{% if installer.swap_encrypted is defined and installer.swap_encrypted %}
swap_fstab="/dev/mapper/swap none swap defaults 0 0"
{% else %}
swap_fstab=""
{% endif %}
if ! sed -i -e "s:UUID.*swap.*:${swap_fstab}:" /mnt/etc/fstab >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to configure filesystem table - unable to append swap options."
    exit $EC
fi

{% if installer.swap_encrypted is defined and installer.swap_encrypted %}
{% if not installer.swap_partition is defined %}
{% do raise('swap partition is not specified') %}
{% endif %}
print_subsec "Configuring swap encryption..."
swap_device="$(readlink -f /dev/disk/by-partlabel/{{ installer.swap_partition }})"
swap_crypttab="{{ installer.swap_partition }} ${swap_device} /dev/urandom swap,cipher=aes-xts-plain64,size=256"
if ! echo "$swap_crypttab" >> /mnt/etc/crypttab 2>>install-arch.log; then
    print_nosubsec_err "Error: Unable to configure swap encryption - {{ n0ec }}"
    exit $EC
fi
{% endif %}

print_subsec "Setting time zone..."
if ! $chroot ln -sf "/usr/share/zoneinfo/{{ installer.timezone|default('America/Chicago', true) }}" /etc/localtime >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to set time zone - {{ n0ec }}"
    exit $EC
fi

print_subsec "Setting hardware clock..."
if ! $chroot hwclock --verbose --systohc >> install-arch.log 2>&1; then
    print_nosubsec "Warning: Unable to set hardware clock - {{ n0ec }}"
fi

print_subsec "Generating localization..."
if ! echo 'en_US.UTF-8 UTF-8' > /mnt/etc/locale.gen && $chroot locale-gen >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to generate localization - {{ n0ec }}"
    exit $EC
fi

print_subsec "Setting system language..."
if ! echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf; then
    print_nosubsec_err "Error: Unable to set system language - {{ n0ec }}"
    exit $EC
fi

print_subsec "Setting TTY font..."
cat > /mnt/etc/vconsole.conf 2>>install-arch.log <<EOF
FONT=ter-132n
FONT_MAP=8859-2
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Error: Unable to set TTY font - unable to write to \"/etc/vconsole.conf\"."
    exit $EC
fi

print_subsec "Setting system hostname..."
if ! echo '{{ installer.hostname }}' > /mnt/etc/hostname && $chroot hostname '{{ installer.hostname }}' >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to set system hostname - {{ n0ec }}"
    exit $EC
fi

print_subsec "Adding system hostname to hosts file..."
hosts_entry='127.0.0.1 {{ installer.hostname }}.localdomain {{ installer.hostname }}'
if ! echo "$hosts_entry" >> /mnt/etc/hosts 2>>install-arch.log; then
    print_nosubsec_err "Error: Unable to add system hostname to hosts file - {{ n0ec }}"
    exit $EC
fi

if [ "$do_users" != "false" ]; then
    print_subsec "Setting root user account password..."
    if ! $chroot passwd; then
        print_nosubsec_err "Error: Unable to set root user account password - {{ n0ec }}"
        exit $EC
    fi
     
    print_subsec "Creating \"{{ installer.username }}\" user account..."
    useraddcmd='useradd -m -g wheel -s {{ installer.shell }} {{ installer.username }}'
    if ! $chroot $useraddcmd >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to create primary user account - {{ n0ec }}"
        exit $EC
    fi
     
    print_subsec "Setting \"{{ installer.username }}\" user account password..."
    if ! $chroot passwd "{{ installer.username }}"; then
        print_nosubsec_err "Error: Unable to set primary user account password - {{ n0ec }}"
        exit $EC
    fi
     
    print_subsec "Creating user home directories..."
    for d in {{ installer.user_directories|join(' ') }}; do
        if ! mkdir -p "/mnt/home/{{ installer.username }}/$d" >> install-arch.log 2>&1; then
            print_nosubsec_err "Error: Unable to create directory \"/mnt/home/{{ installer.username }}/$d\" - {{ n0ec }}"
            exit $EC
        fi
    done
     
    print_subsec "Setting \"{{ installer.username }}\" user account home permissions..."
    if ! $chroot chown -R {{ installer.username }}:wheel "/home/{{ installer.username }}" >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to set primary user account home permissions - {{ n0ec }}"
        exit $EC
    fi
fi

print_subsec "Configuring sudo..."
cat > /mnt/etc/sudoers 2>>install-arch.log <<EOF
root ALL=(ALL) ALL
{{ installer.username }} ALL=(ALL) NOPASSWD: ALL
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Unable to configure sudo - unable to write to \"/etc/sudoers\"."
    exit $EC
fi

# ----------------------------



# --- Create RAM Filesystem --

EC=8

if [ "$do_initramfs" != "false" ]; then

print_sec "Configuring & Creating Initial RAM Filesystem..."

print_subsec "Writing initramfs configuration script..."
cat > /tmp/config-initramfs.py 2>>install-arch.log <<EOF
#!/usr/bin/env python3
import os
import re
import sys

try:
  with open('/mnt/etc/mkinitcpio.conf', 'r') as f:
    conf = f.read()
except Execption as e:
  print('Error: Unable to open "/mnt/etc/mkinitcpio.conf" - ' + str(e) + '.')
  sys.exit(1)

hooks_match = re.compile(r'^HOOKS=\([\w\s]+\)$', re.M).search(conf)
if not hooks_match:
  print('Error: Unable to locate "HOOKS" specification in "/mnt/etc/mkinitcpio.conf".')
  sys.exit(2)

new_conf = conf.replace(hooks_match.group(0), "HOOKS=({{ installer.mkinitcpio.hooks|join(' ') }})")

try:
  with open('/mnt/etc/mkinitcpio.conf', 'w') as f:
    f.write(new_conf)
except Exception as e:
  print('Error: Unable to write "/mnt/etc/mkinitcpio.conf" - ' + str(e) + '.')
  sys.exit(3)

sys.exit(0)
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Error: Unable to write initramfs configuration script - {{ n0ec }}"
    exit $EC
fi

chmod +x /tmp/config-initramfs.py >> install-arch.log 2>&1

print_subsec "Configuring initramfs..."
if ! /tmp/config-initramfs.py >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to configure initramfs - {{ n0ec }}"
    exit $EC
fi

print_subsec "Generating initramfs..."
if ! $chroot mkinitcpio --nocolor -P >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to generate initramfs - {{ n0ec }}"
    exit $EC
fi

fi

# ----------------------------



# ----- Setup Bootloader -----

EC=9

if [ "$do_bootloader" != "false" ]; then

print_sec "Setting-up bootloader..."

{% if not installer.bootloader.kind is defined %}
{% do raise('bootloader kind not specified') %}
{% endif %}
{% if not installer.bootloader.root_partition is defined %}
{% do raise('bootloader root partition not specified') %}
{% endif %}
{% if not installer.bootloader.kernel_parameters is defined %}
{% do raise('bootloader kernel parameters not specified') %}
{% endif %}
{% if installer.system_encrypted is defined and installer.system_encrypted %}
boot_cryptroot="cryptdevice=PARTLABEL={{ installer.bootloader.root_partition + '-encrypted' }}:{{ installer.bootloader.root_partition }}"
boot_root="$boot_cryptroot root=/dev/mapper/{{ installer.bootloader.root_partition }}"
{% else %}
boot_root="root=PARTLABEL={{ installer.bootloader.root_partition }}"
{% endif %}

{% if installer.bootloader.kind == 'systemd-boot' %}
print_subsec "Installing bootloader (systemd-boot)..."
if ! $chroot bootctl --path=/boot install >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to install bootloader - {{ n0ec }}"
    exit $EC
fi
print_subsec "Configuring bootloader updates..."
if [ ! -d /mnt/etc/pacman.d/hooks ]; then
    if ! mkdir -p /mnt/etc/pacman.d/hooks >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to configure bootloader updates - unable to create package manager \"hooks\" directory."
        exit $EC
    fi
fi
cat > /mnt/etc/pacman.d/hooks/systemd-boot.hook 2>>install-arch.log <<EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating bootloader
When = PostTransaction
Exec = /usr/bin/bootctl update
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Error: Unable to configure bootloader updates - unable to write package manager hook."
    exit $EC
fi
print_subsec "Writing bootloader configuration..."
if [ ! -d /mnt/boot/loader ]; then
    if ! mkdir -p /mnt/boot/loader >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to write bootloader configuration - unable to create \"/boot/loader\" directory."
        exit $EC
    fi
fi
cat > /mnt/boot/loader/loader.conf 2>>install-arch.log <<EOF
default arch
timeout 1
editor 0
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Error: Unable to write bootloader configuration."
    exit $EC
fi
print_subsec "Writing bootloader entry..."
if [ ! -d /mnt/boot/loader/entries ]; then
    if ! mkdir -p /mnt/boot/loader/entries >> install-arch.log 2>&1; then
        print_nosubsec_err "Error: Unable to write bootloader entry - unable to create bootloader entries directory."
        exit $EC
    fi
fi
cat > /mnt/boot/loader/entries/arch.conf 2>>install-arch.log <<EOF
title   {{ installer.bootloader.title|default('Arch Linux', true) }}
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Error: Unable to write bootloader entry - unable to create \"/boot/loader/entries/arch.conf\"."
    exit $EC
fi
print_subsec "Configuring boot options..."
boot_options="options $boot_root rw {{ installer.bootloader.kernel_parameters }}"
if ! echo "$boot_options" >> /mnt/boot/loader/entries/arch.conf 2>>install-arch.log; then
    print_nosubsec_err "Error: Unable to configure boot options - unable to append \"/boot/loader/entries/arch.conf\"."
    exit $EC
fi
{% elif installer.bootloader.kind == 'grub' %}
print_subsec "Installing bootloader (grub)..."
if ! $chroot grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB >> install-arch.log 2>&1; then
    print_nosubsec_err "Error: Unable to install bootloader - {{ n0ec }}"
    exit $EC
fi
print_subsec "Writing bootloader configuration..."
cat > /mnt/etc/default/grub 2>>install-arch.log <<EOF
GRUB_CMDLINE_LINUX=""
GRUB_CMDLINE_LINUX_DEFAULT="$boot_root rw {{ installer.bootloader.kernel_parameters }}"
GRUB_DEFAULT=0
GRUB_DISABLE_RECOVERY=true
GRUB_DISTRIBUTOR="Arch"
{% if installer.system_encrypted is defined and installer.system_encrypted %}
GRUB_ENABLE_CRYPTODISK=y
{% endif %}
GRUB_GFXMODE=auto
GRUB_GFXPAYLOAD_LINUX=keep
GRUB_PRELOAD_MODULES="part_gpt part_msdos"
GRUB_TERMINAL_INPUT=console
GRUB_TIMEOUT=1
GRUB_TIMEOUT_STYLE=countdown
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Unable to write bootloader configuration - {{ n0ec }}"
    exit $EC
fi
print_subsec "Configuring bootloader..."
if ! $chroot grub-mkconfig -o /boot/grub/grub.cfg >> install-arch.log 2>&1; then
    print_nosubsec_err "Unable to configure bootloader - {{ n0ec }}"
    exit $EC
fi
{% else %}
{% do raise('unknown bootloader kind specified') %}
{% endif %}

fi

# ----------------------------



# -------- Completion --------

print_sec "Installation complete."

echo
echo "Ensure that the installation process was successful and then run the script again with the \"--finish\" flag before rebooting."
exit 0

# ----------------------------
