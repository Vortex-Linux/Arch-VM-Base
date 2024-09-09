sudo pacman -Syu xorg-server xorg-xauth
sudo touch /boot/loader/entries/arch.conf

sudo tee /etc/systemd/system/xorg.service <<EOF
[Unit]
Description=Xorg Server
After=network.target

[Service]
User=your_username
ExecStart=/usr/bin/startx
Restart=always
Environment=DISPLAY=:0

[Install]
WantedBy=default.target
EOF

sudo systemctl enable xorg.service
sudo systemctl start xorg.service 

sudo sh -c 'echo "X11Forwarding yes" >> /etc/ssh/sshd_config'
sudo sh -c 'echo "X11DisplayOffset 10" >> /etc/ssh/sshd_config'

