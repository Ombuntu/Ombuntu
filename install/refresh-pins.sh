#!/bin/bash
#
# Regenerate overlay/bin/ombuntu-pins.sh: the pinned version and SHA256 of every
# application the Install menu downloads from GitHub releases. Run it when you
# want to move an app to a newer release, then review the diff and commit.
#
#   install/refresh-pins.sh            refresh every app to its latest release
#   install/refresh-pins.sh helix zed  refresh only those (latest release)
#   install/refresh-pins.sh zed=v1.19.2 refresh to an explicit tag (no GitHub API call)
#   install/refresh-pins.sh --check    verify install/checksums.sha256 against publisher sums
#
# Sums come from the publisher's own checksum file where one exists (Ollama,
# Voxtype, mise, Nerd Fonts); otherwise the asset is downloaded and hashed here.
set -eEuo pipefail
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PINS="$REPO/overlay/bin/ombuntu-pins.sh"
CACHE="${OMBUNTU_PIN_CACHE:-$HOME/.cache/ombuntu/pins}"
mkdir -p "$CACHE"
log() { printf '\033[32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31m==> ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

latest_tag() { curl -fsSL --retry 3 "https://api.github.com/repos/$1/releases/latest" | jq -r .tag_name; }
asset_url() { echo "https://github.com/$1/releases/download/$2/$3"; }
hash_asset() { # hash_asset <repo> <tag> <asset>  -> sha256 (downloads to the cache)
  local f="$CACHE/$2-$3"
  [[ -s $f ]] || curl -fsSL --proto '=https' --retry 3 -o "$f" "$(asset_url "$1" "$2" "$3")"
  sha256sum "$f" | cut -d' ' -f1
}
published_sum() { # published_sum <repo> <tag> <sums-file> <asset>
  curl -fsSL --retry 3 "$(asset_url "$1" "$2" "$3")" | awk -v n="$4" '$2 == n || $2 == "./" n || $2 == "*" n {print $1; exit}'
}

declare -A V S  # version per app, sums per key
[[ -f $PINS ]] && source "$PINS"
keep() { # keep <app> <KEY>: carry the current value forward when the app is not being refreshed
  local var="PIN_${2}"; S[$2]="${!var:-}"
}

if [[ ${1:-} == --check ]]; then
  log "Cross-checking install/checksums.sha256 against publisher sums"
  mise_ver=$(grep -oE 'MISE_VERSION:-v[0-9.]+' "$REPO/install/20-binaries.sh" | cut -d- -f2)
  for a in amd64:linux-x64 arm64:linux-arm64; do
    ours=$(awk -v n="mise-$mise_ver-${a%%:*}.tar.gz" '$2==n{print $1}' "$REPO/install/checksums.sha256")
    theirs=$(published_sum jdx/mise "$mise_ver" SHASUMS256.txt "mise-$mise_ver-${a##*:}.tar.gz")
    [[ $ours == "$theirs" ]] && echo "  ok   mise ${a%%:*}" || die "mise ${a%%:*}: ours $ours, publisher $theirs"
  done
  nf_ver=$(grep -oE 'NERD_FONTS_VERSION:-v[0-9.]+' "$REPO/install/25-fonts.sh" | cut -d- -f2)
  ours=$(awk -v n="JetBrainsMono-$nf_ver.tar.xz" '$2==n{print $1}' "$REPO/install/checksums.sha256")
  theirs=$(published_sum ryanoasis/nerd-fonts "$nf_ver" SHA-256.txt JetBrainsMono.tar.xz)
  [[ $ours == "$theirs" ]] && echo "  ok   JetBrainsMono Nerd Font" || die "Nerd Font: ours $ours, publisher $theirs"
  echo "  (Walker, Elephant and Satty publish no checksum files; theirs are first-download pins)"
  exit 0
fi

# Arguments: app names, optionally app=tag to pin an explicit version (skips the GitHub API,
# which rate-limits unauthenticated lookups).
declare -A TAG
apps=()
for arg in "$@"; do
  if [[ $arg == *=* ]]; then apps+=("${arg%%=*}"); TAG[${arg%%=*}]="${arg#*=}"; else apps+=("$arg"); fi
done
(( ${#apps[@]} )) || apps=(helix heroic localsend moonlight zed ollama voxtype)
want() { local a; for a in "${apps[@]}"; do [[ $a == "$1" ]] && return 0; done; return 1; }
tag_for() { echo "${TAG[$1]:-$(latest_tag "$2")}"; }

# ---- each app: version + sums --------------------------------------------------
if want helix; then
  t=$(tag_for helix helix-editor/helix); log "helix $t"; V[HELIX]=$t
  S[HELIX_SHA256_AMD64]=$(hash_asset helix-editor/helix "$t" "helix-$t-x86_64-linux.tar.xz")
  S[HELIX_SHA256_ARM64]=$(hash_asset helix-editor/helix "$t" "helix-$t-aarch64-linux.tar.xz")
else V[HELIX]=${PIN_HELIX_VERSION:-}; keep helix HELIX_SHA256_AMD64; keep helix HELIX_SHA256_ARM64; fi

if want heroic; then
  t=$(tag_for heroic Heroic-Games-Launcher/HeroicGamesLauncher); log "heroic $t"; V[HEROIC]=$t
  S[HEROIC_SHA256_AMD64]=$(hash_asset Heroic-Games-Launcher/HeroicGamesLauncher "$t" "Heroic-${t#v}-linux-amd64.deb")
else V[HEROIC]=${PIN_HEROIC_VERSION:-}; keep heroic HEROIC_SHA256_AMD64; fi

if want localsend; then
  t=$(tag_for localsend localsend/localsend); log "localsend $t"; V[LOCALSEND]=$t
  S[LOCALSEND_SHA256_AMD64]=$(hash_asset localsend/localsend "$t" "LocalSend-${t#v}-linux-x86-64.deb")
  S[LOCALSEND_SHA256_ARM64]=$(hash_asset localsend/localsend "$t" "LocalSend-${t#v}-linux-arm-64.deb")
else V[LOCALSEND]=${PIN_LOCALSEND_VERSION:-}; keep localsend LOCALSEND_SHA256_AMD64; keep localsend LOCALSEND_SHA256_ARM64; fi

if want moonlight; then
  t=$(tag_for moonlight moonlight-stream/moonlight-qt); log "moonlight $t"; V[MOONLIGHT]=$t
  S[MOONLIGHT_SHA256_AMD64]=$(hash_asset moonlight-stream/moonlight-qt "$t" "Moonlight-${t#v}-x86_64.AppImage")
else V[MOONLIGHT]=${PIN_MOONLIGHT_VERSION:-}; keep moonlight MOONLIGHT_SHA256_AMD64; fi

if want zed; then
  t=$(tag_for zed zed-industries/zed); log "zed $t"; V[ZED]=$t
  S[ZED_SHA256_AMD64]=$(hash_asset zed-industries/zed "$t" zed-linux-x86_64.tar.gz)
  S[ZED_SHA256_ARM64]=$(hash_asset zed-industries/zed "$t" zed-linux-aarch64.tar.gz)
else V[ZED]=${PIN_ZED_VERSION:-}; keep zed ZED_SHA256_AMD64; keep zed ZED_SHA256_ARM64; fi

if want ollama; then
  t=$(tag_for ollama ollama/ollama); log "ollama $t (publisher sums)"; V[OLLAMA]=$t
  S[OLLAMA_SHA256_AMD64]=$(published_sum ollama/ollama "$t" sha256sum.txt ollama-linux-amd64.tar.zst)
  S[OLLAMA_SHA256_ARM64]=$(published_sum ollama/ollama "$t" sha256sum.txt ollama-linux-arm64.tar.zst)
  S[OLLAMA_ROCM_SHA256_AMD64]=$(published_sum ollama/ollama "$t" sha256sum.txt ollama-linux-amd64-rocm.tar.zst)
else V[OLLAMA]=${PIN_OLLAMA_VERSION:-}; keep ollama OLLAMA_SHA256_AMD64; keep ollama OLLAMA_SHA256_ARM64; keep ollama OLLAMA_ROCM_SHA256_AMD64; fi

if want voxtype; then
  t=$(tag_for voxtype peteonrails/voxtype); log "voxtype $t (publisher sums)"; V[VOXTYPE]=$t
  S[VOXTYPE_SHA256_AVX2]=$(published_sum peteonrails/voxtype "$t" SHA256SUMS.txt "voxtype-${t#v}-linux-x86_64-avx2")
  S[VOXTYPE_SHA256_AUDIO_BRIDGE]=$(published_sum peteonrails/voxtype "$t" SHA256SUMS.txt "voxtype-${t#v}-linux-x86_64-audio-bridge")
else V[VOXTYPE]=${PIN_VOXTYPE_VERSION:-}; keep voxtype VOXTYPE_SHA256_AVX2; keep voxtype VOXTYPE_SHA256_AUDIO_BRIDGE; fi

for k in "${!S[@]}"; do [[ ${S[$k]} =~ ^[0-9a-f]{64}$ ]] || die "no valid sum for $k"; done

{
  echo "# Pinned releases for apps the Install menu downloads. Generated by install/refresh-pins.sh"
  echo "# on $(date -u +%Y-%m-%d); edit by re-running it, not by hand."
  echo "# shellcheck shell=bash"
  for app in HELIX HEROIC LOCALSEND MOONLIGHT ZED OLLAMA VOXTYPE; do
    echo "PIN_${app}_VERSION=${V[$app]}"
    for k in $(printf '%s\n' "${!S[@]}" | grep "^${app}_" | sort); do echo "PIN_$k=${S[$k]}"; done
  done
} >"$PINS"
log "Wrote $PINS"
cat "$PINS"
