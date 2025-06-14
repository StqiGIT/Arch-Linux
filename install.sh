#!/usr/bin/env bash

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root" >&2
	exit 1
fi

clear

echo
echo "---"
echo "--- Preparing System ---"
echo "---"
echo

timedatectl set-ntp true
sed -i "s/^#\(Color\)/\1\nILoveCandy/" /etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /etc/pacman.conf
reflector --country Russia --delay 24 --score 10 --save /etc/pacman.d/mirrorlist

clear

echo
echo "---"
echo "--- Disk Partitioning ---"
echo "---"
echo

while true; do
	echo
	lsblk -o NAME,FSTYPE,SIZE
	echo
	read -r -p "Select installation disk: " installation_disk_selector
 	echo
	if [ ! -b "/dev/$installation_disk_selector" ]; then
		echo "Error: Not a valid block device: $installation_disk_selector" >&2
  		echo
		continue
	fi
		break
done

while true; do
	echo
	read -r -p "Enter swap size (MiB): " swap_partition_size_selector
 	echo
  	if [[ -z "$swap_partition_size_selector" ]] || [[ "$swap_partition_size_selector" -eq 0 ]]; then
		echo "Error: Swap size must be greater than 0" >&2
  		echo
		continue
	fi
		swap_partition_size_calculated=$((514 + swap_partition_size_selector))
  		root_partition_size_calculated=$((1 + swap_partition_size_calculated))
		break
done

sgdisk -Z /dev/"$installation_disk_selector" > /dev/null
sgdisk -a 2048 -o /dev/"$installation_disk_selector" > /dev/null

sgdisk -n 1:1MiB:513MiB -c 1:"EFI" -t 1:ef00 /dev/"$installation_disk_selector" > /dev/null
sgdisk -n 2:514MiB:"${swap_partition_size_calculated}"MiB -c 2:"SWAP" -t 2:8200 /dev/"$installation_disk_selector" > /dev/null
sgdisk -n 3:${root_partition_size_calculated}MiB:0 -c 3:"ROOT" -t 3:8304 /dev/"$installation_disk_selector" > /dev/null

partprobe /dev/"$installation_disk_selector" > /dev/null

if [[ "/dev/${installation_disk_selector}" =~ "/dev/sd" ]]; then
    efi_partition="/dev/${installation_disk_selector}1"
    swap_partition="/dev/${installation_disk_selector}2"
    root_partition="/dev/${installation_disk_selector}3"
elif [[ "/dev/${installation_disk_selector}" =~ "/dev/vd" ]]; then
    efi_partition="/dev/${installation_disk_selector}1"
    swap_partition="/dev/${installation_disk_selector}2"
    root_partition="/dev/${installation_disk_selector}3"
else
    efi_partition="/dev/${installation_disk_selector}p1"
    swap_partition="/dev/${installation_disk_selector}p2"
    root_partition="/dev/${installation_disk_selector}p3"
fi

while true; do
	echo
	echo "Available filesystems:"
	echo
	echo "1) ext4"
	echo "2) xfs"
	echo
	read -r -p "Select root filesystem [1/2]: " root_filesystem_selector
 	echo
		case $root_filesystem_selector in
			1|ext4)
				mkfs.fat -F 32 "$efi_partition" > /dev/null
				mkswap "$swap_partition" > /dev/null
				mkfs.ext4 "$root_partition" > /dev/null
				root_filesystem_progs="e2fsprogs"
				break
			;;
			2|xfs)
				mkfs.fat -F 32 "$efi_partition" > /dev/null
				mkswap "$swap_partition" > /dev/null
				mkfs.xfs "$root_partition" > /dev/null
				root_filesystem_progs="xfsprogs"
				break
				;;
			*)
				echo "Invalid selection" >&2
    				echo
				;;
		esac
done

clear

echo
echo "---"
echo "--- Mounting Filesystems ---"
echo "---"
echo

swapon "$swap_partition"
mount "$root_partition" /mnt
mkdir -p /mnt/boot
mount -o fmask=0027,dmask=0137 "$efi_partition" /mnt/boot

clear

echo
echo "---"
echo "--- Installing Base System ---"
echo "---"
echo

if grep -q "AuthenticAMD" /proc/cpuinfo; then
	microcode="amd-ucode"
else
	microcode="intel-ucode"
fi

pacstrap /mnt base base-devel linux linux-headers "$microcode" linux-firmware > /dev/null
pacstrap /mnt "$root_filesystem_progs" dosfstools exfatprogs > /dev/null
pacstrap /mnt reflector git wget curl > /dev/null
pacstrap /mnt p7zip zip unzip > /dev/null
pacstrap /mnt openssh > /dev/null
pacstrap /mnt bash-completion vim > /dev/null

