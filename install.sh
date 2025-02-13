#!/usr/bin/env bash

clear

timedatectl set-ntp true

virt_check () {
    hypervisor=$(systemd-detect-virt)
    case $hypervisor in
        kvm )   echo "KVM has been detected, setting up guest tools."
                pacstrap /mnt qemu-guest-agent &>/dev/null
                systemctl enable qemu-guest-agent --root=/mnt &>/dev/null
                ;;
        vmware  )   echo "VMWare Workstation/ESXi has been detected, setting up guest tools."
                    pacstrap /mnt open-vm-tools >/dev/null
                    systemctl enable vmtoolsd --root=/mnt &>/dev/null
                    systemctl enable vmware-vmblock-fuse --root=/mnt &>/dev/null
                    ;;
        oracle )    echo "VirtualBox has been detected, setting up guest tools."
                    pacstrap /mnt virtualbox-guest-utils &>/dev/null
                    systemctl enable vboxservice --root=/mnt &>/dev/null
                    ;;
        microsoft ) echo "Hyper-V has been detected, setting up guest tools."
                    pacstrap /mnt hyperv &>/dev/null
                    systemctl enable hv_fcopy_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_kvp_daemon --root=/mnt &>/dev/null
                    systemctl enable hv_vss_daemon --root=/mnt &>/dev/null
                    ;;
    esac
}

kernel_selector () {
    echo "List of kernels:"
    echo "1) Stable: Vanilla Linux kernel with a few specific Arch Linux patches applied"
    echo "2) Hardened: A security-focused Linux kernel"
    echo "3) Longterm: Long-term support (LTS) Linux kernel"
    echo "4) Zen Kernel: A Linux kernel optimized for desktop usage"
    echo "Please select the number of the corresponding kernel (e.g. 1): "
    read -r kernel_choice
    case $kernel_choice in
        1 ) kernel="linux"
            return 0;;
        2 ) kernel="linux-hardened"
            return 0;;
        3 ) kernel="linux-lts"
            return 0;;
        4 ) kernel="linux-zen"
            return 0;;
        * ) error_print "You did not enter a valid selection, please try again."
            return 1
    esac
}

microcode_detector () {
    CPU=$(grep vendor_id /proc/cpuinfo)
    if [[ "$CPU" == *"AuthenticAMD"* ]]; then
        echo "An AMD CPU has been detected, the AMD microcode will be installed."
        microcode="amd-ucode"
    else
        echo "An Intel CPU has been detected, the Intel microcode will be installed."
        microcode="intel-ucode"
    fi
}

network_selector () {
    echo "Network utilities:"
    echo "1) IWD: Utility to connect to networks written by Intel (WiFi-only, built-in DHCP client)"
    echo "2) NetworkManager: Universal network utility (both WiFi and Ethernet, highly recommended)"
    echo "3) dhcpcd: Basic DHCP client (Ethernet connections or VMs)"
    echo "Please select the number of the corresponding networking utility (e.g. 1): "
    read -r network_choice
    if ! ((1 <= network_choice <= 3)); then
        error_print "You did not enter a valid selection, please try again."
        return 1
    fi
    return 0
}

hostname_selector () {
    echo "Please enter the hostname: "
    read -r hostname
    if [[ -z "$hostname" ]]; then
        error_print "You need to enter a hostname in order to continue."
        return 1
    fi
    return 0
}

locale_selector () {
    echo "Please insert the locale you use (format: xx_XX. Enter empty to use en_US, or \"/\" to search locales): " locale
    read -r locale
    case "$locale" in
        '/') sed -E '/^# +|^#$/d;s/^#| *$//g;s/ .*/ (Charset:&)/' /etc/locale.gen | less -M
                clear
                return 1;;
        *)  if ! grep -q "^#\?$(sed 's/[].*[]/\\&/g' <<< "$locale") " /etc/locale.gen; then
                error_print "The specified locale doesn't exist or isn't supported."
                return 1
            fi
            return 0
    esac
}

keyboard_selector () {
    echo "Please insert the keyboard layout to use in console (enter empty to use US, or \"/\" to look up for keyboard layouts): "
    read -r kblayout
    case "$kblayout" in
        '/') localectl list-keymaps
             clear
             return 1;;
        *) if ! localectl list-keymaps | grep -Fxq "$kblayout"; then
               error_print "The specified keymap doesn't exist."
               return 1
           fi
        echo "Changing console layout to $kblayout."
        loadkeys "$kblayout"
        return 0
    esac
}

