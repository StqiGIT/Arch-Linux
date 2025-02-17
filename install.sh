#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
        echo "This script must be ran by root" >&2
        exit 1
fi

clear

echo
echo *---
echo *--- Preparing ---*
echo *---
echo

timedatectl set-ntp true

sed -i "s/^#\(Color\)/\1\nILoveCandy/" /etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /etc/pacman.conf

curl "https://archlinux.org/mirrorlist/?country=RU&protocol=https&ip_version=4" -o /etc/pacman.d/mirrorlist

sed -i "s/^#\(Server\)/\1/" /etc/pacman.d/mirrorlist

echo
echo *---
echo *--- Formatting disks ---*
echo *---
echo

read -r -p "Enter installation disk: " system_disk
read -r -p "Enter swap size (in MiB): " swap_size

swap_calc=$(("$swap_size"+514))
root_calc=$(("$swap_calc"+1))

sgdisk -Z ${system_disk}
sgdisk -a 2048 -o ${system_disk}

sgdisk -n 1:1MiB:513MiB -c 1:"EFI" -t 1:ef00 ${system_disk}
sgdisk -n 2:514MiB:${swap_calc}MiB -c 2:"SWAP" -t 2:8200 ${system_disk}
sgdisk -n 3:${root_calc}MiB:0 -c 3:"ROOT" -t 3:8304 ${system_disk}

partprobe "$system_disk"

if [[ "${system_disk}" =~ "/dev/sd" ]] ; then
	efi_partition="${system_disk}1"
	swap_partition="${system_disk}2"
	root_partition="${system_disk}3"
elif [[ "${system_disk}" =~ "/dev/vd" ]] ; then
	efi_partition="${system_disk}1"
	swap_partition="${system_disk}2"
	root_partition="${system_disk}3"
else
	efi_partition="${system_disk}p1"
	swap_partition="${system_disk}p2"
	root_partition="${system_disk}p3"
fi

mkfs.fat -F 32 "$efi_partition"
mkswap "$swap_partition"
mkfs.ext4 "$root_partition"

echo
echo *---
echo *--- Mounting disks ---*
echo *---
echo

swapon "$swap_partition"

mount "$root_partition" /mnt

mkdir /mnt/boot

mount -o fmask=0137,dmask=0027 "$efi_partition" /mnt/boot

echo
echo *---
echo *--- Installing base system ---*
echo *---
echo

read -r -p "Type in your desired kernel (e.g: linux,linux-lts,linux-zen): " kernel

if [[ "$(grep vendor_id /proc/cpuinfo)" == *"AuthenticAMD"* ]]; then
	echo "An AMD CPU has been detected, the AMD microcode will be installed."
	microcode="amd-ucode"
else
	echo "An Intel CPU has been detected, the Intel microcode will be installed."
	microcode="intel-ucode"
fi

pacstrap /mnt base base-devel "$kernel" "$kernel"-headers "$microcode" linux-firmware vim
pacstrap /mnt p7zip zip unzip
pacstrap /mnt e2fsprogs dosfstools
pacstrap /mnt xdg-user-dirs
pacstrap /mnt git curl

echo
echo *---
echo *--- Configuring mirrorlist ---*
echo *---
echo

curl "https://archlinux.org/mirrorlist/?country=RU&protocol=https&ip_version=4" -o /mnt/etc/pacman.d/mirrorlist

sed -i "s/^#\(Server\)/\1/" /mnt/etc/pacman.d/mirrorlist

echo
echo *---
echo *--- Configuring pacman ---*
echo *---
echo

sed -i "s/^#\(Color\)/\1\nILoveCandy/" /mnt/etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /mnt/etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /mnt/etc/pacman.conf

echo
echo *---
echo *--- Generating fstab ---*
echo *---
echo

genfstab -U /mnt >> /mnt/etc/fstab

echo
echo *---
echo *--- Configuring hostname ---*
echo *---
echo

read -r -p "Please enter desired host name: " hostname

echo "$hostname" > /mnt/etc/hostname

echo
echo *---
echo *--- Configuring locale ---*
echo *---
echo

read -r -p "Enter locale: " locale
read -r -p "Enter keyboard layout: " keymap

sed -i "/^#en_US.UTF-8/s/^#//" /mnt/etc/locale.gen
sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen

arch-chroot /mnt locale-gen

