# Take screenshot of current active monitor

active_workspace_monitor=$(hyprctl -j activeworkspace | jq -r '(.monitor)')
screenshot_filename="$HOME/Pictures/Screenshots/$(date +"%d-%m-%Y-%H%S")-$active_workspace_monitor.png"

grim -o $active_workspace_monitor $screenshot_filename
