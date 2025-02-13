#!/usr/bin/env bash

clear

timedatectl set-ntp true

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
parted "$system_disk" mkpart "SerWAP" linux-swap 513MiB "$swap_calc"MiB
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

echo
echo *----------------------*
echo *--- Mounting disks ---*
echo *----------------------*
echo

mount "$root_partition" /mnt
swapon "$swap_partition"
mkdir /mnt/boot
mount "$efi_partition" /mnt/boot

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

read -r -p "Enter networking utility: " network_choice    
case $network_choice in
	iwd ) echo "Installing and enabling IWD."
		pacstrap /mnt iwd >/dev/null
		systemctl enable iwd --root=/mnt &>/dev/null
		;;
	networkmanager ) echo "Installing and enabling NetworkManager."
		pacstrap /mnt networkmanager >/dev/null
		systemctl enable NetworkManager --root=/mnt &>/dev/null
		;;
	dhcpd ) echo "Installing dhcpcd."
		pacstrap /mnt dhcpcd >/dev/null
		systemctl enable dhcpcd --root=/mnt &>/dev/null
		;;
esac

pacstrap /mnt base base-devel "$kernel" "$kernel"-headers "$microcode" linux-firmware

hypervisor=$(systemd-detect-virt)
case $hypervisor in
	kvm )		echo "KVM has been detected, setting up guest tools."
			pacstrap /mnt qemu-guest-agent &>/dev/null
			systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
			;;
	vmware )	echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
			pacstrap /mnt open-vm-tools >/dev/null
			systemctl enable vmtoolsd --root=/mnt &>/dev/null
			systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
			;;
	oracle )	echo "VirtualBox has been detected, setting up guest tools."
			pacstrap /mnt virtualbox-guest-utils &>/dev/null
			systemctl enable vboxservice --root=/mnt &>/dev/null
			;;
	microsoft )	echo "Hyper-V has been detected, setting up guest tools."
			pacstrap /mnt hyperv &>/dev/null
			systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
			systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
			systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
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

read -r -p "Enter locale(s): " locale
read -r -p "Enter keyboard layout: " keymap

sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
echo "LANG=${locale}.UTF-8" > /mnt/etc/locale.conf
echo "KEYMAP=${keymap}" > /mnt/etc/vconsole.conf

echo
echo *------------------------*
echo *--- Configuring host ---*
echo *------------------------*
echo

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

echo
echo *---------------------------------------------------------------------------------------*
echo *--- Configuring localtime, system clock, generating locale, installing systemd-boot ---*
echo *---------------------------------------------------------------------------------------*
echo

arch-chroot /mnt /bin/bash -e <<EOF

	ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

	hwclock --systohc

	locale-gen &>/dev/null

	bootctl --path=/boot install

EOF

echo
echo *--------------------------------*
echo *--- Configuring sysetmd-boot ---*
echo *--------------------------------*
echo

echo -e "#timeout 10
	#console-mode max
	default ${kernel}" > /boot/loader/loader.conf

root_UUID=$(blkid -o value -s UUID "${root_partition}")
echo -e "title Arch Linux (${kernel})
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID=${root_UUID} rw qiet loglevel=3" > /boot/loader/entries/"${kernel}".conf

echo
echo *--------------------*
echo *--- Addping user ---*
echo *--------------------*
echo

read -r -p "Enter username: " username
echo """${username}"" ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/"${username}"

echo
echo *--------------------------------------------------*
echo *--- Setting up "$username" and root passwords ---*
echo *--------------------------------------------------*
echo

passwd root
passwd "${username}"

exit
