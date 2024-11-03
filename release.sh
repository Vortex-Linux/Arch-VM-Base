#!/bin/bash 

echo "Shutting down the Arch VM..." 

echo y | ship --vm shutdown arch-vm-base 

echo "Compressing the Arch VM disk image..."

ship --vm compress arch-vm-base 

echo "Starting the xz compression of the Arch disk image to generate the release package for 'arch-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist arch-vm-base | grep .qcow2 | awk '{print $2}')

xz -9 -z "$DISK_IMAGE"

echo "Moving the compressed disk image to the output directory..."

mv "$DISK_IMAGE.xz" output/archlinux.qcow2.xz

echo "The release package for 'arch-vm-base' has been generated successfully!"

