#!/bin/bash
set -e

echo "==> Updating system..."
sudo pacman -Syu --noconfirm

echo "==> Installing base packages..."
sudo pacman -S --noconfirm \
    firefox steam vlc gimp \
    wget curl git base-devel \
    htop neofetch unzip \
    python python-pip \
    gamemode mangohud lutris \
    xdg-user-dirs flatpak

echo "==> Setting up user folders..."
xdg-user-dirs-update

echo "==> Installing yay (AUR helper)..."
if ! command -v yay &> /dev/null; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ..
    rm -rf yay
else
    echo "yay is already installed"
fi

echo "==> Installing AUR packages..."
yay -S --noconfirm \
    visual-studio-code-bin \
    spotify \
    heroic-games-launcher-bin

echo "==> Installing useful pip packages..."
pip install --upgrade pip
pip install \
    requests beautifulsoup4 flask \
    numpy pandas matplotlib opencv-python \
    yt-dlp

echo "==> Setting up Flatpak (Flathub repo)..."
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "==> Done!"
neofetch