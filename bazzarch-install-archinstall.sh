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
DESKTOP_ENV="kde"
MICROCODE="amd-ucode"
# ----------------

echo "[1/3] Generating valid archinstall config..."
cat <<EOF > config.json
{
  "config_type": "generic",
  "profile": "desktop",
  "disks": {
    "$DISK": {
      "partitions": {
        "EFI system partition": {
          "mountpoint": "/boot/efi",
          "size": "512M",
          "filesystem": "fat32",
          "type": "efi"
        },
        "Linux root (x86-64)": {
          "mountpoint": "/",
          "filesystem": "btrfs"
        }
      },
      "wipe": true,
      "bootloader": true
    }
  },
  "bootloader": "grub-install",
  "filesystem": "btrfs",
  "hostname": "$HOSTNAME",
  "locale": "$LOCALE",
  "keyboard_layout": "$KEYMAP",
  "timezone": "$TIMEZONE",
  "mirror_region": "Worldwide",
  "kernel": "linux",
  "microcode": "$MICROCODE",
  "desktop": "$DESKTOP_ENV",
  "network": {
    "type": "NetworkManager"
  },
  "users": {
    "$USERNAME": {
      "password": "$PASSWORD",
      "superuser": true
    }
  },
  "additional_packages": [
    "steam", "gamemode", "mangohud", "protonup-qt", "flatpak",
    "wget", "curl", "unzip", "htop", "neofetch", "git", "vim"
  ]
}
EOF

echo "[2/3] Running archinstall with config.json..."
archinstall --config config.json --silent

echo "[3/3] Done! You can now reboot."