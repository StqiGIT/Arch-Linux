#! /bin/bash

vmname="GPU-Passthrough"

if ps -ef | grep qemu-system-x86_64 | grep -q -e 'multifunction=on' -e '"multifunction":true'; then
	echo "A passthrough VM is already running." &
	exit

else
	cp /usr/share/OVMF/x64/OVMF_VARS.fd /tmp/my_vars.fd
	
	qemu-system-x86_64 \
	-runas michael \
	-name $vmname,process=$vmname \
	-machine type=q35 \
	-enable-kvm \
	-cpu host,topoext=on,kvm=off,hv_time=on,hv_relaxed=on,hv_vapic=on,hv_vendor_id=null \
	-smp 8,sockets=1,cores=4,threads=2 \
	-uuid 15439e8e-33c3-4ffd-bc3a-74ec6caadd19 \
	-no-user-config \
	-nodefaults \
	-global kvm-pit.lost_tick_policy=delay \
	-m 8G \
	-rtc clock=host,base=localtime \
	-spice port=5900,addr=127.0.0.1,disable-ticketing=on,image-compression=off,seamless-migration=on \
	-vga none \
	-nographic \
	-device vfio-pci,host=01:00.0,multifunction=on \
	-device vfio-pci,host=01:00.1 \
	-device driver=virtio-keyboard-pci,id=input1,serial=virtio-keyboard \
	-device driver=virtio-mouse-pci,id=input2,serial=virtio-mouse \
	-audiodev id=audio1,driver=spice \
	-device driver=ich9-intel-hda,id=sound0,bus=pcie.0,addr=0x1b \
	-device driver=hda-micro,id=sound0-codec0,bus=sound0.0,cad=0,audiodev=audio1 \
	-global ICH9-LPC.noreboot=off \
	-drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/x64/OVMF_CODE.fd \
	-drive if=pflash,format=raw,file=/tmp/my_vars.fd \
	-boot order=c \
	-drive id=disk0,if=virtio,cache=none,format=qcow2,file=/Documents/GPU-Passthrough.qcow2 \
	-device ivshmem-plain,memdev=ivshmem,bus=pcie.0 \
	-object memory-backend-file,id=ivshmem,share=on,mem-path=/dev/shm/looking-glass,size=128M
	exit
fi
	exit
