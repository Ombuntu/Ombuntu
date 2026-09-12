#!/bin/bash
# Shared helpers for Ombuntu's Ubuntu-side installers. Source, do not execute.
set -o pipefail

ombuntu_arch() { dpkg --print-architecture; }

# apt_repo_add <name> <key-url> <deb-line-without-signed-by> <key-fingerprint>
# Installs a third-party apt repository. The key is fetched over TLS and refused unless its
# fingerprint matches the one pinned in the calling handler.
apt_repo_add() {
  local name="$1" key_url="$2" deb_line="$3" want_fpr="${4:?apt_repo_add needs the key fingerprint}"
  local keyring="/etc/apt/keyrings/$name.gpg" list="/etc/apt/sources.list.d/$name.list" tmp fpr
  sudo install -d -m 0755 /etc/apt/keyrings
  if [[ ! -s $keyring ]]; then
    tmp=$(mktemp -d) || return 1
    curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$tmp/key" "$key_url" || { rm -rf "$tmp"; return 1; }
    fpr=$(gpg --show-keys --with-colons "$tmp/key" 2>/dev/null | awk -F: '$1=="fpr"{print $10; exit}')
    if [[ $fpr != "$want_fpr" ]]; then
      echo "Refusing $name apt key: fingerprint $fpr, expected $want_fpr" >&2; rm -rf "$tmp"; return 1
    fi
    if ! gpg --dearmor <"$tmp/key" >"$tmp/keyring" 2>/dev/null; then cp "$tmp/key" "$tmp/keyring"; fi # already binary
    sudo install -m 0644 "$tmp/keyring" "$keyring"
    rm -rf "$tmp"
  fi
  # One option group only: "deb [arch=x] URL" -> "deb [signed-by=K arch=x] URL"
  local line
  if [[ $deb_line == "deb ["* ]]; then line="${deb_line/deb [/deb [signed-by=$keyring }"
  else line="${deb_line/deb /deb [signed-by=$keyring] }"; fi
  if ! { [[ -f $list ]] && grep -qxF "$line" "$list"; }; then
    echo "$line" | sudo tee "$list" >/dev/null
  fi
  if ! sudo apt-get update -qq; then
    echo "apt-get update failed after adding $name; removing $list so apt keeps working" >&2
    sudo rm -f "$list"
    return 1
  fi
}

# deb_install <url> [sha256]  Download a .deb (verified when a sum is given) and install it with apt.
deb_install() {
  local url="$1" sum="${2:-}" tmp
  tmp=$(mktemp -d) || return 1
  echo "Downloading $(basename "$url")..."
  curl -fsSL --proto '=https' --proto-redir '=https' --retry 3 -o "$tmp/pkg.deb" "$url" || { rm -rf "$tmp"; return 1; }
  if [[ -n $sum ]] && [[ $(sha256sum "$tmp/pkg.deb" | cut -d' ' -f1) != "$sum" ]]; then
    echo "Checksum mismatch for $url" >&2; rm -rf "$tmp"; return 1
  fi
  sudo apt-get install -y "$tmp/pkg.deb"
  local rc=$?
  rm -rf "$tmp"
  return $rc
}

# gh_asset_url <owner/repo> <tag> <asset-name>
gh_asset_url() { echo "https://github.com/$1/releases/download/$2/$3"; }

# verify_sha256_from_list <file> <sums-file>  (sums file in "sha  name" format)
verify_sha256_from_list() {
  local file="$1" sums="$2" expected
  expected=$(awk -v n="$(basename "$file")" '$2 == n || $2 == "./" n || $2 == "*" n {print $1}' "$sums" | head -1)
  [[ -n $expected ]] || { echo "No checksum for $(basename "$file")" >&2; return 1; }
  [[ $(sha256sum "$file" | cut -d' ' -f1) == "$expected" ]] || { echo "Checksum mismatch for $(basename "$file")" >&2; return 1; }
}

# desktop_entry <id> <name> <exec> <icon> [categories]
desktop_entry() {
  mkdir -p ~/.local/share/applications
  cat >~/.local/share/applications/"$1.desktop" <<DESK
[Desktop Entry]
Type=Application
Name=$2
Exec=$3
Icon=$4
Terminal=false
Categories=${5:-Utility;}
DESK
  update-desktop-database ~/.local/share/applications 2>/dev/null || true
}

not_available() { # not_available <name> <how-to-get-it>
  echo -e "\033[33m$1 is not packaged for Ubuntu by Ombuntu.\033[0m"
  echo -e "$2"
  return 1
}
