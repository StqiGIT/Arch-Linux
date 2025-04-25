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

username=$(whoami)

git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si
cd ..
rm -rf yay-bin

echo
echo *---
echo *--- Configuring graphics card drivers ---*
echo *---
echo

while true; do
	echo
	echo "Graphics card options:"
	echo
	echo "amd"
	echo "----------"
	echo "intel"
	echo "----------"
	echo "nvidia"
	echo "----------"
	echo "none"
	echo
	read -r -p "Enter graphics card: " graphics_card_selector
		case $graphics_card_selector in
			amd )		echo
					echo "Installing amd drivers."
					echo
					sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
    					break
					;;
			intel ) 	echo
					echo "Installing intel drivers."
					echo
					sudo pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel
    					break
					;;
			nvidia )	echo
					echo "Installing & Configuring nvidia drivers."
					echo
					sudo pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia egl-wayland
					sed -i '7s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
					echo "options nvidia_drm modeset=1 fbdev=1" > /mnt/etc/modprobe.d/nvidia.conf
    					break
					;;
			none )		echo
					echo "Choosen no graphics card drivers."
  					echo
					break
					;;
			* )		echo "Enter valid option" >&2
					;;
		esac
done

echo
echo *---
echo *--- Installing and configuring firewall ---*
echo *---
echo

while true; do
	echo
	echo "Firewall options:"
	echo
	echo "nftables"
	echo "----------"
	echo "iptables"
	echo
	read -r -p "Enter firewall: " firewall_selector
		case $firewall_selector in
 			nftables )	echo
					echo "Instaling & Configuring nftables."
   					echo
					yes | sudo pacman -Rnsdd --noconfirm iptables
					yes | sudo pacman -S --noconfirm nftables iptables-nft
       					echo -e "#!/usr/bin/nft -f\n\nflush ruleset\n\ntable inet filter {\n	chain input {\n		type filter hook input priority 0; policy drop;\n		ct state {established, related} accept\n		iif lo accept\n	}\n	chain forward {\n		type filter hook forward priority 0; policy drop;\n	}\n	chain output {\n		type filter hook output priority 0; policy accept;\n	}\n}" | sudo tee /etc/nftables.conf > /dev/null
					sudo systemctl enable nftables
					break
					;;
			iptables )	echo
					echo "Installing & Configuring iptables."
  					echo
					yes | sudo pacman -S --noconfirm iptables
      					echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n-A INPUT -s 127.00.1/32 -i lo -j ACCEPT\nCOMMIT" | sudo tee /etc/iptables/iptables.rules > /dev/null
					sudo systemctl enable iptables
					break
					;;
			* )		echo
					echo "Enter valid option." >&2
					echo
					;;
		esac
done

echo
echo *---
echo *--- Installing desktop ---*
echo *---
echo

while true; do
	echo
	echo "Desktop options:"
	echo
	echo "kde"
	echo "----------"
	echo "gnome"
	echo "----------"
	echo "none"
	echo
	read -r -p "Enter desktop: " desktop_selector
		case $desktop_selector in
			kde )		echo
					echo "Installing KDE Plasma"
					echo
					yay -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-ms-fonts
					yay -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack
					yay -S --noconfirm gstreamer gst-libav gst-plugin-pipewire gst-plugins-ugly gst-plugins-bad gst-plugins-base gst-plugins-good
    					yay -S --noconfirm qt5-wayland qt5-graphicaleffects qt5-multimedia qt5-quickcontrols qt5-quickcontrols2 qt6-wayland qt6-multimedia
					yay -S --noconfirm flatpak
    					yay -S --noconfirm plasma-meta system-config-printer
					yay -S --noconfirm dolphin dolphin-plugins gwenview kcalc kate konsole ktorrent
					sudo systemctl enable sddm
					break
					;;
			gnome )		echo
					echo "Installing GNOME"
  					echo
					yay -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-ms-fonts
					yay -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack
					yay -S --noconfirm gstreamer gst-libav gst-plugin-pipewire gst-plugins-ugly gst-plugins-bad gst-plugins-base gst-plugins-good
					yay -S --noconfirm flatpak
    					yay -S --noconfirm gnome
    					yay -S --noconfirm transmission-gtk
					sudo systemctl enable gdm
					break
					;;
			none )		echo
					echo "Choosen no desktop"
					echo
					break
					;;
			* )		echo
					echo "Enter vaid option" >&2
					echo
					;;
		esac
done

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
echo *--- Finished, it is advised reboot now ---*
echo *---
echo

exit
