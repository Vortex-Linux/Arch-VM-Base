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

COMMANDS=$(cat <<EOF 
sudo pacman -Syu --noconfirm &&
sleep 30 &&
sudo pacman -S xorg-server xorg-xinit --noconfirm &&

echo -e "X11Forwarding yes\nX11DisplayOffset 10" | sudo tee -a /etc/ssh/sshd_config && 
sudo systemctl reload sshd && 

sudo tee /etc/systemd/system/xorg.service > /dev/null <<SERVICE
[Unit]
Description=X.Org Server
After=network.target

[Service]
ExecStart=/usr/bin/Xorg :0 -config /etc/X11/xorg.conf
Restart=always
User=arch
Environment=DISPLAY=:0

[Install]
WantedBy=multi-user.target
SERVICE

sudo systemctl daemon-reload && 
sudo systemctl enable --now xorg.service
EOF
)

tmux send-keys -t arch-vm-base "$COMMANDS" C-m

./view_vm.sh
