COMMANDS=$(cat <<EOF
sudo pacman -Syu --noconfirm && 
sudo pacman -S --noconfirm xorg-server &&

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

