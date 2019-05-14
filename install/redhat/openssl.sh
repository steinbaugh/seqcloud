#!/usr/bin/env bash
set -Eeuxo pipefail

# OpenSSL
# https://www.openssl.org/source/

build_dir="/tmp/build/openssl"
prefix="/usr/local"
version="1.1.1b"

echo "Installing openssl ${version}."

# Run preflight initialization checks.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
. "${script_dir}/_init.sh"

# Install build dependencies.
sudo yum-builddep -y openssl

# SC2103: Use a ( subshell ) to avoid having to cd back.
(
    rm -rf "$build_dir"
    mkdir -p "$build_dir"
    cd "$build_dir" || exit 1
    curl -O "https://www.openssl.org/source/openssl-${version}.tar.gz"
    tar -xvzf "openssl-${version}.tar.gz"
    cd "openssl-${version}" || exit 1
    ./config --prefix="$prefix"
    make
    make test
    sudo make install
    rm -rf "$build_dir"
)

# Ensure ldconfig is current.
sudo ldconfig

echo "Reloading current shell."
exec bash

echo "openssl installed successfully."
command -v openssl
openssl version
