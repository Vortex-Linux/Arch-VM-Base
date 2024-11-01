#!/bin/bash 

echo "Shutting down the Arch VM..." 

echo y | ship --vm shutdown arch-vm-base 

echo "Optimizing the image by removing out the zeroed out blocks"

ship --vm optimize arch-vm-base 

echo "Copying the Arch disk image to generate the release package for 'arch-vm-base'..."

DISK_IMAGE=$(sudo virsh domblklist arch-vm-base | grep .qcow2 | awk '{print $2}')

cp "$DISK_IMAGE" output/archlinux.qcow2

echo "Copy complete. The disk image is located at output/archlinux.qcow2."

