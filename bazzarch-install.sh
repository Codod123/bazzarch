#!/bin/bash
set -e

DISTRO_NAME="bazzarch"
BASE_DIR="."
CONFIG_DIR="$BASE_DIR/configs/$DISTRO_NAME"
CALAMARES_ETC_DIR="$CONFIG_DIR/airootfs/etc/calamares"
CALAMARES_SRC_DIR="$BASE_DIR/calamares"
THEME_DIR="$CONFIG_DIR/boot/grub/themes/bazzarch"

echo "[*] Creating folders..."
mkdir -p "$CONFIG_DIR/airootfs/etc/skel"
mkdir -p "$CONFIG_DIR/airootfs/etc/xdg/autostart"
mkdir -p "$CALAMARES_ETC_DIR/branding/$DISTRO_NAME"
mkdir -p "$CALAMARES_ETC_DIR/modules"
mkdir -p "$CALAMARES_SRC_DIR"
mkdir -p "$CONFIG_DIR/airootfs/etc/systemd/system"
mkdir -p "$THEME_DIR"

# ---- build.sh ----
cat > "$BASE_DIR/build.sh" <<EOF
#!/bin/bash
set -e

ISO_NAME="$DISTRO_NAME"
CONFIG_PATH="./configs/\$ISO_NAME"

echo "[*] Installing archiso..."
sudo pacman -Sy --noconfirm --needed archiso

echo "[*] Building ISO..."
cd "\$CONFIG_PATH"
sudo mkarchiso -v .

echo "[✓] Done. ISO is in: \$CONFIG_PATH/out/"
EOF
chmod +x "$BASE_DIR/build.sh"

# ---- packages.x86_64 ----
cat > "$CONFIG_DIR/packages.x86_64" <<EOF
base
linux-zen
linux-zen-headers
linux-firmware
nano
neofetch
grub
sudo
networkmanager
gnome
gdm
xorg-server
pipewire
pipewire-alsa
pipewire-pulse
pipewire-jack
calamares
qt5-base
qt5-declarative
qt5-svg
qt5-tools
qt5-x11extras
yaml-cpp
steam
wine
protontricks
gamemode
vulkan-icd-loader
vulkan-tools
lib32-vulkan-icd-loader
lib32-vulkan-tools
nvidia
nvidia-utils
lib32-nvidia-utils
mesa
lib32-mesa
xf86-video-amdgpu
xf86-video-intel
xf86-video-nouveau
mesa-vdpau
code
git
python
python-pip
nodejs
npm
gcc
g++
make
cmake
gdb
rustup
jdk-openjdk
docker
docker-compose
EOF

# ---- profiledef.sh ----
cat > "$CONFIG_DIR/profiledef.sh" <<EOF
#!/usr/bin/env bash

iso_name="$DISTRO_NAME"
iso_label="BAZZARCH_\$(date +%Y%m)"
iso_publisher="Codrin"
iso_application="Bazzarch Custom Arch Distro"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'uefi-x64.systemd-boot.esp')
arch="x86_64"
pacman_conf="pacman.conf"
airootfs_image_type="squashfs"
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '15')
file_permissions=(
  ["/etc/shadow"]="0:0:400"
)
EOF

# ---- pacman.conf ----
cat > "$CONFIG_DIR/pacman.conf" <<EOF
[options]
HoldPkg     = pacman glibc
Architecture = auto

Color
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
EOF

# ---- Autostart Calamares ----
cat > "$CONFIG_DIR/airootfs/etc/xdg/autostart/calamares.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Install Bazzarch
Exec=sudo calamares
Icon=calamares
Comment=Start the Bazzarch Installer
X-GNOME-Autostart-enabled=true
EOF

# ---- GPU driver detection script ----
cat > "$CONFIG_DIR/airootfs/usr/local/bin/gpu-driver-detect.sh" <<'EOF'
#!/bin/bash
if lspci | grep -i nvidia >/dev/null; then
    echo "NVIDIA GPU detected."
    modprobe nvidia
