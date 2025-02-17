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
echo *--- Configuring graphics card drivers ---*
echo *---
echo

while true; do
read -r -p "Enter graphics card (e.g: amd,intel,nvidia,none): " graphics_card_selector
	case $graphics_card_selector in
		amd )		echo "Installing amd drivers."
				sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
    				break
				;;
		intel ) 	echo "Installing intel drivers."
				sudo pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel
    				break
				;;
		nvidia )	echo "Installing & Configuring nvidia drivers."
				sudo pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia egl-wayland
				sed -i '7s/MODULES=()/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
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

echo
echo *---
echo *--- Installing and configuring firewall ---*
echo *---
echo

while true; do
read -r -p "Enter firewall (e.g: nftables,iptables): " firewall_selector
	case $firewall_selector in
 		nftables )	echo "Instaling & Configuring nftables."
   				yes | sudo pacman -S --noconfirm nftables iptables-nft
       				echo -e "#!/usr/bin/nft -f\n\nflush ruleset\n\ntable inet filter {\n	chain input {\n		type filter hook input priority 0; policy drop;\n		ct state {established, related} accept\n		iif lo accept\n	}\n	chain forward {\n		type filter hook forward priority 0; policy drop;\n	}\n	chain output {\n		type filter hook output priority 0; policy accept;\n	}\n}" | sudo tee /etc/nftables.conf > /dev/null
				sudo systemctl enable nftables
				break
				;;
		iptables )	echo "Installing & Configuring iptables."
  				yes | sudo pacman -S --noconfirm iptables
      				echo -e "*filter\n:INPUT DROP [0:0]\n:FORWARD DROP [0:0]\n:OUTPUT ACCEPT [0:0]\n-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT\n-A INPUT -s 127.00.1/32 -i lo -j ACCEPT\nCOMMIT" | sudo tee /etc/iptables/iptables.rules > /dev/null
				sudo systemctl enable iptables
				break
				;;
		* )		echo "Enter valid option." >&2
				;;
	esac
done

echo
echo *---
echo *--- Installing desktop ---*
echo *---
echo

while true; do
read -r -p "Enter desktop (e.g: kde,gnome,hyprland): " desktop_selector
	case $desktop_selector in
		kde )		echo "Installing KDE Plasma"
				yay -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-ms-fonts
				yay -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack
				yay -S --noconfirm gstreamer gst-libav gst-plugin-pipewire gst-plugins-ugly gst-plugins-bad gst-plugins-base gst-plugins-good
    				yay -S --noconfirm qt5-wayland qt5-graphicaleffects qt5-multimedia qt5-quickcontrols qt5-quickcontrols2 qt6-wayland qt6-multimedia
				yay -S --noconfirm flatpak
    				yay -S --noconfirm plasma-meta
				yay -S --noconfirm dolphin dolphin-plugins gwenview kcalc kate konsole ktorrent
				sudo systemctl enable sddm
				break
				;;
		gnome )		echo "Installing GNOME"
  				yay -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-ms-fonts
				yay -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack
				yay -S --noconfirm gstreamer gst-libav gst-plugin-pipewire gst-plugins-ugly gst-plugins-bad gst-plugins-base gst-plugins-good
				yay -S --noconfirm flatpak
    				yay -S --noconfirm gnome
    				yay -S --noconfirm transmission-gtk
				sudo systemctl enable gdm
				break
				;;
		hyprland )	echo "Installing Hyprland"
  				yay -S --noconfirm noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd ttf-ms-fonts
				yay -S --noconfirm pipewire pipewire-pulse pipewire-alsa pipewire-jack
				yay -S --noconfirm gstreamer gst-libav gst-plugin-pipewire gst-plugins-ugly gst-plugins-bad gst-plugins-base gst-plugins-good
        			yay -S --noconfirm qt5-wayland qt6-wayland
				yay -S --noconfirm flatpak
				yay -S --noconfirm hyprland hyprpaper hyprpolkitagent xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
        			yay -S --noconfirm grim slurp
    				yay -S --noconfirm blueman nm-connection-editor pavucontrol
				yay -S --noconfirm gvfs gvfs-mtp thunar thunar-volman tumbler mousepad ristretto
    				yay -S --noconfirm transmission-gtk
				break
				;;
	esac
done

yay -S --noconfirm openrgb libreoffice-fresh-ru gimp mpv firefox vesktop-bin steam

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
