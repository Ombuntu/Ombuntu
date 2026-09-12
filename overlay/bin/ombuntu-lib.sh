#!/bin/bash
# Shared helpers for Ombuntu's Ubuntu-side installers. Source, do not execute.

ombuntu_arch() { dpkg --print-architecture; }

# apt_repo_add <name> <key-url> <deb-line-without-signed-by>
# Installs a third-party apt repository with its key under /etc/apt/keyrings.
apt_repo_add() {
  local name="$1" key_url="$2" deb_line="$3"
  local keyring="/etc/apt/keyrings/$name.gpg" list="/etc/apt/sources.list.d/$name.list"
  sudo install -d -m 0755 /etc/apt/keyrings
  if [[ ! -s $keyring ]]; then
    if curl -fsSL --retry 3 "$key_url" | gpg --dearmor 2>/dev/null | sudo tee "$keyring" >/dev/null && [[ -s $keyring ]]; then :; else
      curl -fsSL --retry 3 "$key_url" | sudo tee "$keyring" >/dev/null # already binary
    fi
    sudo chmod 0644 "$keyring"
  fi
  local line="${deb_line/deb /deb [signed-by=$keyring] }"
  [[ -f $list ]] && grep -qF "$line" "$list" || echo "$line" | sudo tee "$list" >/dev/null
  sudo apt-get update -qq
}

# deb_install <url> [sha256]  Download a .deb (verified when a sum is given) and install it with apt.
deb_install() {
  local url="$1" sum="${2:-}" tmp
  tmp=$(mktemp -d) || return 1
  echo "Downloading $(basename "$url")..."
  curl -fsSL --retry 3 -o "$tmp/pkg.deb" "$url" || { rm -rf "$tmp"; return 1; }
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