echo "LANG=${locale}" > /mnt/etc/locale.conf

cat /mnt/etc/vconsole.conf <<EOF
KEYMAP=${keymap}
FONT=cyr-sun16
EOF

echo
echo *---
echo *--- Configuring hosts ---*
echo *---
echo

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain   ${hostname}
EOF

echo
echo *---
echo *--- Configuring timezone ---*
echo *---
echo

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime

echo
echo *---
echo *--- Configuring system clock ---*
echo *---
echo

arch-chroot /mnt hwclock --systohc

echo
echo *---
echo *--- Configuring systemd-boot ---*
echo *---
echo

arch-chroot /mnt bootctl --path=/boot install

cat > /mnt/boot/loader/loader.conf <<EOF
#timeout 10
#console-mode max
default ${kernel}.conf
EOF

root_UUID=$(blkid -o value -s UUID "${root_partition}")

cat > /mnt/boot/loader/entries/"${kernel}".conf <<EOF
title Arch Linux (${kernel})
linux /vmlinuz-${kernel}
initrd /${microcode}.img
initrd /initramfs-${kernel}.img
options root=UUID=${root_UUID} rw quiet loglevel=3
EOF

echo
echo *---
echo *--- Adding user ---*
echo *---
echo

read -r -p "Enter username: " username

arch-chroot /mnt useradd -m "$username"

sed -i "/root ALL=(ALL:ALL) ALL/a${username} ALL=(ALL:ALL) NOPASSWD:ALL" /mnt/etc/sudoers

echo
echo *---
echo *--- Setting up ${username} password and root password ---*
echo *---
echo

arch-chroot /mnt passwd "$username"
arch-chroot /mnt passwd

echo
echo *---
echo *--- Finishing ---*
echo *---
echo

hypervisor=$(systemd-detect-virt)
case $hypervisor in
	kvm )		echo "KVM has been detected, setting up guest tools."
			pacstrap /mnt qemu-guest-agent
			systemctl enable qemu-guest-agent --root=/mnt
			;;
	vmware )	echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
			pacstrap /mnt open-vm-tools
			systemctl enable vmtoolsd --root=/mnt
			systemctl enable vmware-vmblock-fuse --root=/mnt
			;;
	oracle )	echo "VirtualBox has been detected, setting up guest tools."
			pacstrap /mnt virtualbox-guest-utils
			systemctl enable vboxservice --root=/mnt
			;;
	microsoft )	echo "Hyper-V has been detected, setting up guest tools."
			pacstrap /mnt hyperv
			systemctl enable hv_fcopy_daemon --root=/mnt
			systemctl enable hv_kvp_daemon --root=/mnt
			systemctl enable hv_vss_daemon --root=/mnt
			;;
	* )		echo "Error: unknown hypervisor"
			;;
esac

while true; do
read -r -p "Enter text editor (e.g: vim,nano,emacs): " editor_selector
	case $editor_selector in
		vim )	echo "The text editor vim will be installed"
 			pacstrap /mnt vim
   			break
     			;;
		nano )	echo "The text editor nano will be installed"
       			pacstrap /mnt nano
	 		break
   			;;
		emacs )	echo "The text editor emacs will be installed"
 			pacstrap /mnt emacs
   			break
     			;;
       		* )	echo "Enter valid option" >&2
			;;
 	esac
done

while true; do
read -r -p "Enter networking utility (e.g: iwd,networkmanager,dhcpd): " network_selector    
	case $network_selector in
		iwd )			echo "Installing and enabling IWD."
					pacstrap /mnt iwd
					systemctl enable iwd --root=/mnt
     					break
					;;
		networkmanager )	echo "Installing NetworkManager."
					pacstrap /mnt networkmanager
					systemctl enable NetworkManager --root=/mnt
     					break
					;;
		dhcpd ) 		echo "Installing dhcpcd."
					pacstrap /mnt dhcpcd
					systemctl enable dhcpcd --root=/mnt
     					break
					;;
		* )			echo "Enter valid option" >&2
					;;
	esac
done

echo
echo *---
echo *--- Cleaning up ---*
echo *---
echo

arch-chroot /mnt pacman -Syu
arch-chroot /mnt pacman -Scc

umount ${efi_partition}
umount ${root_partition}
swapoff ${swap_partition}

echo
echo *---
echo *--- Finished, you may reboot now ---*
echo *---
echo

exit
