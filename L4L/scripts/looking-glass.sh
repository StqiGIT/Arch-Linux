#! /bin/bash

tmp=$(virsh --connect qemu:///system list | grep " GPU-Passthrough " | awk '{ print $3}')
if ([ "x$tmp" == "x" ] || [ "x$tmp" != "xrunning" ])
then
    virsh --connect qemu:///system start GPU-Passthrough
    echo "Virtual Machine GPU-Passthrough is starting..."
    sleep 5
fi
looking-glass-client input:escapeKey=102 audio:micDefault=allow &
exit
