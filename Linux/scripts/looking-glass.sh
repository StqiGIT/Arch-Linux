#! /bin/bash

tmp=$(virsh --connect qemu:///system list | grep " W11-Passthrough ")
if ([ "x$tmp" == "x" ] || [ "x$tmp" != "xrunning" ])
then
    virsh --connect qemu:///system start W11-Passthrough
    sleep 5
fi
looking-glass-client &
exit
