SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/arch-vm-base.xml"

ship --vm create arch-vm-base --source https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2

sed -i '/<\/devices>/i \
  <console type="pty">\
    <target type="virtio"/>\
  </console>' "$XML_FILE"

ship --vm shutdown arch-vm-base 
virsh -c qemu:///system undefine arch-vm-base
virsh -c qemu:///system define "$XML_FILE"

ship --vm start arch-vm-base
#ship --vm exec arch-vm-base --command "$SCRIPT_DIR/customize.sh"
ship --vm view arch-vm-base
