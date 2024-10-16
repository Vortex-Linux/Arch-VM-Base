#!/bin/bash

INITIAL_COMMANDS=$(cat <<'EOF'
root
exec bash
EOF
)

while IFS= read -r command; do
    if [[ -n "$command" ]]; then
        tmux send-keys -t arch-vm-base "$command" C-m
        sleep 1
    fi
done <<< "$INITIAL_COMMANDS"

INSTALLATION_SCRIPT=$(cat << 'EOF'
cat  << 'INSTALL_SCRIPT' > "install.sh"
#!/bin/bash
sgdisk --new=1:2048:+1G --typecode=1:ef00 --change-name=1:"boot" /dev/vda 
sgdisk --new=2:0:0 --typecode=2:8e00 --change-name=2:"LVM" /dev/vda 

partprobe /dev/vda 

pvcreate /dev/vda2 
vgcreate vg0 /dev/vda2 

lvcreate --type thin-pool -L 1999G -n thinpool vg0 
lvcreate --thin vg0/thinpool --virtualsize 10G -n swap  
lvcreate --thin vg0/thinpool --virtualsize 1000G -n root 
lvcreate --thin vg0/thinpool --virtualsize 989G -n home 

mkfs.fat -F32 /dev/vda1
mkfs.ext4 /dev/vg0/root 
mkfs.ext4 /dev/vg0/home 
mkswap /dev/vg0/swap 
swapon /dev/vg0/swap 

mount /dev/vg0/root /mnt  

mkdir /mnt/boot 
mount /dev/vda1 /mnt/boot 

mkdir /mnt/home 
mount /dev/vg0/home /mnt/home 

echo "Partitioning and filesystem setup complete. Sleeping for 60 seconds to allow changes to settle before continuing." 
sleep 60  

pacman -Sy pacman-contrib --noconfirm 

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup 
timeout 60 rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist 

pacstrap -K /mnt base linux linux-firmware base-devel  

genfstab -U -p /mnt >> /mnt/etc/fstab  

arch-chroot /mnt /bin/bash <<CHROOT 

sed -i 's/^#\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen
locale-gen

echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "archlinux" > /etc/hostname  

systemctl enable fstrim.timer

sed -i '/^\[multilib\]$/,/^\s*$/ s|^#*\s*Include\s*=.*|Include = /etc/pacman.d/mirrorlist|; /^\s*Include\s*=/ s|^#*||' /etc/pacman.conf

echo "root:arch" | chpasswd

useradd -m -g users -G wheel,storage,power -s /bin/bash arch
echo "arch:arch" | chpasswd

sed -i '/^# %wheel/s/^# //' /etc/sudoers
echo "Defaults rootpw" >> /etc/sudoers

pacman -S xorg-server xorg-xinit xpra networkmanager blueman linux-headers lvm2 --noconfirm

sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf block lvm2 filesystems keyboard fsck)/' /etc/mkinitcpio.conf
sed -i 's/^MODULES=.*/MODULES=(ext4)/' /etc/mkinitcpio.conf
mkinitcpio -P

bootctl install --esp-path=/boot

sudo touch /boot/loader/entries/arch.conf
sudo tee /boot/loader/entries/arch.conf <<BOOTENTRY
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
BOOTENTRY
echo "options root=PARTUUID=$(blkid -s PARTUUID -o value "/dev/vg0/root") rw" >> /boot/loader/entries/arch.conf
echo "options root=PARTUUID=$(blkid -s UUID -o value /dev/vg0/root) rw" >> /boot/loader/entries/arch.conf


systemctl enable NetworkManager.service

echo -e "X11Forwarding yes\nX11DisplayOffset 10" | tee -a /etc/ssh/sshd_config
systemctl reload sshd 

tee /etc/systemd/system/xorg.service > /dev/null <<SERVICE
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

systemctl enable xorg.service

CHROOT

umount -R /mnt

INSTALL_SCRIPT
EOF
)

tmux send-keys -t arch-vm-base "$INSTALLATION_SCRIPT" C-m 

echo "Waiting 5 seconds for the installation script to be created..."
sleep 5 &&

EXECUTE_INSTALL_SCRIPT="bash install.sh"

tmux send-keys -t arch-vm-base "$EXECUTE_INSTALL_SCRIPT" C-m
