#!/bin/sh
set -e

printf "sudo or doas > "
read -r tool

deps="git make gcc pkgconf libxft xorg-xinit libxinerama xlibre-xserver ttf-hack ttf-terminus-nerd maim xclip xdg-utils"
$tool pacman -S --needed --noconfirm $deps

git clone https://github.com/larpingston/suckless

cd suckless
cd dwm && $tool make clean install && cd ..
cd dmenu && $tool make clean install && cd ..
cd dwmblocks && $tool make clean install && cd ..
cd st && $tool make clean install && cd ..