case $(systemd-detect-virt) in
	kvm)
		echo "KVM detected - installing guest tools"
		pacstrap /mnt qemu-guest-agent > /dev/null
		systemctl enable qemu-guest-agent --root=/mnt > /dev/null
		;;
	vmware)
		echo "VMware detected - installing guest tools"
		pacstrap /mnt open-vm-tools > /dev/null
		systemctl enable vmtoolsd --root=/mnt > /dev/null
		systemctl enable vmware-vmblock-fuse --root=/mnt > /dev/null
		;;
	oracle)
		echo "VirtualBox detected - installing guest tools"
		pacstrap /mnt virtualbox-guest-utils > /dev/null
		systemctl enable vboxservice --root=/mnt > /dev/null
		;;
	microsoft)
		echo "Hyper-V detected - installing guest tools"
		pacstrap /mnt hyperv > /dev/null
		systemctl enable hv_fcopy_daemon --root=/mnt > /dev/null
		systemctl enable hv_kvp_daemon --root=/mnt > /dev/null
		systemctl enable hv_vss_daemon --root=/mnt > /dev/null
		;;
	none)
		echo "Running on bare metal - no guest tools needed"
		;;
	*)
		echo "Unknown virtualization detected"
		;;
esac

clear

echo
echo "---"
echo "--- System Configuration ---"
echo "---"
echo

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt ln -sf "/usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone)" /etc/localtime
arch-chroot /mnt hwclock --systohc

while true; do
	echo
	read -r -p "Enter hostname: " hostname_selector
 	echo
	if [ -n "$hostname_selector" ]; then
		echo "$hostname_selector" > /mnt/etc/hostname
		break
	fi
		echo "Hostname cannot be empty" >&2
  		echo
done

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
127.0.1.1   $hostname_selector.lan $hostname_selector

::1         localhost ip6-localhost ip6-loopback
EOF

echo
read -r -p "Enter locale (leave empty for en_US.UTF-8): " locale_selector
echo
locale_selector=${locale_selector:-en_US.UTF-8}
sed -i "/^#${locale_selector}/s/^#//" /mnt/etc/locale.gen
arch-chroot /mnt locale-gen > /dev/null
echo "LANG=$locale_selector" > /mnt/etc/locale.conf

echo
read -r -p "Enter keymap (leave empty for default): " keymap_selector
echo
{
    [ -n "$keymap_selector" ] && echo "KEYMAP=$keymap_selector"
    echo "FONT=cyr-sun16"
} > /mnt/etc/vconsole.conf

if lsblk --discard | grep -q 'DISC'; then
	systemctl enable fstrim.timer --root=/mnt > /dev/null
fi

sed -i "s/^#\(Color\)/\1\nILoveCandy/" /mnt/etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /mnt/etc/pacman.conf

cat > /mnt/etc/xdg/reflector/reflector.conf <<EOF
--save /etc/pacman.d/mirrorlist
--country Russia
--score 10
--delay 24
EOF

systemctl enable reflector.timer --root=/mnt > /dev/null

clear

echo
echo "---"
echo "--- User Configuration ---"
echo "---"
echo

while true; do
        echo
        read -r -p "Create user? [y/N]: " create_user
        echo
        case $create_user in
                [Yy]*)
                        echo
                        read -p "Enter username to create/update: " username
                        echo

                        if ! arch-chroot /mnt id -u "$username" &>/dev/null; then
                                arch-chroot /mnt useradd -m -s /bin/bash "$username"
				echo "$username ALL=(ALL:ALL) ALL" > /mnt/etc/sudoers.d/"$username"
    				chmod 0440 /mnt/etc/sudoers.d/"$username"
                        fi

                        while true; do
                                arch-chroot /mnt passwd "$username" && break
                        done
                        break
                        ;;
                *)
                        break
                        ;;
        esac
done

echo
echo "Setting root password:"
echo
while ! arch-chroot /mnt passwd; do
	echo "Please try again" >&2
 	echo
done

clear

echo
echo "---"
echo "--- Network configuration ---"
echo "---"
echo

while true; do
        echo
        echo "Available network interfaces:"
        echo
        ip a
        echo
        
        read -p "Enter the network interface (or 'q' to quit): " interface
        
        [[ "$interface" == "q" ]] && break
        
        if ip link show "$interface" &>/dev/null; then
        	CONFIG_FILE="/mnt/etc/systemd/network/10-${interface}.network"
                
                cat > "$CONFIG_FILE" <<EOF
[Match]
Name=$interface

[Network]
DHCP=yes

[DHCP]
UseDNS=true
EOF
                
                chmod 644 "$CONFIG_FILE"
                systemctl enable systemd-networkd --root=/mnt > /dev/null
                systemctl enable systemd-resolved --root=/mnt > /dev/null
                
                echo
                echo "Successfully configured $interface"
                break
        else
                echo
                echo "ERROR: Interface '$interface' not found!" >&2
		echo
                read -p "Try again? [y/N]: " try_again
		echo
                [[ "$try_again" != [Yy]* ]] && break
        fi
done

clear

echo
echo "---"
echo "--- Finalizing Installation ---"
echo "---"
echo

arch-chroot /mnt bootctl --path=/boot install > /dev/null

cat > /mnt/boot/loader/loader.conf <<EOF
default arch
timeout 3
editor  no
EOF

cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /$microcode.img
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value "$root_partition") rw
EOF

arch-chroot /mnt pacman -Syu --noconfirm > /dev/null
arch-chroot /mnt pacman -Scc --noconfirm > /dev/null

umount -R /mnt > /dev/null
swapoff -a

clear

echo
echo "---"
echo "Installation complete!"
echo "You may now reboot your system."
echo "---"
echo

exit 0
