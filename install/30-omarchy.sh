#!/bin/bash
# Clone upstream Omarchy at a pinned tag into ~/.local/share/omarchy, then lay
# the Ubuntu overlay (this repo's overlay/ directory) on top of it.
set -eEo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

if [[ -d $OMARCHY_PATH/.git ]]; then
  current=$(git -C "$OMARCHY_PATH" describe --tags --exact-match 2>/dev/null || true)
  if [[ $current != "$OMARCHY_REF" ]]; then
    log "Updating Omarchy checkout to $OMARCHY_REF"
    git -C "$OMARCHY_PATH" fetch --depth 1 origin "refs/tags/$OMARCHY_REF:refs/tags/$OMARCHY_REF"
    git -C "$OMARCHY_PATH" checkout -q --force "$OMARCHY_REF"
  else
    # Drop any previous overlay so upstream files are pristine before re-applying
    git -C "$OMARCHY_PATH" checkout -q -- . 2>/dev/null || true
    git -C "$OMARCHY_PATH" clean -qfd 2>/dev/null || true
  fi
else
  log "Cloning Omarchy $OMARCHY_REF"
  rm -rf "$OMARCHY_PATH"
  git clone -q --depth 1 --branch "$OMARCHY_REF" "$OMARCHY_UPSTREAM" "$OMARCHY_PATH"
fi

log "Applying Ubuntu overlay"
cp -R "$OMBUNTU_REPO/overlay/." "$OMARCHY_PATH/"
chmod +x "$OMARCHY_PATH"/bin/* "$OMARCHY_PATH"/default/waybar/indicators/*.sh 2>/dev/null || true

# Remember where this installer lives so `omarchy-update` can re-apply it
echo "$OMBUNTU_REPO" >"$OMARCHY_PATH/ombuntu-repo.path"

# Walker autostart entry needs an absolute path (systemd's xdg-autostart
# generator does not see ~/.local/bin) and must not start under XFCE.
sed -i "s|^Exec=.*|Exec=$HOME/.local/bin/walker --gapplication-service|" "$OMARCHY_PATH/default/walker/walker.desktop"
grep -q "^OnlyShowIn=" "$OMARCHY_PATH/default/walker/walker.desktop" || echo "OnlyShowIn=Hyprland;" >>"$OMARCHY_PATH/default/walker/walker.desktop"

# Link the Omarchy shims into ~/.local/bin so they're on PATH everywhere,
# including the systemd user manager and XFCE terminals.
mkdir -p ~/.local/bin
ln -sfn "$OMARCHY_PATH/bin/omarchy" ~/.local/bin/omarchy

# Small menu text fixes: "Learn > Arch" becomes Ubuntu docs, AUR entry is labelled
menu="$OMARCHY_PATH/bin/omarchy-menu"
sed -i 's/󰣇  Arch\\n/  Ubuntu\\n/' "$menu"
sed -i 's|\*Arch\*) omarchy-launch-webapp "https://wiki.archlinux.org[^"]*"|*Ubuntu*) omarchy-launch-webapp "https://help.ubuntu.com/"|' "$menu"
sed -i 's/󰣇  AUR\\n/󰣇  AUR (n\/a on Ubuntu)\\n/' "$menu"

# No menu extensions: upstream sources ~/.config/omarchy/extensions/menu.sh into omarchy-menu
sed -i '/^USER_EXTENSIONS=/d; /\$USER_EXTENSIONS/d; /^# Allow user extensions and overrides$/d' "$menu"
