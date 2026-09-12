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

# Tags are mutable; the commit they must point at is pinned in install.sh / lib.sh.
actual=$(git -C "$OMARCHY_PATH" rev-parse HEAD)
if [[ -n $OMARCHY_COMMIT && $actual != "$OMARCHY_COMMIT" ]]; then
  die "Upstream tag $OMARCHY_REF resolves to $actual, expected $OMARCHY_COMMIT. Refusing to continue; if upstream re-tagged legitimately, update OMARCHY_COMMIT."
fi

log "Applying Ubuntu overlay"
cp -R "$OMBUNTU_REPO/overlay/." "$OMARCHY_PATH/"
chmod +x "$OMARCHY_PATH"/bin/* "$OMARCHY_PATH"/default/waybar/indicators/*.sh 2>/dev/null || true

# Only Ombuntu wallpapers are offered: drop the per-theme background images that Omarchy
# ships (the background chooser lists ~/.config/omarchy/current/theme/backgrounds and the
# user's ~/.config/omarchy/backgrounds/<theme>; the second is where ours are linked).
rm -rf "$OMARCHY_PATH"/themes/*/backgrounds

# Remember where this installer lives so `omarchy-update` can re-apply it
echo "$OMBUNTU_REPO" >"$OMARCHY_PATH/ombuntu-repo.path"
cp -f "$OMBUNTU_REPO/VERSION" "$OMARCHY_PATH/ombuntu-version"

# Walker autostart entry needs an absolute path (systemd's xdg-autostart
# generator does not see ~/.local/bin) and must not start under XFCE.
home_esc=$(printf '%s' "$HOME" | sed 's/[&|\\]/\\&/g')
sed -i "s|^Exec=.*|Exec=\"$home_esc/.local/bin/walker\" --gapplication-service|" "$OMARCHY_PATH/default/walker/walker.desktop"
grep -q "^OnlyShowIn=" "$OMARCHY_PATH/default/walker/walker.desktop" || echo "OnlyShowIn=Hyprland;" >>"$OMARCHY_PATH/default/walker/walker.desktop"

# Link the Omarchy shims into ~/.local/bin so they're on PATH everywhere,
# including the systemd user manager and XFCE terminals.
mkdir -p ~/.local/bin
ln -sfn "$OMARCHY_PATH/bin/omarchy" ~/.local/bin/omarchy

# Trim the menu to entries that work on Ubuntu (see install/patch-menu.py)
python3 "$OMBUNTU_REPO/install/patch-menu.py" "$OMARCHY_PATH/bin/omarchy-menu"
