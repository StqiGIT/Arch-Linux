#!/usr/bin/env bash

read -r -p "Enter graphics card (e.g: amd,intel,nvidia,none): " graphics_card
case $graphics_card in
	amd )		echo "Installing amd drivers."
			pacstrap /mnt mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon
			;;
	intel ) 	echo "Installing intel drivers."
			pacstrap /mnt mesa lib32-mesa vulkan-intel lib32-vulkan-intel
			;;
	nvidia )	echo "Installing & Configuring nvidia drivers."
			pacstrap /mnt nvidia-dkms nvidia-utils lib32-nvidia-utils opencl-nvidia lib32-opencl-nvidia egl-wayland
			sed -i '7s/MODULES=(.*)/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/g' /mnt/etc/mkinitcpio.conf
			echo "options nvidia_drm modeset=1 fbdev=1" > /mnt/etc/modprobe.d/nvidia.conf
			;;
	none )		echo "Choosen no graphics card drivers"
			;;
	* )		echo "Error: enter valid graphics card name"
			;;
esac
