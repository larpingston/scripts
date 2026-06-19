#!/bin/sh
# install-suckless.sh
# Installs suckless programs + dotfiles from larpingston's repos.
# Always replaces existing configs — no questions asked.
set -e

# ─── privilege tool ───────────────────────────────────────────────────────────
printf "sudo or doas > "
read -r PRIV

# ─── packages ─────────────────────────────────────────────────────────────────
DEPS="git make gcc pkgconf \
      libxft libxinerama \
      xlibre-xserver xorg-xinit xorg-xsetroot xorg-xrandr \
      ttf-hack ttf-terminus-nerd \
      maim xclip xdg-utils feh \
      zsh zsh-autosuggestions zsh-syntax-highlighting \
      dunst libnotify \
      conky \
      neovim \
      dbus \
      libxcb xcb-util-renderutil xcb-util-image libconfig \
      meson ninja cmake \
      base-devel"

AUR_DEPS="picom-ftlabs-git"

# ─── dirs ─────────────────────────────────────────────────────────────────────
SUCKLESS_DIR="$HOME/suckless"
DOTS_TMP="/tmp/suckless-dots-install"
CONFIG_DIR="$HOME/.config"

# ══════════════════════════════════════════════════════════════════════════════
# 1. Install pacman deps
# ══════════════════════════════════════════════════════════════════════════════
printf '\n==> Installing pacman dependencies...\n'
$PRIV pacman -S --needed --noconfirm $DEPS

# ══════════════════════════════════════════════════════════════════════════════
# 2. Install AUR packages manually (no helper)
#    Pre-installing all deps above means makepkg won't need to pull anything.
#    We also pass PACMAN so makepkg uses the correct privilege tool if needed.
# ══════════════════════════════════════════════════════════════════════════════
printf '\n==> Installing AUR packages manually...\n'
AUR_BUILD_DIR="/tmp/aur-build-$$"
mkdir -p "$AUR_BUILD_DIR"

for pkg in $AUR_DEPS; do
    printf '  -> Building %s\n' "$pkg"
    git clone "https://aur.archlinux.org/${pkg}.git" "$AUR_BUILD_DIR/$pkg"
    cd "$AUR_BUILD_DIR/$pkg"
    PACMAN="$PRIV pacman" makepkg -si --noconfirm --needed
    cd /
done

rm -rf "$AUR_BUILD_DIR"

# ══════════════════════════════════════════════════════════════════════════════
# 3. Clone & build suckless programs into ~/suckless
# ══════════════════════════════════════════════════════════════════════════════
printf '\n==> Setting up suckless programs in %s...\n' "$SUCKLESS_DIR"

rm -rf "$SUCKLESS_DIR"
git clone https://github.com/larpingston/suckless "$SUCKLESS_DIR"

for prog in dwm dmenu dwmblocks st; do
    printf '  -> Compiling and installing %s...\n' "$prog"
    cd "$SUCKLESS_DIR/$prog"
    $PRIV make clean install
done

# ══════════════════════════════════════════════════════════════════════════════
# 4. Clone dotfiles, deploy everything, then delete the repo
# ══════════════════════════════════════════════════════════════════════════════
printf '\n==> Fetching dotfiles...\n'
rm -rf "$DOTS_TMP"
git clone https://github.com/larpingston/suckless-dots "$DOTS_TMP"

mkdir -p "$CONFIG_DIR"

# ~/.config dirs — always replace
printf '\n==> Deploying ~/.config entries...\n'
for dir in nvim picom dunst conky; do
    printf '  -> %s -> %s/%s\n' "$dir" "$CONFIG_DIR" "$dir"
    rm -rf "${CONFIG_DIR:?}/$dir"
    cp -r "$DOTS_TMP/$dir" "$CONFIG_DIR/$dir"
done

# misc files into ~/.config
printf '  -> bookmarks.txt -> %s\n' "$CONFIG_DIR"
cp "$DOTS_TMP/bookmarks.txt" "$CONFIG_DIR/bookmarks.txt"

printf '  -> emojis.txt -> %s\n' "$CONFIG_DIR"
cp "$DOTS_TMP/emojis.txt" "$CONFIG_DIR/emojis.txt"

# scripts -> ~/scripts — always replace
printf '  -> scripts -> %s/scripts\n' "$HOME"
rm -rf "${HOME:?}/scripts"
cp -r "$DOTS_TMP/scripts" "$HOME/scripts"

# xinitrc-dwm
printf '  -> xinitrc-dwm.txt -> ~/.xinitrc-dwm\n'
cp "$DOTS_TMP/xinitrc-dwm.txt" "$HOME/.xinitrc-dwm"

# .zshrc — always replace
printf '  -> zshrc.txt -> ~/.zshrc\n'
cp "$DOTS_TMP/zshrc.txt" "$HOME/.zshrc"

# ══════════════════════════════════════════════════════════════════════════════
# 5. Set zsh as default shell
# ══════════════════════════════════════════════════════════════════════════════
printf '\n==> Setting zsh as default shell...\n'
ZSH_PATH="$(command -v zsh)"
if ! grep -qx "$ZSH_PATH" /etc/shells; then
    printf '%s\n' "$ZSH_PATH" | $PRIV tee -a /etc/shells > /dev/null
fi
chsh -s "$ZSH_PATH"

# ══════════════════════════════════════════════════════════════════════════════
# 6. Clean up dotfiles clone
# ══════════════════════════════════════════════════════════════════════════════
printf '\n==> Cleaning up...\n'
rm -rf "$DOTS_TMP"

printf '\n==> Done. Log out and back in for zsh to take effect.\n'
printf '    Start dwm with: startx ~/.xinitrc-dwm\n'
