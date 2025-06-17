#!/bin/bash
set -e

# ---- CONFIG ----
DISK="/dev/sdb"
HOSTNAME="bazzarch"
USERNAME="codo"
PASSWORD="1"
LOCALE="en_US.UTF-8"
KEYMAP="fi"
TIMEZONE="Europe/Helsinki"
DESKTOP_ENV="kde"              # KDE Plasma
MICROCODE="amd-ucode"          # or intel-ucode
# ----------------

echo "[1/3] Generating archinstall config..."
cat <<EOF > config.json
{
  "disk_config": {
    "$DISK": {
      "wipe": true,
      "partitions": [
        {
          "mountpoint": "/boot/efi",
          "size": "512M",
          "filesystem": "fat32",
          "type": "efi"
        },
        {
          "mountpoint": "/",
          "filesystem": "btrfs"
        }
      ],
      "bootloader": {
        "install": true
      }
    }
  },
  "filesystem": "btrfs",
  "bootloader": "grub-install",
  "hostname": "$HOSTNAME",
  "locale": "$LOCALE",
  "keyboard": "$KEYMAP",
  "timezone": "$TIMEZONE",
  "mirror_region": "Worldwide",
  "kernel": "linux",
  "microcode": "$MICROCODE",
  "desktop_environment": "$DESKTOP_ENV",
  "additional_packages": [
    "steam", "gamemode", "mangohud", "protonup-qt", "flatpak",
    "wget", "curl", "unzip", "htop", "neofetch", "git", "vim"
  ],
  "network_configuration": {
    "method": "NetworkManager"
  },
  "users": {
    "$USERNAME": {
      "password": "$PASSWORD",
      "superuser": true
    }
  }
}
EOF

echo "[2/3] Running archinstall with config.json..."
archinstall --config config.json --silent

echo "[3/3] Done! You can now reboot."