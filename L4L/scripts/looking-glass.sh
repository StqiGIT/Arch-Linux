#! /bin/bash

tmp=$(virsh --connect qemu:///system list | grep " GPU-Passthrough ")
if ([ "x$tmp" == "x" ] || [ "x$tmp" != "xrunning" ])
then
    virsh --connect qemu:///system start GPU-Passthrough 
    sleep 5 
fi
looking-glass-client win:Fullscreen=yes input:escapeKey=102 audio:micDefault=allow &
exit
