#!/bin/bash

COMMANDS=$(cat <<'EOF'
root
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t arch-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$COMMANDS"

COMMANDS=$(cat <<EOF
sgdisk --new=1:2048:+1G --typecode=1:ef00 --change-name=1:"boot" /dev/vda &&
sgdisk --new=2:0:0 --typecode=2:8e00 --change-name=2:"LVM" /dev/vda && 

pvcreate /dev/vda2 &&
vgcreate vg0 /dev/vda2 &&

lvcreate --type thin-pool -L 1999G -n thinpool vg0 &&
lvcreate --thin vg0/thinpool --virtualsize 10G -n swap && 
lvcreate --thin vg0/thinpool --virtualsize 1000G -n root &&
lvcreate --thin vg0/thinpool --virtualsize 989G -n home &&

mkfs.fat -F32 /dev/vda1 &&
mkfs.ext4 /dev/vg0/root &&
mkfs.ext4 /dev/vg0/home &&
mkswap /dev/vg0/swap &&
swapon /dev/vg0/swap &&

mount /dev/vg0/root /mnt && 

mkdir /mnt/boot &&
mount /dev/vda1 /mnt/boot &&

mkdir /mnt/home &&
mount /dev/vg0/home /mnt/home &&

sleep 10 && 

pacman -Sy pacman-contrib --noconfirm &&

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup &&
timeout 60 rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist &&

pacstrap -K /mnt base linux linux-firmware base-devel && 

genfstab -U -p /mnt >> /mnt/etc/fstab && 

arch-chroot /mnt /bin/bash -c '
sed -i "/^#.*en_US.UTF-8 UTF-8/s/^#//" /etc/locale.gen && 
locale-gen &&

echo "LANG=en_US.UTF-8" > /etc/locale.conf && 

timedatectl set-timezone "$zoneinfo" &&
sudo hwclock --systohc &&

echo "archlinux" > /etc/hostname &&  

sudo systemctl enable fstrim.timer && 

sudo sed -i '/^\[multilib\]$/,/^\s*$/ s/^#*\s*Include\s*=.*/Include = \/etc\/pacman.d\/mirrorlist/; /^\s*Include\s*=/ s/^#*//' /etc/pacman.conf &&

echo "root:$arch" | sudo chpasswd && 

useradd -m -g users -G wheel,storage,power -s /bin/bash arch &&
echo "arch:arch" | sudo chpasswd && 

sudo sed -i '/^# %wheel/s/^# //' /etc/sudoers &&
echo "Defaults rootpw" >> /etc/sudoers &&

bootctl install && 

sudo touch /boot/loader/entries/arch.conf &&
sudo tee /boot/loader/entries/arch.conf << BOOTENTRY
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=/dev/vg0/root rw
BOOTENTRY
&&

sudo pacman -S xorg-server xorg-xinit xpra networkmanager blueman linux-headers --noconfirm &&

sudo systemctl enable NetworkManager.service &&

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
&&
sudo systemctl daemon-reload && 
sudo systemctl enable --now xorg.service
'
umount -R /mnt
EOF
)

tmux send-keys -t arch-vm-base "$COMMANDS" C-m
