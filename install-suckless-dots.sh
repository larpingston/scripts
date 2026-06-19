#!/bin/sh
set -e

printf "sudo or doas > "
read -r PRIV

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
      meson ninja cmake \
      base-devel"

AUR_HELPER_PKG="yay-bin"
AUR_DEPS="picom-ftlabs-git"

SUCKLESS_DIR="$HOME/suckless"
DOTS_TMP="/tmp/suckless-dots-install"
CONFIG_DIR="$HOME/.config"

printf '\n==> Installing pacman dependencies...\n'
$PRIV pacman -S --needed --noconfirm $DEPS

printf '\n==> Installing AUR helper and AUR packages...\n'
AUR_BUILD_DIR="/tmp/aur-build-$$"
mkdir -p "$AUR_BUILD_DIR"

SHIM_DIR="/tmp/sudo-shim-$$"
mkdir -p "$SHIM_DIR"
cat > "$SHIM_DIR/sudo" <<EOF
#!/bin/sh
ARGS=
for a in "\$@"; do
    case "\$a" in
        -k) continue ;;
    esac
    ARGS="\$ARGS '\$a'"
done
eval exec $PRIV \$ARGS
EOF
chmod +x "$SHIM_DIR/sudo"

OLD_PATH="$PATH"
PATH="$SHIM_DIR:$PATH"
export PATH

if ! command -v yay >/dev/null 2>&1; then
    printf '  -> Building %s\n' "$AUR_HELPER_PKG"
    git clone "https://aur.archlinux.org/${AUR_HELPER_PKG}.git" "$AUR_BUILD_DIR/$AUR_HELPER_PKG"
    cd "$AUR_BUILD_DIR/$AUR_HELPER_PKG"
    PACMAN=pacman makepkg -si --noconfirm --needed
    cd /
fi

for pkg in $AUR_DEPS; do
    printf '  -> Installing %s with yay\n' "$pkg"
    yay -S --noconfirm --needed --removemake "$pkg"
done

PATH="$OLD_PATH"
export PATH
rm -rf "$SHIM_DIR"
rm -rf "$AUR_BUILD_DIR"

printf '\n==> Setting up suckless programs in %s...\n' "$SUCKLESS_DIR"

rm -rf "$SUCKLESS_DIR"
git clone https://github.com/larpingston/suckless "$SUCKLESS_DIR"

for prog in dwm dmenu dwmblocks st; do
    printf '  -> Compiling and installing %s...\n' "$prog"
    cd "$SUCKLESS_DIR/$prog"
    $PRIV make clean install
done

printf '\n==> Fetching dotfiles...\n'
rm -rf "$DOTS_TMP"
git clone https://github.com/larpingston/suckless-dots "$DOTS_TMP"

mkdir -p "$CONFIG_DIR"

printf '\n==> Deploying ~/.config entries...\n'
for dir in nvim picom dunst conky; do
    printf '  -> %s -> %s/%s\n' "$dir" "$CONFIG_DIR" "$dir"
    rm -rf "${CONFIG_DIR:?}/$dir"
    cp -r "$DOTS_TMP/$dir" "$CONFIG_DIR/$dir"
done

printf '  -> bookmarks.txt -> %s\n' "$CONFIG_DIR"
cp "$DOTS_TMP/bookmarks.txt" "$CONFIG_DIR/bookmarks.txt"

printf '  -> emojis.txt -> %s\n' "$CONFIG_DIR"
cp "$DOTS_TMP/emojis.txt" "$CONFIG_DIR/emojis.txt"

printf '  -> scripts -> %s/scripts\n' "$HOME"
rm -rf "${HOME:?}/scripts"
cp -r "$DOTS_TMP/scripts" "$HOME/scripts"

printf '  -> xinitrc-dwm.txt -> ~/.xinitrc-dwm\n'
cp "$DOTS_TMP/xinitrc-dwm.txt" "$HOME/.xinitrc-dwm"

printf '  -> zshrc.txt -> ~/.zshrc\n'
cp "$DOTS_TMP/zshrc.txt" "$HOME/.zshrc"

printf '\n==> Setting zsh as default shell...\n'
ZSH_PATH="$(command -v zsh)"
if ! grep -qx "$ZSH_PATH" /etc/shells; then
    printf '%s\n' "$ZSH_PATH" | $PRIV tee -a /etc/shells > /dev/null
fi
chsh -s "$ZSH_PATH"

printf '\n==> Cleaning up...\n'
rm -rf "$DOTS_TMP"

printf '\n==> Done. Log out and back in for zsh to take effect.\n'
printf '    Start dwm with: startx ~/.xinitrc-dwm\n'
