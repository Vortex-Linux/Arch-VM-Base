# Arch-VM-Base

## Overview

This repo contains the build files for the base of the Arch VM used by ship and also the built image releases

## Main Components

### `build.sh`
- Deletes any existing "arch-vm-base" VM
- Creates a new VM using the latest Arch Linux ISO
- Modifies the VM's XML configuration to add a console
- Starts the VM

### `install.sh`
- Runs the installation and configuration tasks inside the Arch Linux VM
- Sets up essential system components and configurations

### `setup.sh`
- Partitions the disk and sets up LVM
- Installs the base Arch Linux system
- Configures system settings (locale, hostname, users, etc.)
- Installs essential packages (e.g., Xorg, NetworkManager)

### `view_vm.sh`
- Connects to the VM console for interaction

### `release.sh`
- Shuts down the VM
- Compresses the VM disk image
- Splits the disk image into parts for easier distribution

---

These scripts streamline the creation and customization of Arch Linux VMs, providing a reliable and reproducible setup as a base for ship to use.
