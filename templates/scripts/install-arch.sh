#!/bin/bash
# Installer script for my Arch Linux setup

trap "exit" INT


# ------ Configuration ------

efivars_dir="/sys/firmware/efi/efivars"

mirrorlist_url="https://www.archlinux.org/mirrorlist/?country=US&protocol=https&use_mirror_status=on"

dotfiles_repo="https://github.com/HarrisonTotty/dotfiles.git"

emacs_repo="https://github.com/HarrisonTotty/.emacs.d.git"

trizen_repo="https://aur.archlinux.org/trizen.git"

aur_packages="bdf-curie oomox paper-icon-theme-git polybar-git ttf-iosevka-ss02 urxvt-resize-font-git"

core_packages="base dialog intel-ucode sudo wpa_supplicant"

xorg_packages="xorg-server xorg-xinit xorg-xlsfonts xorg-xset"

dev_packages="autoconf crystal fakeroot gcc git make openssh patch python-setuptools shards"

ui_packages="alsa-utils arandr dunst feh i3-gaps i3lock lxappearance python-pywal rofi scrot"

app_packages="emacs neofetch rxvt-unicode xclip w3m zsh"

packages="$app_packages $core_packages $dev_packages $ui_packages $xorg_packages"

kernel_parameters="verbose"

timezone="America/Chicago"

# ---------------------------



# ----- Helper Functions -----

# Functions for printing colored text
print_sec() { echo "$(tput setaf 4)::$(tput sgr0) $@"; }
print_nosec() { echo "   $@"; }
print_nosec_err() { echo "   $(tput setaf 1)$@$(tput sgr0)" 1>&2; }
print_subsec() { echo "  $(tput setaf 4)-->$(tput sgr0) $@"; }
print_nosubsec() { echo "      $@"; }
print_nosubsec_err() { echo "      $(tput setaf 1)$@$(tput sgr0)" 1>&2; }

# Show help
show_help() {
    echo "Harrison's Arch Linux installer script"
    echo 'Usage: install-arch.sh [...]'
    echo
    echo "OPTIONS:"
    echo "-f, --no-format       Don't format the partitions."
    echo "-h, --help            Show help and usage information."
    echo "-i, --no-install      Don't install packages."
    echo "-p, --no-partition    Don't setup partitions."
}

# ----------------------------



# ----- Parse Arguments -----

print_sec "Parsing command-line arguments..."
getopt --test > /dev/null
if [ $? -ne 4 ]; then
    print_nosec_err "Unable to parse command-line arguments - enhanced getopt does not exist on the system."
    exit 1
fi
short_options="f,h,i,p"
long_options="no-format,help,no-install,no-partition"
args=$(getopt --options=$short_options --longoptions=$long_options --name "install-arch.sh" -- "$@")
if [ $? -ne 0 ]; then
    exit 1
fi
eval set -- "$args"
while true; do
    case "$1" in
        -f|--no-format)
            no_format=y
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -i|--no-install)
            no_install=y
            shift
            ;;
        -p|--no-partition)
            no_partition=y
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            print_nosec_err "Unable to parse command-line arguments - encountered * in argument case."
            exit 1
            ;;
    esac
done


# ---------------------------



# ------ Initial Setup -------

print_sec "Verifying UEFI mode..."
if [ ! -d "$efivars_dir" ]; then
    print_nosec_err "Unable to verify UEFI mode - \"$efivars_dir\" does not exist."
    exit 1
elif [ -z "$(ls -A $efivars_dir)" ]; then
    print_nosec_err "Unable to verify UEFI mode - \"$efivars_dir\" is empty."
    exit 1
fi

print_sec "Verifying internet connection..."
if ! host "archlinux.org" 2>&1 >/dev/null; then
    print_nosec_err "Unable to verify internet connection - host lookup for \"archlinux.org\" failed."
    exit 1
elif ! wget -q --spider "archlinux.org"; then
    print_nosec_err "Unable to verify internet connection - connection to \"archlinux.org\" failed."
    exit 1
