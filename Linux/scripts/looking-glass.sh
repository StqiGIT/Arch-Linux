#! /bin/bash

tmp=$(virsh --connect qemu:///system list | grep " GPU-Passthrough ")
if ([ "x$tmp" == "x" ] || [ "x$tmp" != "xrunning" ])
then
    virsh --connect qemu:///system start GPU-Passthrough 
    sleep 3
fi
looking-glass-client &
exit
