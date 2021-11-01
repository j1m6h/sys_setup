#!/bin/sh

partition() {
	parted -a optimal $1
	unit mib
	mklabel gpt
	mkpart primary 1 513
	name 1 boot
	set 1 BOOT on
	mkpart primary 513 -1
	name 2 lvm
	set 2 lvm on
	quit
}

cryptsetup() {
	cryptsetup luksFormat /dev/$12
	cryptsetup luksOpen /dev/$12 cryptlvm

	lvm pvcreate /dev/mapper/cryptlvm
	vgcreate vg0 /dev/mapper/cryptlvm 
	lvcreate -L 50G -n root vg0
	lvcreate -L 2G -n swap vg0
	lvcreate -l 100%FREE -n home vg0
}

create_filesystems() {
	mkfs.fat -F32 /dev/$11
	mkfs.ext4 /dev/mapper/vg0-root 
	mkfs.ext4 /dev/mapper/vg0-home
	mkswap /dev/mapper/vg0-swap
	swapon /dev/mapper/vg0-swap
}

setup_mount_points() {
	mount /dev/mapper/vg0-root /mnt/gentoo
	mkdir /mnt/gentoo/home
	mount /dev/mapper/vg0-home /mnt/gentoo/home
	mkdir /mnt/gentoo/boot
	mount /dev/$11 /mnt/gentoo/boot
	cd /mnt/gentoo
}

setup_rootfs() {
	wget http://http://gentoo.osuosl.org/releases/amd64/autobuilds/current-stage3-amd64-hardened-openrc/stage3-amd64-hardened-openrc-20211101T001702Z.tar.xz
	tar xvpf stage3-amd64-hardened-openrc-20211101T001702Z.tar.xz --xattrs --numeric-owner

	if [ -f "/etc/portage/make.conf" ]; then
		rm /etc/portage/make.conf
	fi

	curl https://raw.githubusercontent.com/j1m6h/sys_setup/main/make.conf > /etc/portage/make.conf

	mkdir /mnt/gentoo/etc/portage/repos.conf 
	cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
	cp /etc/resolv.conf /mnt/gentoo/etc/resolv.conf

	mount -t proc /proc /mnt/gentoo/proc
	mount --rbind /sys /mnt/gentoo/sys
	mount --make-rslave /mnt/gentoo/sys
	mount --rbind /dev /mnt/gentoo/dev
	mount --make-rslave /mnt/gentoo/dev

	test -L /dev/shm && rm /dev/shm && mkdir /dev/shm
	mount -t tmpfs -o nosuid,nodev,noexec shm /dev/shm
	chmod 1777 /dev/shm

	chroot /mnt/gentoo /bin/bash
	source /etc/profile

	emerge-webrsync

	echo America/Chicago > /etc/timezone
	emerge --config sys-libs/timezone-data
	locale-gen
	env-update && source /etc/profile
}

setup_fstab() {
	echo "UUID=$(blkid -s UUID -o value $11)			/boot	vfat	defaults	1	2" >> /etc/fstab
	echo "UUID=$(blkid -s UUID -o value /dev/mapper/vg0-root)	/	ext4	defaults	0	1" >> /etc/fstab
	echo "UUID=$(blkid -s UUID -o value /dev/mapper/vg0-home)	/home	ext4	defaults	0	1" >> /etc/fstab 
	echo "UUID=$(blkid -s UUID -o value /dev/mapper/vg0-swap)	swap	swap	defaults	0	1" >> /etc/fstab
	echo "tmpfs							/tmp	tmpfs	size=4G		0	0" >> /etc/fstab
}

install_kernel_cryptsetup() {
	emerge sys-kernel/gentoo-sources
	emerge sys-kernel/genkernel
	emerge sys-fs/cryptsetup

	echo "All modern CPU's like Intel i7, Ryzen and even old Xen support AES-NI instruction set. AES-NI significantly improve encryption/decryption performance. To enable AES-NI support in Linux kernel, in Cryptographic API select AES-NI as build-in "
	genkernel --luks --lvm --no-zfs --menuconfig all
}

install_grub2() {
	echo "sys-boot/grub:2 device-mapper" >> /etc/portage/package.use/sys-boot
	emerge -av grub

	echo "GRUB_CMDLINE_LINUX=\"dolvm crypt_root=UUID=$(blkid -s UUID -o value $12) root=/dev/mapper/vg0-root root_trim=yes\"" >> /etc/default/grub 

	grub-install --target=x86_64-efi --efi-directory=/boot
	grub-mkconfig -o /boot/grub/grub.cfg
}

finish_up() {
	passwd
	rc-update add lvm default
	echo "Successfully installed gentoo linux without having to do much! Rebooting in 5 seconds..."
	sleep 5
	reboot
}

partition
cryptsetup
create_filesystems
setup_mount_points
setup_rootfs
setup_fstab
install_kernel_crypsetup
install_grub2
finish_up
