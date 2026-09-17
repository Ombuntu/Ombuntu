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
#   ./install.sh --keep-telemetry        leave Canonical/browser telemetry at Ubuntu defaults
#   ./install.sh --keep-browser-buttons  keep browsers' own minimize/maximize/close buttons
#   ./install.sh --no-firefox-policy     do not install the Firefox policy file (managed machines)
#
# Piped form takes the same flags:  curl -fsSL https://ombuntu.org/install.sh | bash -s -- --skip-bashrc
#
set -eEuo pipefail
: "${HOME:?HOME must be set}"

# ---------------------------------------------------------------------------
# Bootstrap: when this file is run on its own (curl | bash, or a lone copy),
# fetch the repository and hand over to the copy inside it.
# ---------------------------------------------------------------------------
# A checkout is only trusted when it is a git repository owned by this user and not
# writable by others; a lone copy of this file next to a planted install/ directory
# (in /tmp, say) must not be used.
is_own_checkout() {
  local d="$1" mode uid gid
  [[ -f $d/install/lib.sh && -f $d/VERSION && -d $d/.git ]] || return 1
  read -r uid gid mode < <(stat -c '%u %g %a' "$d") || return 1
  [[ $uid == "$(id -u)" ]] || return 1
  [[ ${mode: -1} =~ [0-5] ]] || return 1                       # not world-writable
  # group-writable is fine only for the user's own primary group (Ubuntu user-private groups)
  [[ ${mode: -2:1} =~ [0-5] || $gid == "$(id -g)" ]]
}
if [[ -n ${BASH_SOURCE[0]} ]] && ! is_own_checkout "$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; then
  d="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
  printf '\033[33m==> WARNING:\033[0m %s\n' "Not using the checkout at $d (needs .git, VERSION, install/lib.sh; owned by you; not writable by others: $(stat -c 'owner %U group %G mode %a' "$d" 2>/dev/null)). Fetching a release instead."
fi
if [[ -z ${BASH_SOURCE[0]} ]] || ! is_own_checkout "$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"; then
  OMBUNTU_HOME="${OMBUNTU_HOME:-$HOME/.local/share/ombuntu/repo}"
  OMBUNTU_REPO_URL="${OMBUNTU_REPO_URL:-https://github.com/Ombuntu/Ombuntu.git}"
  # Default: the newest release tag. OMBUNTU_REF=main opts into the development branch.
  OMBUNTU_REF="${OMBUNTU_REF:-${OMBUNTU_BRANCH:-}}"

  printf '\033[32m==>\033[0m %s\n' "Ombuntu: Omarchy on Xubuntu"

  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:-} ${ID_LIKE:-}" in
      *ubuntu* | *debian*) ;;
      *) printf '\033[31m==> ERROR:\033[0m %s\n' "This installer is for Ubuntu / Xubuntu 26.04 (found ${PRETTY_NAME:-unknown})." >&2; exit 1 ;;
    esac
    if [[ ${ID:-} == ubuntu && $(printf '%s\n' "${VERSION_ID:-0}" 26.04 | sort -V | head -1) != 26.04 ]]; then
      printf '\033[31m==> ERROR:\033[0m %s\n' "Ombuntu needs Ubuntu 26.04 or newer, found ${PRETTY_NAME:-unknown}. Earlier releases do not ship Hyprland." >&2
      exit 1
    fi
  fi

  if ! command -v git >/dev/null || ! command -v curl >/dev/null; then
    printf '\033[32m==>\033[0m %s\n' "Installing git and curl (sudo)"
    sudo apt-get update -qq
    sudo apt-get install -y -qq git curl
  fi

  if [[ -z $OMBUNTU_REF ]]; then
    OMBUNTU_REF=$(git ls-remote --tags "$OMBUNTU_REPO_URL" 2>/dev/null | grep -v '\^{}' | sed 's|.*refs/tags/||' | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -1)
    [[ -n $OMBUNTU_REF ]] || { printf '\033[31m==> ERROR:\033[0m %s\n' "Could not determine the latest Ombuntu release; set OMBUNTU_REF=main to use the development branch." >&2; exit 1; }
  fi

  # Release tags must be signed by the Ombuntu release key (SSH signature). The key is embedded
  # here on purpose: this file is served from ombuntu.org, so a compromised GitHub repository
  # cannot ship a tag signed by some other key together with a matching signer list.
  OMBUNTU_RELEASE_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPM3a2X/L2JZ5fcl//oGA7F97c5ZvrZG29WTSoRIzics"
  verify_release_tag() { # verify_release_tag <repo-dir> <tag>
    local signers; signers=$(mktemp)
    echo "ombuntu-release $OMBUNTU_RELEASE_KEY" >"$signers"
    if git -C "$1" -c gpg.format=ssh -c gpg.ssh.allowedSignersFile="$signers" verify-tag "$2" >/dev/null 2>&1; then
      rm -f "$signers"; return 0
    fi
    rm -f "$signers"; return 1
  }

  if [[ -d $OMBUNTU_HOME/.git ]]; then
    printf '\033[32m==>\033[0m %s\n' "Updating $OMBUNTU_HOME to $OMBUNTU_REF"
    git -C "$OMBUNTU_HOME" fetch -q --tags origin
    if [[ $OMBUNTU_REF == main ]]; then
      git -C "$OMBUNTU_HOME" checkout -q main && git -C "$OMBUNTU_HOME" pull -q --ff-only --no-rebase
    else
      git -C "$OMBUNTU_HOME" checkout -q --force "$OMBUNTU_REF"
    fi
  else
    printf '\033[32m==>\033[0m %s\n' "Fetching Ombuntu $OMBUNTU_REF into $OMBUNTU_HOME"
    mkdir -p "$(dirname "$OMBUNTU_HOME")"
    git clone -q --branch "$OMBUNTU_REF" "$OMBUNTU_REPO_URL" "$OMBUNTU_HOME"
  fi

  if [[ $OMBUNTU_REF != main ]] && ! verify_release_tag "$OMBUNTU_HOME" "$OMBUNTU_REF"; then
    printf '\033[31m==> ERROR:\033[0m %s\n' "Release tag $OMBUNTU_REF is not signed by the Ombuntu release key. Refusing to run it. (OMBUNTU_REF=main skips this check for development.)" >&2
    exit 1
  fi

  # Hand the terminal back to the real installer so sudo and prompts work when piped from curl
  if ( : </dev/tty ) 2>/dev/null; then
    exec bash "$OMBUNTU_HOME/install.sh" "$@" </dev/tty
  else
    exec bash "$OMBUNTU_HOME/install.sh" "$@"
  fi
