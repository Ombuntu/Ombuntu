#!/bin/bash
#
# Ombuntu installer (Omarchy on Xubuntu)
#
# Reproduces the Omarchy (v3.8.x) Hyprland desktop on Ubuntu/Xubuntu 26.04.
# Safe to re-run: every step is idempotent. Existing personal config files are
# never overwritten unless you pass --force-config.
#
# One-line install on a fresh Ubuntu / Xubuntu 26.04:
#   curl -fsSL https://ombuntu.org/install.sh | bash
#
# From a checkout:
#   ./install.sh                 full install (asks for sudo once for apt + session file)
#   ./install.sh --user-only     skip the steps that need root (apt packages, session file)
#   ./install.sh --skip-bashrc   leave ~/.bashrc alone
#   ./install.sh --force-config  overwrite ~/.config files with Omarchy defaults (backups are made)
#
# Piped form takes the same flags:  curl -fsSL https://ombuntu.org/install.sh | bash -s -- --skip-bashrc
#
set -eEo pipefail

# ---------------------------------------------------------------------------
# Bootstrap: when this file is run on its own (curl | bash, or a lone copy),
# fetch the repository and hand over to the copy inside it.
# ---------------------------------------------------------------------------
if [[ -z ${BASH_SOURCE[0]} || ! -d "$(dirname "${BASH_SOURCE[0]}")/install" ]]; then
  OMBUNTU_HOME="${OMBUNTU_HOME:-$HOME/.local/share/ombuntu/repo}"
  OMBUNTU_REPO_URL="${OMBUNTU_REPO_URL:-https://github.com/Ombuntu/Ombuntu.git}"
  OMBUNTU_BRANCH="${OMBUNTU_BRANCH:-main}"

  printf '\033[32m==>\033[0m %s\n' "Ombuntu: Omarchy on Xubuntu"

  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:-} ${ID_LIKE:-}" in
      *ubuntu* | *debian*) ;;
      *) printf '\033[31m==> ERROR:\033[0m %s\n' "This installer is for Ubuntu / Xubuntu 26.04 (found ${PRETTY_NAME:-unknown})." >&2; exit 1 ;;
    esac
  fi

  if ! command -v git >/dev/null || ! command -v curl >/dev/null; then
    printf '\033[32m==>\033[0m %s\n' "Installing git and curl (sudo)"
    sudo apt-get update -qq
    sudo apt-get install -y -qq git curl
  fi

  if [[ -d $OMBUNTU_HOME/.git ]]; then
    printf '\033[32m==>\033[0m %s\n' "Updating $OMBUNTU_HOME"
    git -C "$OMBUNTU_HOME" pull -q --ff-only --no-rebase
  else
    printf '\033[32m==>\033[0m %s\n' "Fetching Ombuntu into $OMBUNTU_HOME"
    mkdir -p "$(dirname "$OMBUNTU_HOME")"
    git clone -q --depth 1 --branch "$OMBUNTU_BRANCH" "$OMBUNTU_REPO_URL" "$OMBUNTU_HOME"
  fi

  # Hand the terminal back to the real installer so sudo and prompts work when piped from curl
  if ( : </dev/tty ) 2>/dev/null; then
    exec bash "$OMBUNTU_HOME/install.sh" "$@" </dev/tty
  else
    exec bash "$OMBUNTU_HOME/install.sh" "$@"
  fi
fi

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
  -h | --help) sed -n '2,/^set -eEo/p' "$0" | head -n -1; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

source "$OMBUNTU_REPO/install/lib.sh"

step "Preflight" "$OMBUNTU_REPO/install/00-preflight.sh"

if [[ $OMARCHY_USER_ONLY == false ]]; then
  log "Root access is needed for apt and the login session file"
  sudo -v
  step "Packages (apt)" "$OMBUNTU_REPO/install/10-packages.sh" root
  step "Third-party apt repos (Signal)" "$OMBUNTU_REPO/install/15-third-party.sh" root
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
