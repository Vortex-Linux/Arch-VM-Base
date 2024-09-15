#!/bin/bash
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
XML_FILE="/tmp/arch-vm-base.xml"

ship --vm delete arch-vm-base 

echo n | ship --vm create arch-vm-base --source https://geo.mirror.pkgbuild.com/images/latest/Arch-Linux-x86_64-basic.qcow2

sed -i '/<\/devices>/i \
  <console type="pty">\
    <target type="virtio"/>\
  </console>' "$XML_FILE"

virsh -c qemu:///system undefine arch-vm-base
virsh -c qemu:///system define "$XML_FILE"

ship --vm start arch-vm-base 

COMMANDS=$(cat <<'EOF'
arch
arch
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t arch-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$COMMANDS"

COMMANDS=$(cat <<'EOF'
echo "hi"
echo "its working"
EOF
)

COMBINED_COMMANDS=$(echo "$COMMANDS" | awk '{print $0 " &&"}' | sed '$s/ &&$//') 

tmux send-keys -t arch-vm-base "$COMBINED_COMMANDS" C-m

./view_vm.sh