elif lspci | grep -i amd >/dev/null; then
    echo "AMD GPU detected."
elif lspci | grep -i intel >/dev/null; then
    echo "Intel GPU detected."
else
    echo "No dedicated GPU detected or unknown GPU."
fi
EOF
chmod +x "$CONFIG_DIR/airootfs/usr/local/bin/gpu-driver-detect.sh"

# ---- systemd service for GPU detection ----
cat > "$CONFIG_DIR/airootfs/etc/systemd/system/gpu-detect.service" <<EOF
[Unit]
Description=GPU Driver Detection Service
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/gpu-driver-detect.sh

[Install]
WantedBy=multi-user.target
EOF

mkdir -p "$CONFIG_DIR/airootfs/etc/systemd/system/multi-user.target.wants"
ln -sf ../gpu-detect.service "$CONFIG_DIR/airootfs/etc/systemd/system/multi-user.target.wants/gpu-detect.service"

# ---- Calamares branding ----
cat > "$CALAMARES_ETC_DIR/branding/$DISTRO_NAME/branding.desc" <<EOF
---
name: $DISTRO_NAME
version: 1.0
productName: Bazzarch Linux
shortProductName: Bazzarch
versionedName: Bazzarch 1.0
welcomeStyle: classic
EOF

# ---- Calamares settings.conf ----
cat > "$CALAMARES_ETC_DIR/settings.conf" <<EOF
---
sequence:
  - show:
      - welcome
      - locale
      - keyboard
      - partition
      - users
      - summary
      - install
      - finished

branding: $DISTRO_NAME
modules-search: /etc/calamares/modules
EOF

# ---- Unattended install config ----
cat > "$CALAMARES_ETC_DIR/unattended.conf" <<EOF
---
locale:
  zone: Europe/Helsinki
  keyboardLayout: fi

users:
  - name: codrin
    fullname: Codrin User
    password: password
    sudo: true
    autologin: true

partitions:
  erase: true
  useLUKS: false
EOF

# ---- README.md ----
cat > "$BASE_DIR/README.md" <<EOF
# Bazzarch

Custom Arch-based Linux with GNOME, linux-zen kernel, gaming support, Calamares installer, and unattended install.

## Quick start

\`\`\`bash
git clone https://github.com/YOUR_USERNAME/bazzarch.git
cd bazzarch
chmod +x setup.sh
./setup.sh
./build.sh
\`\`\`

Features:
- GNOME desktop environment
- linux-zen kernel for performance
- Steam, Wine, Proton, Vulkan, Gamemode
- Auto GPU driver detection
- Calamares installer autostart on live boot
- Finnish locale and keyboard
- Full GRUB theme included
EOF

# ---- GRUB theme files ----

cat > "$THEME_DIR/theme.txt" <<'EOF'
# Bazzarch GRUB Theme

set color_normal=white/black
set color_highlight=black/light-gray

if loadfont /boot/grub/fonts/DejaVuSansMono.pf2; then
    set gfxmode=auto
    insmod gfxterm
    terminal_output gfxterm
fi

if background_image /boot/grub/themes/bazzarch/background.png; then
    true
else
    set menu_color_normal=white/black
    set menu_color_highlight=black/light-gray
fi

menu_color_normal=white/black
menu_color_highlight=black/light-gray

terminal_input gfxterm

set menu_width=40
set menu_height=15
set menu_x=10
set menu_y=10
EOF

if command -v convert &>/dev/null; then
    convert -size 1920x1080 gradient: -rotate 90 \
        -fill "#1a1a2e" -colorize 20% \
        "$THEME_DIR/background.png"
    echo "[✓] GRUB background.png created"
else
    echo "[!] ImageMagick not found. Please add your own GRUB background.png at:"
    echo "    $THEME_DIR/background.png"
fi

echo "[✓] Setup complete. Run ./build.sh to build your ISO."