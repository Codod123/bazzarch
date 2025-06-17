#!/bin/bash
set -e

# ---- CONFIG ----
DISK="/dev/sdX"           # Replace with your actual disk (e.g. /dev/sda)
HOSTNAME="bazzarch"
USERNAME="gamer"
PASSWORD="gamer"
LOCALE="en_US.UTF-8"
KEYMAP="fi"
TIMEZONE="Europe/Helsinki"
DESKTOP_ENV="gnome"
MICROCODE="amd-ucode"     # or intel-ucode
# ----------------

echo "[1/9] Partitioning and formatting $DISK..."
sgdisk -Z $DISK
sgdisk -n 1:0:+512M -t 1:ef00 -c 1:EFI $DISK
sgdisk -n 2:0:0 -t 2:8300 -c 2:ROOT $DISK

mkfs.fat -F32 ${DISK}1
mkfs.btrfs -f ${DISK}2

mount ${DISK}2 /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
umount /mnt

mount -o compress=zstd,subvol=@ ${DISK}2 /mnt
mkdir -p /mnt/{boot/efi,home}
mount -o compress=zstd,subvol=@home ${DISK}2 /mnt/home
mount ${DISK}1 /mnt/boot/efi

echo "[2/9] Installing base system..."
pacstrap -K /mnt base linux linux-firmware ${MICROCODE} sudo networkmanager grub efibootmgr btrfs-progs git vim

echo "[3/9] Configuring system..."
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
hwclock --systohc

echo "${LOCALE} UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" > /etc/locale.conf
echo "KEYMAP=${KEYMAP}" > /etc/vconsole.conf

echo "${HOSTNAME}" > /etc/hostname
echo "127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}" >> /etc/hosts

echo "[4/9] Enabling multilib..."
sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
pacman -Sy

echo "[5/9] Installing desktop and packages..."
pacman -S --noconfirm xorg ${DESKTOP_ENV} gdm steam gamemode mangohud \
  vulkan-icd-loader lib32-vulkan-icd-loader \
  lib32-mesa mesa protonup-qt flatpak \
  wget curl unzip htop neofetch

echo "[6/9] Enabling services..."
systemctl enable NetworkManager gdm

echo "[7/9] Adding user ${USERNAME}..."
useradd -m -G wheel -s /bin/bash ${USERNAME}
echo "${USERNAME}:${PASSWORD}" | chpasswd
echo "root:${PASSWORD}" | chpasswd
echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/99_wheel

echo "[8/9] Detecting GPU and installing drivers..."
GPU=\$(lspci | grep -E "VGA|3D")
if echo "\$GPU" | grep -qi nvidia; then
  pacman -S --noconfirm nvidia nvidia-utils lib32-nvidia-utils
elif echo "\$GPU" | grep -qi amd; then
  pacman -S --noconfirm vulkan-radeon lib32-vulkan-radeon
elif echo "\$GPU" | grep -qi intel; then
  pacman -S --noconfirm vulkan-intel lib32-vulkan-intel
fi

echo "[9/9] Finished. Installing GRUB..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "Installation complete. Rebooting..."
umount -R /mnt
reboot
