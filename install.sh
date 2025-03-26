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

echo
echo *---
echo *--- Formatting disks ---*
echo *---
echo

lsblk -o NAME,FSTYPE,SIZE
echo
read -r -p "Enter installation disk: " system_disk
echo
read -r -p "Enter swap size (in MiB): " swap_size

swap_calc=$(("$swap_size"+514))
root_calc=$(("$swap_calc"+1))

sgdisk -Z /dev/"$system_disk"
sgdisk -a 2048 -o /dev/"$system_disk"

sgdisk -n 1:1MiB:513MiB -c 1:"EFI" -t 1:ef00 /dev/"$system_disk"
sgdisk -n 2:514MiB:${swap_calc}MiB -c 2:"SWAP" -t 2:8200 /dev/"$system_disk"
sgdisk -n 3:${root_calc}MiB:0 -c 3:"ROOT" -t 3:8304 /dev/"$system_disk"

partprobe "$system_disk"

if [[ "/dev/${system_disk}" =~ "/dev/sd" ]] ; then
	efi_partition="/dev/${system_disk}1"
	swap_partition="/dev/${system_disk}2"
	root_partition="/dev/${system_disk}3"
	
elif [[ "${system_disk}" =~ "/dev/vd" ]] ; then
	efi_partition="/dev/${system_disk}1"
	swap_partition="/dev/${system_disk}2"
	root_partition="/dev/${system_disk}3"
else
	efi_partition="/dev/${system_disk}p1"
	swap_partition="/dev/${system_disk}p2"
	root_partition="/dev/${system_disk}p3"
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

while true; do
	echo
 	echo "Kernel options:"
  	echo
  	echo "linux"
  	echo "----------"
  	echo "linux-lts"
  	echo "----------"
  	echo "linux-zen"
  	echo
	read -r -p "Enter kernel: " kernel
	case $kernel in
		linux )		kernel="linux"
  				break
      				;;
		linux-lts )	kernel="linux-lts"
  				break
      				;;
		linux-zen )	kernel="linux-zen"
  				break
      				;;
		* )		echo "Enter valid option" >&2
  				;;
      esac
done
  

if [[ "$(grep vendor_id /proc/cpuinfo)" == *"AuthenticAMD"* ]]; then
	echo
	echo "An AMD CPU has been detected, the AMD microcode will be installed."
 	echo
	microcode="amd-ucode"
else
	echo
	echo "An Intel CPU has been detected, the Intel microcode will be installed."
 	echo
	microcode="intel-ucode"
fi

pacstrap /mnt base base-devel "$kernel" "$kernel"-headers "$microcode" linux-firmware
pacstrap /mnt p7zip zip unzip
pacstrap /mnt e2fsprogs dosfstools exfat-utils
pacstrap /mnt xdg-user-dirs
pacstrap /mnt git curl
pacstrap /mnt networkmanager bluez

systemctl enable NetworkManager --root=/mnt
systemctl enable bluetooth --root=/mnt

echo
echo *---
echo *--- Generating fstab ---*
echo *---
echo

genfstab -U /mnt > /mnt/etc/fstab

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
echo *--- Configuring hostname ---*
echo *---
echo

read -r -p "Enter hostname: " hostname

echo "$hostname" > /mnt/etc/hostname

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
echo *--- Configuring locale ---*
echo *---
echo

read -r -p "Enter locale: " locale

if [ "$locale" = "" ]; then
	sed -i "/^#en_US.UTF-8/s/^#//" /mnt/etc/locale.gen
else
	sed -i "/^#en_US.UTF-8/s/^#//" /mnt/etc/locale.gen
	sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
fi

arch-chroot /mnt locale-gen
echo "LANG=${locale}" > /mnt/etc/locale.conf

if [ "$locale" = "" ]; then
	echo FONT=cyr-sun16 > /mnt/etc/vconsole.conf
else
	echo
	read -r -p "Enter keymap: " keymap
	echo -e "KEYMAP=${keymap}\nFONT=cyr-sun16" > /mnt/etc/vconsole.conf
fi

echo
echo *---
echo *--- Configuring users ---*
echo *---
echo

read -r -p "Enter username: " username

arch-chroot /mnt useradd -m "$username"

echo
echo "Enter ${username} password"
arch-chroot /mnt passwd "$username"
echo
echo "Enter root password"
arch-chroot /mnt passwd

sed -i "/root ALL=(ALL:ALL) ALL/a${username} ALL=(ALL:ALL) NOPASSWD:ALL" /mnt/etc/sudoers

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
echo *--- Configuring systemd-boot ---*
echo *---
echo

arch-chroot /mnt bootctl --path=/boot install

cat > /mnt/boot/loader/loader.conf <<EOF
#timeout 10
#console-mode max
default ${kernel}.conf
EOF

root_UUID=$(blkid -o value -s UUID "$root_partition")

cat > /mnt/boot/loader/entries/"${kernel}".conf <<EOF
title Arch Linux (${kernel})
linux /vmlinuz-${kernel}
initrd /${microcode}.img
initrd /initramfs-${kernel}.img
options root=UUID=${root_UUID} rw quiet loglevel=3
EOF

echo
echo *---
echo *--- Finishing ---*
echo *---
echo

hypervisor=$(systemd-detect-virt)
case $hypervisor in
	kvm )		echo
 			echo "KVM has been detected, setting up guest tools."
    			echo
			pacstrap /mnt qemu-guest-agent
			systemctl enable qemu-guest-agent --root=/mnt
			;;
	vmware )	echo
 			echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
    			echo
			pacstrap /mnt open-vm-tools
			systemctl enable vmtoolsd --root=/mnt
			systemctl enable vmware-vmblock-fuse --root=/mnt
			;;
	oracle )	echo
 			echo "VirtualBox has been detected, setting up guest tools."
 			echo
			pacstrap /mnt virtualbox-guest-utils
			systemctl enable vboxservice --root=/mnt
			;;
	microsoft )	echo
 			echo "Hyper-V has been detected, setting up guest tools."
 			echo
			pacstrap /mnt hyperv
			systemctl enable hv_fcopy_daemon --root=/mnt
			systemctl enable hv_kvp_daemon --root=/mnt
			systemctl enable hv_vss_daemon --root=/mnt
			;;
	* )		echo
 			echo "Error: unknown hypervisor"
 			echo
			;;
esac

while true; do
	echo
 	echo "Editor options:"
  	echo
  	echo "vim"
  	echo "----------"
  	echo "nano"
  	echo "----------"
  	echo "emacs"
  	echo
	read -r -p "Enter text editor: " editor_selector
	case $editor_selector in
		vim )	echo
  			echo "The text editor vim will be installed"
     			echo
 			pacstrap /mnt vim
   			break
     			;;
		nano )	echo
  			echo "The text editor nano will be installed"
     			echo
       			pacstrap /mnt nano
	 		break
   			;;
		emacs )	echo
  			echo "The text editor emacs will be installed"
     			echo
 			pacstrap /mnt emacs
   			break
     			;;
       		* )	echo "Enter valid option" >&2
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
