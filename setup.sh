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

mkdir /mnt/boot &&
mount /dev/vda1 /mnt/boot &&

mkdir /mnt/home &&
mount /dev/vg0/home /mnt/home &&

pacman -Sy pacman-contrib &&

cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup &&
rankmirrors -n 6 /etc/pacman.d/mirrorlist.backup > /etc/pacman.d/mirrorlist

pacstrap -K /mnt base linux linux-firmware base-devel && 

genfstab -U -p /mnt >> /mnt/etc/fstab 
EOF
)

tmux send-keys -t arch-vm-base "$COMMANDS" C-m
