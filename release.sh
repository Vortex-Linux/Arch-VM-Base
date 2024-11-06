#!/bin/bash 

echo "Shutting down the Arch VM..." 

echo y | ship --vm shutdown arch-vm-base 

echo "Compressing the Arch VM disk image..."

ship --vm compress arch-vm-base 

echo "Copying the Arch VM disk image to generate the release package for 'arch-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist arch-vm-base | grep .qcow2 | awk '{print $2}')

cp "$DISK_IMAGE" output/archlinux.qcow2

echo "Splitting the copied disk image into two parts..."

split -b $(( $(stat -c%s "output/archlinux.qcow2") / 2 )) -d -a 3 "output/archlinux.qcow2" "output/archlinux.qcow2."

echo "The release package for 'arch-vm-base' has been generated and split successfully!"