fi

OMBUNTU_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export OMBUNTU_REPO
export OMARCHY_PATH="$HOME/.local/share/omarchy"
export OMARCHY_REF="${OMARCHY_REF:-v3.8.4}"
export OMARCHY_COMMIT="${OMARCHY_COMMIT:-8fcc9d6048af4cb0e3af8512c78049857a3b53dd}"  # commit the tag must resolve to
export OMARCHY_UPSTREAM="${OMARCHY_UPSTREAM:-https://github.com/basecamp/omarchy.git}"
export PATH="$OMARCHY_PATH/bin:$HOME/.local/bin:$PATH"

export OMARCHY_USER_ONLY=false
export OMARCHY_SKIP_BASHRC=false
export OMARCHY_FORCE_CONFIG=false
export OMBUNTU_KEEP_TELEMETRY=false
export OMBUNTU_KEEP_BROWSER_BUTTONS=false
export OMBUNTU_NO_FIREFOX_POLICY=false

for arg in "$@"; do
  case "$arg" in
  --user-only) OMARCHY_USER_ONLY=true ;;
  --skip-bashrc) OMARCHY_SKIP_BASHRC=true ;;
  --force-config) OMARCHY_FORCE_CONFIG=true ;;
  --keep-telemetry) OMBUNTU_KEEP_TELEMETRY=true ;;
  --keep-browser-buttons) OMBUNTU_KEEP_BROWSER_BUTTONS=true ;;
  --no-firefox-policy) OMBUNTU_NO_FIREFOX_POLICY=true ;;
  -h | --help) sed -n '2,/^set -eEo/p' "$0" | head -n -1; exit 0 ;;
  *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

source "$OMBUNTU_REPO/install/lib.sh"

step "Preflight" "$OMBUNTU_REPO/install/00-preflight.sh"

if [[ $OMARCHY_USER_ONLY == false ]]; then
  log "Root access is needed for apt and the login session file"
  if ! sudo -n true 2>/dev/null && ! ( : </dev/tty ) 2>/dev/null; then
    die "sudo needs a terminal to ask for your password. Run this from a terminal window (Super + Return), or use --user-only."
  fi
  sudo -v
  step "Packages (apt)" "$OMBUNTU_REPO/install/10-packages.sh" root
  step "Third-party apt repos (Signal)" "$OMBUNTU_REPO/install/15-third-party.sh" root
fi

step "Ombuntu desktop" "$OMBUNTU_REPO/install/30-omarchy.sh"
step "Binaries not packaged by Ubuntu" "$OMBUNTU_REPO/install/20-binaries.sh"
step "Fonts" "$OMBUNTU_REPO/install/25-fonts.sh"
step "User configuration" "$OMBUNTU_REPO/install/40-config.sh"
step "Theme" "$OMBUNTU_REPO/install/50-theme.sh"

if [[ $OMARCHY_USER_ONLY == false ]]; then
  step "Login session" "$OMBUNTU_REPO/install/60-session.sh" root
  if [[ $OMBUNTU_KEEP_TELEMETRY != true ]]; then
    step "Privacy (telemetry off)" "$OMBUNTU_REPO/install/70-privacy.sh" root
  fi
  step "Browser defaults (extensions, search)" "$OMBUNTU_REPO/install/75-browser-defaults.sh" root
fi

step "Verify Hyprland config" "$OMBUNTU_REPO/install/90-verify.sh"

echo
log "Done. Log out and pick the \"Ombuntu\" session in the LightDM greeter."
log "Super+Alt+Space opens the Ombuntu menu, Super+K lists keybindings."
