#!/bin/bash

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
sleep 60 &&
sudo pacman -Syu --noconfirm &&
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