until kernel_selector do : ; done
until network_selector do : ; done
until hostname_selector do : ; done
until locale_selector do : ; done
until keyboard_selector do : ; done

echo "[INFO] Select desired disk for Arch installation"
echo "Disk(s) aviable:"
parted -l | awk '/Disk \//{ gsub(":","") ; print "- \033[93m"$2"\033[0m",$3}' | column -t
read -r -p "Please enter destination disk: " system_disk

echo "Disk ${system_disk} will be ERASED!"
read -r -p "Are you sure you want to proceed? (y/n)" system_disk_format

if [[ "${system_disk_format}" != "y" ]] ; then
    echo "Installation aborted!"
    exit 0
fi

echo "[INFO] Format ${system_disk} and create partitions"

read -r -p "Please enter swap size (in MiB): " swap_size
swap_calc=$((${swap_size}+512))

parted "${system_disk}" mklabel gpt
parted "${system_disk}" mkpart "EFI" fat32 1MiB 512MiB
parted "${system_disk}" set 1 esp on
parted "$Psystem_disk}" mkpart "SWAP" linux-swap 512MiB "$swap_calc"MiB
parted "${system_disk}" mkpart "ROOT" ext4 "$swap_calc"MiB 100%

if [[ "${system_disk}" =~ "/dev/{vd,sd}" ]] ; then
  efi_partition="${system_disk}1"
  swap_partition="${system_disk}2"
  root_partition="${system_disk}3"
else [[ "${system_disk}" =~ "/dev/nv" ]]; then
  efi_partiytion="${system_disk}p1"
  swap_partition="${system_disk}p2"
  root_partition="${system_disk}p3"
fi

mount "$root_partition" /mnt
swapon "$swap_partition"
mkdir /mnt/boot
mount "$efi_partition" /mnt/boot

echo "[INFO] Installing Arch base"
pacstrap /mnt base base-devel "$kernel" "$kernel"-headers "$microcode" linux-firmware

virt_check

network_installer () {
    case $network_choice in
        1 ) echo "Installing and enabling IWD."
            pacstrap /mnt iwd >/dev/null
            systemctl enable iwd --root=/mnt &>/dev/null
            ;;
        2 ) echo "Installing and enabling NetworkManager."
            pacstrap /mnt networkmanager >/dev/null
            systemctl enable NetworkManager --root=/mnt &>/dev/null
            ;;
        3 ) echo "Installing and enabling wpa_supplicant and dhcpcd."
            pacstrap /mnt wpa_supplicant dhcpcd >/dev/null
            systemctl enable wpa_supplicant --root=/mnt &>/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
            ;;
        4 ) echo "Installing dhcpcd."
            pacstrap /mnt dhcpcd >/dev/null
            systemctl enable dhcpcd --root=/mnt &>/dev/null
    esac
}

network_installer

echo "[INFO] Generating fstab"
genfstab -U /mnt >> /mnt/etc/fstab

echo "[INFO] Base installed, proceeding with installation"
read -r -p "Please enter desired host name: " hostname
echo "$hostname" > /mnt/etc/hostname

sed -i "/^#$locale/s/^#//" /mnt/etc/locale.gen
echo "LANG=$locale" > /mnt/etc/locale.conf
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

arch-chroot /mnt /bin/bash -e <<EOF

	ln -sf /usr/share/zoneinfo/$(curl -s http://ip-api.com/line?fields=timezone) /etc/localtime &>/dev/null

	hwclock --systohc

	locale-gen &>/dev/null

	mkinitcpio -P &>/dev/null

	bootctl --path=/boot install

EOF

echo -e "#timeout 10
	#console-mode max
	default ${kernel}" > /boot/loader/loader.conf

root_UUID=$"blkid -o value -s UUID ${root_partition}"
echo -e "title Arch Linux ($kernel)
linux /vmlinuz-linux
initrd /intel-ucode.img
initrd /initramfs-linux.img
options root=UUID="$root_UUID" rw qiet loglevel=3" > /boot/loader/entries/arch.conf

echo "[INFO] Generate user & password"
echo "${username} ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/${username}

echo "Change password for user root :"
passwd root
echo "Change password for user ${username} :"
passwd "${username}"

echo "[INFO] Done, you may now wish to reboot (further changes can be done by chrooting into /mnt)."
exit
