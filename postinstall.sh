#!/usr/bin/env bash

if [ "$(id -u)" -eq 0 ]; then
        echo "This script must NOT be ran by root" >&2
        exit 1
fi

clear

echo
echo *---
echo *--- Preparing ---*
echo *---
echo

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin

echo
echo *---
echo *--- Installing essentials ---*
echo *---
echo

while true; do
read -r -p "Enter graphics card (e.g: amd,intel,nvidia,none): " graphics_card_selector
	case $graphics_card_selector in
		amd )		echo "Installing amd drivers."
				sudo pacman -S mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
    				break
				;;
		intel ) 	echo "Installing intel drivers."
				sudo pacman -S mesa lib32-mesa vulkan-intel lib32-vulkan-intel
    				break
				;;
		nvidia )	echo "Installing & Configuring nvidia drivers."
				pacstrap /mnt nvidia-dkms nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia egl-wayland
				sed -i '7s/MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
				echo "options nvidia_drm modeset=1 fbdev=1" > /mnt/etc/modprobe.d/nvidia.conf
    				break
				;;
		none )		echo "Choosen no graphics card drivers."
  				break
				;;
		* )		echo "Enter valid option" >&2
				;;
	esac
done

while true; do
read -r -p "Enter firewall (e.g: nftables,iptables): " firewall_selector
	case $firewall_selector in
 		nftables )	echo "Instaling & Configuring nftables."
   				sudo pacman -S nftables iptables-nft
       				echo -e "#!/usr/bin/nft -f\n\nflush ruleset\n\ntable inet filter {\n	chain input {\n		type filter hook input priority 0; policy drop;\n		ct state {established, related} accept\n		iif lo accept\n	}\n	chain forward {\n		type filter hook forward priority 0; policy drop;\n	}\n	chain output {\n		type filter hook output priority 0; policy accept;\n	}\n}" | sudo tee /etc/nftables.conf > /dev/null
				sudo systemctl enable nftables
				break
				;;
		iptables )	echo "Installing & Configuring iptables."
  				sudo pacman -S iptables
      				echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n-A INPUT -s 127.00.1/32 -i lo -j ACCEPT\nCOMMIT" | sudo tee /etc/iptables/iptables.rules > /dev/null
				sudo systemctl enable iptables
				break
				;;
		* )		echo "Enter valid option." >&2
				;;
	esac
done

#
# Checking variables
#

username=$(whoami)

while true; do
read -r -p "Enter Enter networking utility (e.g: iwd,networkmanager,dhcpd): " network_selector
	case $network_selector in
		iwd )			net_gui=iwgtk
     					break
					;;
		networkmanager )	net_gui=nm-connection-editor
     					break
					;;
		dhcpd )			break
					;;
		* )			echo "Enter valid option" >&2
					;;
	esac
done

#
# Checking variables end
#

echo
echo *---
echo *--- Installing fonts ---*
echo *---
echo

yay -S noto-fonts noto-fonts-cjk noto-fonts-emoji
yay -S ttf-jetbrains-mono-nerd
yay -S ttf-ms-fonts

echo
echo *---
echo *--- Installing GUI essentials ---*
echo *---
echo

yay -S pipewire pipewire-pulse pipewire-alsa pipewire-jack
yay -S gstreamer gst-libav gst-plugin-pipewire gst-plugins-ugly gst-plugins-bad gst-plugins-base gst-plugins-good
yay -S gvfs gvfs-mtp
yay -S bluez openrgb
yay -S flatpak transmission-gtk
yay -S qt5-wayland qt6-wayland

echo
echo *---
echo *--- Installing hyprland ---*
echo *---
echo

yay -S hyprland xdg-desktop-portal-hyprland
yay -S hyprpaper hyprpolkitagent-git

echo
echo *---
echo *--- Installing GUI apps ---*
echo *---
echo

yay -S blueman pavucontrol ${network_gui}
yay -S qt5ct qt6ct nwg-look
yay -S grim slurp
yay -S thunar thunar-volman tumbler
yay -S mousepad
yay -S ristretto mpv
yay -S foot waybar wofi wlogout mako
yay -S libreoffice-fresh-ru
yay -S firefox

echo
echo *---
echo *--- Configuring installed apps ---*
echo *---
echo

sudo systemctl enable bluetooth
sudo modprobe i2c-dev i2c-piix4

echo
echo *---
echo *--- Copying config files ---*
echo *---
echo

read -r -p "Enter external partition with config files: " external_partition

sudo mount ${external_partition} /mnt

cp -r /mnt/Arch-Linux/dotfiles/{.config/,.local/,.scripts/} ~/

echo
echo *---
echo *--- Cleaning up ---*
echo *---
echo

rm -rf /home/${username}/.cache
sudo pacman -Rns $(pacman -Qdtq)
sudo pacman -Scc

echo
echo *---
echo *--- Finished, you may reboot now ---*
echo *--- Run hyprland via 'sh .scripts/hyprland.sh' ---*
echo *---
echo

exit
