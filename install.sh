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
reflector --country Russia --delay 24 --score 10 --save /etc/pacman.d/mirrorlist

clear

echo
echo *---
echo *--- Formatting disks ---*
echo *---
echo

while true; do
        echo
        lsblk -o NAME,FSTYPE,SIZE
        echo
        read -r -p "Enter installation disk: " installation_disk_selector
                if [ ! -b "/dev/$installation_disk_selector" ]; then
                        echo "Error: $installation_disk_selector is not a viable block device" >&2
                        continue
                fi
                break
done

while true; do
        read -r -p "Enter swap size (in MiB): " swap_partition_size_selector
                if [[ -z "$swap_partition_size_selector" ]] || [[ "$swap_partition_size_selector"  -eq 0 ]]; then
                        echo "Error: partition size cannot be 0 or empty, enter valid option"
                        continue
                fi
                        swap_partition_size_calculated=$((514 + swap_partition_size_selector))
                        break
done

root_partition_size_calculated=$((1 + swap_partition_size_calculated))

sgdisk -Z /dev/"$installation_disk_selector"
sgdisk -a 2048 -o /dev/"$installation_disk_selector"

sgdisk -n 1:1MiB:513MiB -c 1:"EFI" -t 1:ef00 /dev/"$installation_disk_selector"
sgdisk -n 2:514MiB:"${swap_partition_size_calculated}"MiB -c 2:"SWAP" -t 2:8200 /dev/"$installation_disk_selector"
sgdisk -n 3:${root_partition_size_calculated}MiB:0 -c 3:"ROOT" -t 3:8304 /dev/"$installation_disk_selector"

partprobe /dev/"$installation_disk_selector"

if [[ "/dev/${installation_disk_selector}" =~ "/dev/sd" ]] ; then
        efi_partition="/dev/${installation_disk_selector}1"
        swap_partition="/dev/${installation_disk_selector}2"
        root_partition="/dev/${installation_disk_selector}3"

elif [[ "/dev/${installation_disk_selector}" =~ "/dev/vd" ]] ; then
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
        echo "Filesystem options: "
        echo
        echo "ext4"
        echo "----------"
        echo "xfs"
        echo
        read -r -p "Enter root filesystem: " root_filesystem_selector
                case $root_filesystem_selector in
                        ext4 )  echo
                                mkfs.fat -F 32 "$efi_partition"
                                mkswap "$swap_partition"
                                mkfs.ext4 "$root_partition"

                                root_filesystem_progs="e2fsprogs"

                                break
                                ;;
                        xfs )   echo
                                mkfs.fat -F 32 "$efi_partition"
                                mkswap "$swap_partition"
                                mkfs.xfs "$root_partition"

                                root_filesystem_progs="xfsprogs"

                                break
                                ;;
                        * )     echo
                                echo "Enter valid option" >&2
                                echo
                                ;;
                esac
done

clear

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

pacstrap /mnt base base-devel linux linux-headers "$microcode" linux-firmware
pacstrap /mnt "$root_filesystem_progs" dosfstools exfat-utils
pacstrap /mnt reflector git wget curl
pacstrap /mnt p7zip zip unzip
pacstrap /mnt vim

hypervisor=$(systemd-detect-virt)
case $hypervisor in
        kvm )           echo
                        echo "KVM has been detected, setting up guest tools."
                        echo
                        pacstrap /mnt qemu-guest-agent
                        systemctl enable qemu-guest-agent --root=/mnt
                        ;;
        vmware )        echo
                        echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
                        echo
                        pacstrap /mnt open-vm-tools
                        systemctl enable vmtoolsd --root=/mnt
                        systemctl enable vmware-vmblock-fuse --root=/mnt
                        ;;
        oracle )        echo
                        echo "VirtualBox has been detected, setting up guest tools."
                        echo
                        pacstrap /mnt virtualbox-guest-utils
                        systemctl enable vboxservice --root=/mnt
                        ;;
        microsoft )     echo
                        echo "Hyper-V has been detected, setting up guest tools."
                        echo
                        pacstrap /mnt hyperv
                        systemctl enable hv_fcopy_daemon --root=/mnt
                        systemctl enable hv_kvp_daemon --root=/mnt
                        systemctl enable hv_vss_daemon --root=/mnt
                        ;;
        * )             echo
                        echo "No Hypervisor has been detected"
                        echo
                        ;;
esac

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

arch-chroot /mnt ln -sf /usr/share/zoneinfo/"$(curl -s http://ip-api.com/line?fields=timezone)" /etc/localtime

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

while true; do
        read -r -p "Enter hostname: " hostname_selector
                if [ -z "$hostname_selector" ]; then
                        echo "Error: hostname cannot be empty, enter valid option"
                        continue
                fi
                        echo "$hostname_selector" > /mnt/etc/hostname
                        break