fi

print_sec "Updating system clock..."
if ! timedatectl set-ntp true 2>&1 >/dev/null; then
    print_nosec_err "Unable to update system clock - process returned non-zero exit code."
    exit 1
fi

print_sec "Generating pacman mirror list..."
print_subsec "Backing-up previous mirror list..."
if ! cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup 2>&1 >/dev/null; then
    print_nosubsec_err "Unable to back-up previous mirror list."
    exit 1
fi
print_subsec "Installing rankmirrors package..."
if ! pacman -Sy pacman-contrib --noconfirm 2>&1 >/dev/null; then
    print_nosubsec_err "Unable to install rankmirrors package."
    exit 1
fi
print_subsec "Fetching and ranking fastest mirrors..."
if ! curl -s "$mirrorlist_url" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - 2>/dev/null > /etc/pacman.d/mirrorlist; then
    print_nosubsec_err "Unable to generate pacman mirrorlist - process returned non-zero exit code."
    exit 1
fi

# ----------------------------



# ----- Filesystem Setup -----

print_sec "Partitioning disks..."
print_subsec "Cleaning mount points..."
umount -R /mnt 2>/dev/null >/dev/null
rm -rf /mnt
print_subsec "Listing available disks..."
available_disks=$(lsblk -a -l -o name -n | grep -v loop)
archiso_disk=$(findmnt -f -n -o SOURCE --mountpoint /run/archiso/bootmnt | cut -d '/' -f 3)
echo "      ${available_disks}"
read -p "      $(tput setaf 4)Select disk:$(tput sgr0) " primary_disk
print_subsec "Verifying selected disk..."
if ! echo "$available_disks" | grep -q "$primary_disk"; then
    print_nosubsec_err "Unable to verify selected disk - selected disk does not exist."
    exit 1
elif df -h . | grep "/dev/" | cut -d ' ' -f 1 | grep -q "$primary_disk"; then
    print_nosubsec_err "Unable to verify selected disk - selected disk is currently in use."
    exit 1
elif echo "$archiso_disk" | grep -q "$primary_disk"; then
    print_nosubsec_err "Unable to verify selected disk - selected disk is same as archiso installer image."
    exit 1
fi
if [ "$no_partition" != "y" ]; then
    print_subsec "Clearing selected disk..."
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk /dev/${primary_disk} 2>&1 >/dev/null
      x # Enable expert mode
      z # Wipe partition tables
      y # Destroy GPT partition
      y # Destroy MBR partition
    EOF
    if [ $? -ne 0 ]; then
        echo "      $(tput setaf 3)WARNING: Unable to wipe previous GPT/MBR tables.$(tput sgr0)"
    fi
    print_subsec "Partitioning selected disk..."
    sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | gdisk /dev/${primary_disk} 2>&1 >/dev/null
      n # Create a new partition (/boot)
      1 # Designate it as partition number 1
        # Start at the beginning of the disk
      +1G # Make the partition 1GB in size
      ef00 # Designate it as an EFI System partition
      n # Create a new partition (/)
      2 # Designate it as partition number 2
        # Start after the previous partition
      +128G # Make the partition 128GB in size
      8304 # Designate it as a Linux x86-64 root partition
      n # Create a new partition (/var)
      3 # Designate it as parition number 3
        # Start after the previous partition
      +32G # Make the partition 32GB in size
      8300 # Designate it as a Linux filesystem partition
      n # Create a new partition (/home)
      4 # Designate it as partition number 4
        # Start after the previous partition
        # Fill up the rest of the disk
      8302 # Designate it as a Linux /home partition
      w # Write the changes to disk
      y # Confirm the changes and exit
    EOF
    if [ $? -ne 0 ]; then
        print_nosubsec_err "Unable to partition selected disk - partition process returned non-zero exit code."
        exit 1
    fi
else
    print_subsec "Skipping disk partitioning..."
