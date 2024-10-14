#!/usr/bin/env bash

set -euo pipefail

readonly SRC_DIR="emacs-src"

if [[ ! -d "${SRC_DIR}/.git" ]]; then
  git clone --filter=blob:none https://github.com/emacs-mirror/emacs.git "$SRC_DIR"
  echo -e "\nCompleted cloning Emacs source\n"
fi

cd "$SRC_DIR"

if type emacs >/dev/null 2>&1; then
  current_version=$(emacs --version | head -n1 | cut -d' ' -f3)
  current_tag="emacs-${current_version}"
  git switch -d "$current_tag"

  # Uninstall current Emacs
  echo -n "Emacs ${current_version} is already installed, Uninstall? (y/N): "
  read -r yn
  case "$yn" in
    [yY]* )
      make uninstall
      echo -e "\nCurrent Emacs has been uninstalled\n"
      ;;
    * )
      echo "abort"
      exit 0
      ;;
  esac
  hash -r
fi

# Get total cores
if grep core.id /proc/cpuinfo >/dev/null 2>&1; then
  jobs=$(grep core.id /proc/cpuinfo | sort -u | wc -l)
elif type sysctl >/dev/null 2>&1; then
  jobs=$(sysctl -n hw.physicalcpu_max)
else
  echo "Unable to get CPU core count" >&2
  exit 1
fi

# Checkout latest stable version or argument version
git fetch --tags
latest_version=$(git tag -l 'emacs-[0-9]*' --sort=-v:refname | grep -E 'emacs-[0-9]+\.[0-9]+$' | head -n1)
if [[ -n "${1:-}" ]]; then
  ver="emacs-${1}"
else
  ver=$latest_version
fi
git switch -d "$ver"

echo -e "\n=== Starting Emacs build ===\n"
./autogen.sh
./configure --prefix "${HOME}/.local" --with-imagemagick --with-tree-sitter --with-xwidgets --with-native-compilation
make -j"$jobs"
make install

echo -e "\nSuccessfully installed Emacs"
