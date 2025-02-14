#!/usr/bin/env bash

clear

timedatectl set-ntp true

sed -i "s/^#\(Color\)/\1\nILoveCandy/" /etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf

echo
echo *------------------------*
echo *--- Formatting disks ---*
echo *------------------------*
echo

read -r -p "Enter installation disk: " system_disk

read -r -p "Enter swap size (in MiB): " swap_size
swap_calc=$(("$swap_size"+513))

parted "$system_disk" mklabel gpt
parted "$system_disk" mkpart "EFI" fat32 1MiB 513MiB
parted "$system_disk" set 1 esp on
parted "$system_disk" mkpart "SWAP" linux-swap 513MiB "$swap_calc"MiB
parted "$system_disk" mkpart "ROOT" ext4 "$swap_calc"MiB 100%

if [[ "${system_disk}" =~ "/dev/sda" ]] ; then
	efi_partition="${system_disk}1"
	swap_partition="${system_disk}2"
	root_partition="${system_disk}3"
elif [[ "${system_disk}" =~ "/dev/vda" ]] ; then
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
echo *----------------------*
echo *--- Mounting disks ---*
echo *----------------------*
echo

mount "$root_partition" /mnt
swapon "$swap_partition"
mkdir /mnt/boot
mount -o fmask=0137,dmask=0027 "$efi_partition" /mnt/boot

echo
echo *------------------------------*
echo *--- Configuring mirrorlist ---*
echo *------------------------------*
echo

curl 'https://archlinux.org/mirrorlist/?country=RU&protocol=https&ip_version=4' | sed -e 's/^#Server/Server/' | rankmirrors -n 5 - > /mnt/etc/pacman.d/mirrorlist


echo
echo *--------------------------*
echo *--- Configuring pacman ---*
echo *--------------------------*
echo

sed -i "s/^#\(Color\)/\1\nILoveCandy/" /mnt/etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /mnt/etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' mnt/etc/pacman.conf

echo
echo *------------------------------*
echo *--- Installing base system ---*
echo *------------------------------*
echo

read -r -p "Type in your desired kernel: " kernel

if [[ "$(grep vendor_id /proc/cpuinfo)" == *"AuthenticAMD"* ]]; then
	echo "An AMD CPU has been detected, the AMD microcode will be installed."
	microcode="amd-ucode"
else
	echo "An Intel CPU has been detected, the Intel microcode will be installed."
	microcode="intel-ucode"
fi

pacstrap /mnt base base-devel "$kernel" "$kernel"-headers "$microcode" linux-firmware vim

hypervisor=$(systemd-detect-virt)
case $hypervisor in
	kvm )		echo "KVM has been detected, setting up guest tools."
			pacstrap /mnt qemu-guest-agent &>
			systemctl enable qemu-guest-agent --root=/mnt &>
			;;
	vmware )	echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
			pacstrap /mnt open-vm-tools >
			systemctl enable vmtoolsd --root=/mnt &>
			systemctl enable vmware-vmblock-fuse --root=/mnt &>
			;;
	oracle )	echo "VirtualBox has been detected, setting up guest tools."
			pacstrap /mnt virtualbox-guest-utils &>
			systemctl enable vboxservice --root=/mnt &>
			;;
	microsoft )	echo "Hyper-V has been detected, setting up guest tools."
			pacstrap /mnt hyperv &>
			systemctl enable hv_fcopy_daemon --root=/mnt &>
			systemctl enable hv_kvp_daemon --root=/mnt &>
			systemctl enable hv_vss_daemon --root=/mnt &>
			;;
	* )		echo "Error: unknown hypervisor"
			;;
esac

echo
echo *------------------------*
echo *--- Generating fstab ---*
echo *------------------------*
echo

genfstab -U /mnt >> /mnt/etc/fstab

echo
echo *----------------------------*
echo *--- Configuring hostname ---*
echo *----------------------------*
echo

read -r -p "Please enter desired host name: " hostname
echo "$hostname" > /mnt/etc/hostname

echo
echo *--------------------------*
echo *--- Configuring locale ---*
echo *--------------------------*
echo

read -r -p "Enter locale: " locale
read -r -p "Enter keyboard layout: " keymap

sed -i "/^#en_US.UTF-8/s/^#//" /mnt/etc/locale.gen
sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen
echo "LANG=${locale}.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=${keymap}" > /mnt/etc/vconsole.conf

echo
echo *------------------------*
echo *--- Configuring host ---*
echo *------------------------*
echo

echo -e "127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain   ${hostname}" > /mnt/etc/hosts

echo
echo *----------------------------*
echo *--- Configuring timezone ---*
echo *----------------------------*
echo

arch-chroot /mnt ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime

echo
echo *--------------------------------*
echo *--- Configuring system clock ---*
echo *--------------------------------*
echo

arch-chroot /mnt hwclock --systohc

echo
echo *--------------------------------*
echo *--- Configuring systemd-boot ---*
echo *--------------------------------*
echo

arch-chroot /mnt bootctl --path=/boot install

echo -e "#timeout 10
#console-mode max
default ${kernel}" > /mnt/boot/loader/loader.conf

root_UUID=$(blkid -o value -s UUID "${root_partition}")
echo -e "title Arch Linux (${kernel})
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=${root_UUID} rw quiet loglevel=3" > /mnt/boot/loader/entries/"${kernel}".conf

echo
echo *--------------------*
echo *--- Adding user ---*
echo *--------------------*
echo

read -r -p "Enter username: " username
arch-chroot /mnt useradd -m "$username"
echo """${username}"" ALL=(ALL:ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/"${username}"

echo
echo *--------------------------------------------------*
echo *--- Setting up "$username" and root passwords ---*
echo *--------------------------------------------------*
echo

arch-chroot /mnt passwd "$username"
arch-chroot /mnt passwd

echo
echo *-----------------*
echo *--- Finishing ---*
echo *-----------------*
echo

read -r -p "Enter networking utility: " network_choice    
case $network_choice in
	iwd )	echo "Installing and enabling IWD."
		pacstrap /mnt iwd >
		systemctl enable iwd --root=/mnt &>
		;;
	networkmanager ) echo "Installing and enabling NetworkManager."
		pacstrap /mnt networkmanager >
		systemctl enable NetworkManager --root=/mnt &>
		;;
	dhcpd ) echo "Installing dhcpcd."
		pacstrap /mnt dhcpcd >
		systemctl enable dhcpcd --root=/mnt &>
		;;
	* )	echo "Error: enter valid networking utility name"
		;;
esac

read -r -p "Enter graphics card (e.g: amd,intel,nvidia): " graphics_card
case $graphics_card in
	amd )		echo "Installing amd drivers."
			pacstrap /mnt mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon >
			;;
	intel ) 	echo "Installing intel drivers."
			pacstrap /mnt mesa lib32-mesa vulkan-intel lib32-vulkan-intel >
			;;
	nvidia )	echo "Installing & Configuring nvidia drivers."
			pacstrap /mnt nvidia-dkms nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia egl-wayland" >
			sed -i '7s/MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
			echo "options nvidia_drm modeset=1 fbdev=1" > /mnt/etc/modprobe.d/nvidia.conf"
			;;
	* )		echo "Error: enter valid graphics card name"
			;;
esac

exit