fi

if [ "$no_format" != "y" ]; then
    print_sec "Formatting partitions..."
    if echo "$primary_disk" | grep -q "nvme"; then
        partition_prefix="p"
    else
        partition_prefix=""
    fi
    print_subsec "Formatting boot partition..."
    if ! mkfs.vfat -F 32 /dev/${primary_disk}${partition_prefix}1 2>&1 >/dev/null; then
        print_nosubsec_err "Unable to format partition - format process returned non-zero exit code."
        exit 1
    fi
    print_subsec "Formatting root partition..."
    if ! mkfs.ext4 /dev/${primary_disk}${partition_prefix}2 2>&1 >/dev/null; then
        print_nosubsec_err "Unable to format partition - format process returned non-zero exit code."
        exit 1
    fi
    print_subsec "Formatting var partition..."
    if ! mkfs.ext4 /dev/${primary_disk}${partition_prefix}3 2>&1 >/dev/null; then
        print_nosubsec_err "Unable to format partition - format process returned non-zero exit code."
        exit 1
    fi
    print_subsec "Formatting home partition..."
    if ! mkfs.ext4 /dev/${primary_disk}${partition_prefix}4 2>&1 >/dev/null; then
        print_nosubsec_err "Unable to format partition - format process returned non-zero exit code."
        exit 1
    fi
else
    print_sec "Skipping partition formatting..."
fi

print_sec "Mounting partitions..."
mkdir /mnt
print_subsec "Mounting root partition..."
if ! mount /dev/${primary_disk}${partition_prefix}2 /mnt; then
    print_nosubsec_err "Unable to mount partition - mounting process returned non-zero exit code."
    exit 1
fi
print_subsec "Mounting boot partition..."
mkdir /mnt/boot
if ! mount /dev/${primary_disk}${partition_prefix}1 /mnt/boot; then
    print_nosubsec_err "Unable to mount partition - mounting process returned non-zero exit code."
    exit 1
fi
print_subsec "Mounting var partition..."
mkdir /mnt/var
if ! mount /dev/${primary_disk}${partition_prefix}3 /mnt/var; then
    print_nosubsec_err "Unable to mount partition - mounting process returned non-zero exit code."
    exit 1
fi
print_subsec "Mounting home partition..."
mkdir /mnt/home
if ! mount /dev/${primary_disk}${partition_prefix}4 /mnt/home; then
    print_nosubsec_err "Unable to mount partition - mounting process returned non-zero exit code."
    exit 1
fi

# ----------------------------



# ------- Installation -------

if [ "$no_install" != "y" ]; then
    print_sec "Installing system..."
    if ! pacstrap /mnt $packages; then
        print_nosec_err "Unable to install system - pacstrap process returned non-zero exit code."
        exit 1
    fi
else
    print_sec "Skipping system installation..."
fi

# ----------------------------



# --- System Configuration ---

print_sec "Configuring system..."
print_subsec "Generating filesystem table..."
if ! genfstab -U /mnt 2>/dev/null >> /mnt/etc/fstab; then
    print_nosubsec_err "Unable to generate filesystem table - genfstab process returned non-zero exit code."
    exit 1
fi
print_subsec "Setting time zone..."
if ! arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime; then
    print_nosubsec_err "Unable to set time zone."
    exit 1
fi
print_subsec "Setting hardware clock..."
if ! arch-chroot /mnt hwclock --systohc; then
    print_nosubsec_err "Unable to set hardware clock."
    exit 1
fi
print_subsec "Generating localization..."
if ! echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen && arch-chroot /mnt locale-gen; then
    print_nosubsec_err "Unable to generate localization."
    exit 1
fi
print_subsec "Setting system language..."
if ! echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf; then
    print_nosubsec_err "Unable to set system language."
    exit 1
fi
print_subsec "Setting system hostname..."
read -p "      $(tput setaf 4)Enter system hostname:$(tput sgr0) " hostname
if ! echo "$hostname" > /mnt/etc/hostname; then
    print_nosubsec_err "Unable to set system hostname."
    exit 1
