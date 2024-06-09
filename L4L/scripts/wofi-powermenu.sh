#!/usr/bin/env bash

op=$( echo -e " Poweroff\n Reboot\n Hibernate\n Logout" | wofi --dmenu --lines 5 --width 300 | awk '{print tolower($2)}' )

case $op in 
        poweroff)
		systemctl poweroff
                ;&
        reboot)
		systemctl reboot
                ;&
        hibernate)
                systemctl hibernate
                ;;
        logout)
                hyprctl dispatch exit
                ;;
esac
