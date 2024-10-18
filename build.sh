#!/bin/bash

SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/arch-vm-base.xml"

echo y | ship --vm delete arch-vm-base 

echo n | ship --vm create arch-vm-base --source https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso

sed -i '/<\/devices>/i \
  <console type="pty">\
    <target type="virtio"/>\
  </console>' "$XML_FILE"

virsh -c qemu:///system undefine arch-vm-base
virsh -c qemu:///system define "$XML_FILE"

echo "Building of VM Complete.Starting might take a while as it might take a bit of type for the vm to boot up and be ready for usage."
ship --vm start arch-vm-base 

./setup.sh
./view_vm.sh
./release.sh