done

echo
echo *---
echo *--- Configuring hosts ---*
echo *---
echo

cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost.localdomain localhost
127.0.1.1   ${hostname_selector}.lan   ${hostname_selector}

::1         ip6-localhost       ip6-loopback
EOF

echo
echo *---
echo *--- Configuring locale ---*
echo *---
echo

read -r -p "Enter locale: " locale_selector

if [ -z "$locale_selector" ]; then
        sed -i "/^#en_US.UTF-8/s/^#//" /mnt/etc/locale.gen
else
        sed -i "/^#en_US.UTF-8/s/^#//" /mnt/etc/locale.gen
        sed -i "/^#$locale_selector/s/^#//" /mnt/etc/locale.gen
fi

arch-chroot /mnt locale-gen
echo "LANG=${locale_selector}" > /mnt/etc/locale.conf

while true; do
        if [ -z "$locale_selector" ]; then
                echo FONT=cyr-sun16 > /mnt/etc/vconsole.conf
                break
        else
                echo
                read -r -p "Enter keymap: " keymap_selector
                        if [ -z "$keymap_selector" ]; then
                                echo "Error: keymap cannot be empty, enter valid option"
                                continue
                        fi
                                echo -e "KEYMAP=${keymap_selector}\nFONT=cyr-sun16" > /mnt/etc/vconsole.conf
                                break
        fi
                continue
done

echo
echo *---
echo *--- Configuring users ---*
echo *---
echo

while true; do
        read -r -p "Add user?: " additional_user_selector
                case $additional_user_selector in
                        yes )   echo
                                read -r -p "Enter username: " additional_user_username

                                if [ -z "$additional_user_username" ]; then
                                        echo "Error: username cannot be empty, enter valid option"
                                        continue
                                fi

                                arch-chroot /mnt useradd -m "$additional_user_username"
                                break
                                ;;
                        no )    echo
                                break
                                ;;
                        * )     echo
                                echo "Enter valid option" >&2
                                ;;
                esac
done

if id "$additional_user_username" $>/dev/null; then
        while true; do
                echo
                echo "Enter {$additional_user_username} password"
                arch-chroot /mnt passwd "$additional_user_username"
                if [ "$additional_user_username" -eq 0 ]; then
                        echo "Password changed successfully"
                        break
                fi
                        echo "Error: password change failed, enter valid option"
                        sleep 1

                echo "{$additional_user_username} ALL=(ALL:ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/"$additional_user_username"

                echo
                echo "Enter root password"
                arch-chroot /mnt passwd root
                if [ $? -eq 0 ]; then
                        echo "Password changed successfully"
                        break
                fi
                        echo "Error: password change failed, enter valid option"
                        sleep 1
        done
fi
        while true; do
                echo
                echo "Enter root password"
                arch-chroot /mnt passwd root
                if [ $? -eq 0 ]; then
                        echo "Password changed successfully"
                        break
                fi
                        echo "Error: password change failed, enter valid option"
                        sleep 1
        done

echo
echo *---
echo *--- Configuring pacman ---*
echo *---
echo

sed -i "s/^#\(Color\)/\1\nILoveCandy/" /mnt/etc/pacman.conf
sed -i "s/^#\(ParallelDownloads\)/\1/" /mnt/etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /mnt/etc/pacman.conf

arch-chroot /mnt reflector --country Russia --delay 24 --score 10 --save /etc/pacman.d/mirrorlist

cat > /mnt/etc/xdg/reflector/reflector.conf <<EOF
--save /etc/pacman.d/mirrorlist
--country Russia
--score 10
--delay 24
EOF

systemctl enable reflector.timer --root=/mnt

echo
echo *---
echo *--- Configuring systemd-boot ---*
echo *---
echo

arch-chroot /mnt bootctl --path=/boot install

cat > /mnt/boot/loader/loader.conf <<EOF
#timeout 10
#console-mode max
default linux.conf
EOF

cat > /mnt/boot/loader/entries/linux.conf <<EOF
title Arch Linux (linux)
linux /vmlinuz-linux
initrd /${microcode}.img
initrd /initramfs-linux.img
options root=UUID=$(blkid -o value -s UUID "$root_partition") rw quiet
EOF

echo
echo *---
echo *--- Finishing ---*
echo *---
echo

echo
echo *---
echo *--- Cleaning up ---*
echo *---
echo

arch-chroot /mnt pacman -Syu
arch-chroot /mnt pacman -Scc

umount "${efi_partition}"
umount "${root_partition}"
swapoff "${swap_partition}"

echo
echo *---
echo *--- Finished, you may reboot now ---*
echo *---
echo

exit
