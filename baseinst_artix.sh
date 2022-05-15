#!/bin/sh

partition() {
	# install the parted program to efficiently partition device
	pacman -S parted
	parted -l

	echo "Enter which device you want to install to..."
	read device

	parted -s $device mklabel gpt
	parted -s -a optimal $device mkpart "primary" "fat32" "0%" "513MiB"
	parted -s $device set 1 esp on

	parted -s -a optimal $device mkpart "primary" "ext4" "513MiB" "100%"
	parted -s $device set 2 lvm on
}

setup_encryption() {
	cryptsetup luksFormat -v --type=luks1 $device\2
	cryptsetup luksOpen $device cryptlvm

	pvcreate /dev/mapper/cryptlvm 
	vgcreate artixlvm /dev/mapper/cryptlvm
	
	lvcreate -L 50G artixlvm -n root
	lvcreate -L 2G artixlvm -n swap
	lvcreate -l 100%FREE artixlvm -n home
}

create_filesystems() {
	mkswap /dev/artixlvm/swap
	mkfs.fat -n ESP -F 32 $device\1
	mkfs.ext4 -L root /dev/artixlvm/root 
	mkfs.ext4 -L home /dev/artixlvm/home
}

mount_partitions() {
	mkdir -p /mnt/boot/efi
	mkdir -p /mnt/home

	swapon /dev/artixlvm/swap 
	mount $device\1 /mnt/boot/efi
	mount /dev/artixlvm/root /mnt
	mount /dev/artixlvm/home /mnt/home 
}

install_base() {
	# install the base system... kernel + init
	basestrap /mnt base base-devil runit elogind-runit
	basestrap /mnt linux-firmware linux linux-headers

	# generate fstab file and use device UUIDs
	fstabgen -U /mnt >> /mnt/etc/fstab

	# chroot into the system
	artix-chroot /mnt /bin/bash
}

config_sys_info() {
	echo -e "en_US.UTF-8 UTF-8" >> /etc/locale.gen
	locale-gen

	echo LANG=en_US.UTF-8 > /etc/locale.conf
	export LANG=en_US.UTF-8

	ln -s /usr/share/zoneinfo/America/Chicago /etc/localtime

	# set the hostname
	echo "artix" > /etc/hostname
}

config_initramfs() {
	sed -i "s/modconf block/modconf block encrypt lvm2 resume/g" /etc/mkinitcpio.conf

	pacman -S lvm2 lvm2-runit cryptsetup cryptsetup-runit
	# gen initramfs
	mkinitcpio -p linux
}

install_bootloader() {
	pacman -S grub efibootmgr
	pacman -S freetype2 gptfdisk

	sed -i "s/GRUB_CMDLINE_LINUX=\"\"/GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=`blkid -s UUID -o value $device\2`:cryptlvm\"/g" /etc/default/grub
	sed -i "s/#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/g" /etc/default/grub

	grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=artix --recheck $device
	grub-mkconffig -o /boot/grub/grub.cfg
}

partition
setup_encryption
create_filesystems
mount_partitions
install_base
config_sys_info
config_initramfs
install_bootloader
# prompt to set root pwd
passwd
