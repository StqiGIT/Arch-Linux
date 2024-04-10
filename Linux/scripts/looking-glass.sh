#! /bin/bash

tmp=$(virsh --connect qemu:///system list | grep " 'VM Name' " | awk '{ print $3}')
if ([ "x$tmp" == "x" ] || [ "x$tmp" != "xrunning" ])
then
    virsh --connect qemu:///system start 'VM Name'
    echo "Virtual Machine win11 is starting..."
    sleep 3
fi
looking-glass-client -F -m 102 &
exit
