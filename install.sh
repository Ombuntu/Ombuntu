#!/bin/bash
#
# Ombuntu installer (Omarchy on Xubuntu)
#
# Reproduces the Omarchy (v3.8.x) Hyprland desktop on Ubuntu/Xubuntu 26.04.
# Safe to re-run: every step is idempotent. Existing personal config files are
# never overwritten unless you pass --force-config.
#
# Usage:
#   ./install.sh                 full install (asks for sudo once for apt + session file)
#   ./install.sh --user-only     skip the steps that need root (apt packages, session file)
#   ./install.sh --skip-bashrc   leave ~/.bashrc alone
#   ./install.sh --force-config  overwrite ~/.config files with Omarchy defaults (backups are made)
#
set -eEo pipefail

export OMBUNTU_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_REF="${OMARCHY_REF:-v3.8.4}"
export OMARCHY_UPSTREAM="${OMARCHY_UPSTREAM:-https://github.com/basecamp/omarchy.git}"
export PATH="$OMARCHY_PATH/bin:$HOME/.local/bin:$PATH"

export OMARCHY_USER_ONLY=false
export OMARCHY_SKIP_BASHRC=false
export OMARCHY_FORCE_CONFIG=false

for arg in "$@"; do
  case "$arg" in
  --user-only) OMARCHY_USER_ONLY=true ;;
  --skip-bashrc) OMARCHY_SKIP_BASHRC=true ;;
  --force-config) OMARCHY_FORCE_CONFIG=true ;;
  -h | --help) sed -n '2,15p' "$0"; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

source "$OMBUNTU_REPO/install/lib.sh"

step "Preflight" "$OMBUNTU_REPO/install/00-preflight.sh"

if [[ $OMARCHY_USER_ONLY == false ]]; then
  log "Root access is needed for apt and the login session file"
  sudo -v
  step "Packages (apt)" "$OMBUNTU_REPO/install/10-packages.sh" root
fi

step "Omarchy core + Ubuntu overlay" "$OMBUNTU_REPO/install/30-omarchy.sh"
step "Binaries not packaged by Ubuntu" "$OMBUNTU_REPO/install/20-binaries.sh"
step "Fonts" "$OMBUNTU_REPO/install/25-fonts.sh"
step "User configuration" "$OMBUNTU_REPO/install/40-config.sh"
step "Theme" "$OMBUNTU_REPO/install/50-theme.sh"

if [[ $OMARCHY_USER_ONLY == false ]]; then
  step "Login session" "$OMBUNTU_REPO/install/60-session.sh" root
fi

step "Verify Hyprland config" "$OMBUNTU_REPO/install/90-verify.sh"

echo
log "Done. Log out and pick the \"Ombuntu\" session in the LightDM greeter."
log "Super+Alt+Space opens the Ombuntu menu, Super+K lists keybindings."