fi
print_subsec "Adding hostname to hosts file..."
if ! echo "127.0.1.1 $hostname.localdomain $hostname" >> /mnt/etc/hosts; then
    print_nosubsec_err "Unable to add hostname to hosts file."
    exit 1
fi
print_subsec "Setting root user account password..."
if ! arch-chroot /mnt passwd; then
    print_nosubsec_err "Unable to set root user account password."
    exit 1
fi
print_subsec "Creating primary user account..."
read -p "      $(tput setaf 4)Enter primary user account name:$(tput sgr0) " username
useradd_command="useradd -m -g wheel -s /bin/zsh $username"
if ! arch-chroot /mnt ${useradd_command}; then
    print_nosubsec_err "Unable to create primary user account."
    exit 1
fi
print_subsec "Setting primary user account password..."
userpwd_command="passwd $username"
if ! arch-chroot /mnt ${userpwd_command}; then
    print_nosubsec_err "Unable to set primary user account password."
    exit 1
fi
print_subsec "Cloning dotfiles repo..."
if ! git clone "$dotfiles_repo" "/mnt/home/$username/.config" >/dev/null; then
    print_nosubsec_err "Unable to clone dotfiles repo."
    exit 1
fi
print_subsec "Building primary user account home subdirectories..."
if ! mkdir -p "/mnt/home/$username/"{.cache/lock,docs,downloads,media/music,media/videos,pics/screenshots,projects}; then
    print_nosubsec_err "Unable to build primary user account home subdirectories."
    exit 1
fi
print_subsec "Setting primary user account home permissions..."
if ! chown -R "$username":wheel "/mnt/home/$username/"; then
    print_nosubsec_err "Unable to set primary user account home permissions."
    exit 1
fi

# ----------------------------



# ----- Bootloader Setup -----

print_sec "Setting-up bootloader..."
print_subsec "Getting root PARTUUID..."
root_partuuid=$(blkid -s PARTUUID -o value /dev/${primary_disk}${partition_prefix}2)
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Unable to obtain PARTUUID of root partition."
    exit 1
fi
print_subsec "Installing bootloader..."
if ! arch-chroot /mnt bootctl --path=/boot install >/dev/null; then
    print_nosubsec_err "Unable to install bootloader - bootctl returned non-zero exit code."
    exit 1
fi
print_subsec "Configuring automatic bootloader updates..."
mkdir -p /mnt/etc/pacman.d/hooks
cat > /mnt/etc/pacman.d/hooks/systemd-boot.hook << EOF
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
    print_nosubsec_err "Unable to configure automatic updates - unable to write pacman hook."
    exit 1
fi
print_subsec "Writing primary bootloader configuration..."
mkdir -p /mnt/boot/loader
cat > /mnt/boot/loader/loader.conf << EOF
default arch
timeout 1
editor 0
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Unable to write primary bootloader configuration."
    exit 1
fi
print_subsec "Writing primary bootloader entry..."
mkdir -p /mnt/boot/loader/entries
cat > /mnt/boot/loader/entries/arch.conf << EOF
title    Arch Linux
linux    /vmlinuz-linux
initrd   /intel-ucode.img
initrd   /initramfs-linux.img
EOF
if [ "$?" -ne 0 ]; then
    print_nosubsec_err "Unable to write primary bootloader entry - unable to write initial file."
    exit 1
fi
if ! echo "options  root=PARTUUID=$root_partuuid rw $kernel_parameters" >> /mnt/boot/loader/entries/arch.conf; then
    print_nosubsec_err "Unable to write primary bootloader entry - unable to append options specification."
    exit 1
fi

# ----------------------------



# -------- Completion --------

print_sec "Installation process complete..."
echo
echo "Ensure that the installation process was successful and then run \"umount -R /mnt\" before rebooting."

# ----------------------------