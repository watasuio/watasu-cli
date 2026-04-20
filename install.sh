#!/usr/bin/env bash

set -euo pipefail

program="watasu"
base_url="${WATASU_INSTALL_BASE_URL:-https://watasuio.github.io/watasu-cli}"
version_input="${1:-latest}"

usage() {
  echo "usage: install.sh [latest|VERSION]" >&2
  exit 64
}

if [[ ! "$version_input" =~ ^(latest|v?[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z.]+)?)$ ]]; then
  usage
fi

downloader=""
if command -v curl >/dev/null 2>&1; then
  downloader="curl"
elif command -v wget >/dev/null 2>&1; then
  downloader="wget"
else
  echo "curl or wget is required" >&2
  exit 69
fi

has_jq=false
if command -v jq >/dev/null 2>&1; then
  has_jq=true
fi

download_file() {
  local url="$1"
  local output="${2:-}"

  if [ "$downloader" = "curl" ]; then
    if [ -n "$output" ]; then
      curl -fsSL -o "$output" "$url"
    else
      curl -fsSL "$url"
    fi
  else
    if [ -n "$output" ]; then
      wget -q -O "$output" "$url"
    else
      wget -q -O - "$url"
    fi
  fi
}

normalize_json() {
  tr -d '\n\r\t' | sed 's/[[:space:]][[:space:]]*/ /g'
}

get_platform_value_without_jq() {
  local json="$1"
  local platform="$2"
  local key="$3"
  local block=""

  json="$(printf '%s' "$json" | normalize_json)"

  if [[ "$json" =~ \"$platform\"[[:space:]]*:[[:space:]]*\{([^}]*)\} ]]; then
    block="${BASH_REMATCH[1]}"
  else
    return 1
  fi

  if [[ "$block" =~ \"$key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

get_top_level_value_without_jq() {
  local json="$1"
  local key="$2"

  json="$(printf '%s' "$json" | normalize_json)"

  if [[ "$json" =~ \"$key\"[[:space:]]*:[[:space:]]*\"([^\"]+)\" ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi

  return 1
}

get_platform_value() {
  local json="$1"
  local platform="$2"
  local key="$3"

  if [ "$has_jq" = true ]; then
    printf '%s' "$json" | jq -r --arg platform "$platform" --arg key "$key" '.platforms[$platform][$key] // empty'
  else
    get_platform_value_without_jq "$json" "$platform" "$key"
  fi
}

get_top_level_value() {
  local json="$1"
  local key="$2"

  if [ "$has_jq" = true ]; then
    printf '%s' "$json" | jq -r --arg key "$key" '.[$key] // empty'
  else
    get_top_level_value_without_jq "$json" "$key"
  fi
}

detect_platform() {
  local os=""
  local arch=""

  case "$(uname -s)" in
    Darwin) os="darwin" ;;
    Linux) os="linux" ;;
    MINGW*|MSYS*|CYGWIN*)
      echo "Windows is not supported by install.sh. Use install.ps1 instead." >&2
      exit 1
      ;;
    *)
      echo "Unsupported operating system: $(uname -s)" >&2
      exit 1
      ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64) arch="amd64" ;;
    arm64|aarch64) arch="arm64" ;;
    *)
      echo "Unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac

  if [ "$os" = "darwin" ] && [ "$arch" = "amd64" ]; then
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || true)" = "1" ]; then
      arch="arm64"
    fi
  fi

  if [ "$os" = "linux" ] && { [ -e /lib/libc.musl-x86_64.so.1 ] || [ -e /lib/libc.musl-aarch64.so.1 ] || ldd /bin/ls 2>&1 | grep -q musl; }; then
    echo "Musl-based Linux distributions are not packaged yet. Please use a glibc-based system or build from source." >&2
    exit 1
  fi

  printf '%s-%s\n' "$os" "$arch"
}

choose_install_dir() {
  if [ -n "${WATASU_INSTALL_DIR:-}" ]; then
    printf '%s\n' "$WATASU_INSTALL_DIR"
    return
  fi

  if [ -n "${XDG_BIN_HOME:-}" ]; then
    printf '%s\n' "$XDG_BIN_HOME"
    return
  fi

  if [ -d "$HOME/.local/bin" ] || [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    printf '%s\n' "$HOME/.local/bin"
    return
  fi

  if [ -d "$HOME/bin" ] || [[ ":$PATH:" == *":$HOME/bin:"* ]]; then
    printf '%s\n' "$HOME/bin"
    return
  fi

  printf '%s\n' "$HOME/.local/bin"
}

checksum_file() {
  local path="$1"

  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | cut -d' ' -f1
  else
    shasum -a 256 "$path" | cut -d' ' -f1
  fi
}

platform="$(detect_platform)"

if [ "$version_input" = "latest" ]; then
  manifest_url="${base_url%/}/latest.json"
else
  if [[ "$version_input" != v* ]]; then
    version_input="v${version_input}"
  fi
  manifest_url="${base_url%/}/manifests/${version_input}.json"
fi

manifest_json="$(download_file "$manifest_url")"

asset_url="$(get_platform_value "$manifest_json" "$platform" "url")"
asset_checksum="$(get_platform_value "$manifest_json" "$platform" "checksum")"
asset_archive="$(get_platform_value "$manifest_json" "$platform" "archive")"
release_version="$(get_top_level_value "$manifest_json" "version")"

if [ -z "$asset_url" ] || [ -z "$asset_checksum" ] || [ -z "$asset_archive" ]; then
  echo "Platform ${platform} is not available in ${manifest_url}" >&2
  exit 1
fi

if [[ ! "$asset_checksum" =~ ^[a-f0-9]{64}$ ]]; then
  echo "Invalid checksum in release manifest" >&2
  exit 1
fi

work_dir="$(mktemp -d)"
archive_path="$work_dir/archive"
install_dir="$(choose_install_dir)"

cleanup() {
  rm -rf "$work_dir"
}

trap cleanup EXIT

download_file "$asset_url" "$archive_path"

actual_checksum="$(checksum_file "$archive_path")"
if [ "$actual_checksum" != "$asset_checksum" ]; then
  echo "Checksum verification failed" >&2
  exit 1
fi

case "$asset_archive" in
  tar.gz)
    tar -xzf "$archive_path" -C "$work_dir"
    ;;
  zip)
    if ! command -v unzip >/dev/null 2>&1; then
      echo "unzip is required to unpack ${asset_archive} archives" >&2
      exit 69
    fi
    unzip -qo "$archive_path" -d "$work_dir"
    ;;
  *)
    echo "Unsupported archive format: ${asset_archive}" >&2
    exit 1
    ;;
esac

binary_path="$(find "$work_dir" -maxdepth 2 -type f -name "$program" | head -n 1)"

if [ -z "$binary_path" ]; then
  echo "Could not find ${program} in the downloaded archive" >&2
  exit 1
fi

mkdir -p "$install_dir"
install -m 0755 "$binary_path" "$install_dir/$program"

echo "Installed ${program} ${release_version:-} to $install_dir/$program"

if [[ ":$PATH:" != *":$install_dir:"* ]]; then
  echo "Add $install_dir to your PATH if it is not already there."
fi
