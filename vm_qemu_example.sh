#!/bin/sh

cp /usr/share/edk2/x64/OVMF_CODE.4m.fd /tmp/
OVMF_CODE="/tmp/OVMF_CODE.4m.fd"
OVMF_VARS="/usr/share/edk2/x64/OVMF_VARS.4m.fd"

VM_NAME=""
VM_PROCESS_NAME=""

DISK=""
INSTALL_IMG=""
VIRTIO_IMG=""

	qemu-system-x86_64 \
	-drive if=pflash,format=raw,file=$OVMF \
	-drive if=pflash,format=raw,readonly=on,file=$VARS \
	-name $VM_NAME,process=$VM_PROCESS_NAME \
	-machine type=q35 \
	-enable-kvm \
	-cpu host,topoext=on,kvm=off,hypervisor=off,hv_time=on,hv_relaxed=on,hv_vapic=on,hv_vendor_id=12456789ab \
	-smp 8,sockets=1,cores=4,threads=2 \
	-m 16G \
	-rtc clock=host,base=localtime \
	-audiodev pipewire,id=snd0 \
	-device ich9-intel-hda \
	-device hda-micro,audiodev=hda \
	-audiodev pipewire,id=hda \
	-spice port=5900,addr=127.0.0.1,disable-ticketing=on,image-compression=off,seamless-migration=on \
	-display none \
	-vga none \
	-net nic,model=virtio \
	-net user \
	-drive file=$DISK_IMG,index=0,media=disk,format=raw,if=virtio \
	-drive file=$INSTALL_IMG,index=2,media=cdrom \
	-drive file=$VIRTIO_IMG,index=3,media=cdrom \
	-device driver=virtio-keyboard-pci,id=input1,serial=virtio-keyboard \
	-device driver=virtio-mouse-pci,id=input2,serial=virtio-mouse
