#! /bin/sh

 #####################
 #     Variables     #
 #####################
uptime=$(uptime -p | sed -e 's/up //g')
rofi_command="rofi -theme ~/.config/rofi/powermenu.rasi"

 ###################
 #     Options     #
 ###################
shutdown="󰐥 Shutdown"
reboot="󰜉 Reboot"
suspend="󰒲 Suspend"
logout=" Logout"

options="$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | $rofi_command -dmenu)"
case $chosen in
    $shutdown)
        poweroff
        ;;
    $reboot)
        reboot
        ;;
    $suspend)
        systemctl suspend
        ;;
    $logout)
	qtile cmd-obj -o cmd -f shutdown
        ;;
esac
