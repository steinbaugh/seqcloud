#!/usr/bin/env bash

# FIXME Installer now isn't working on macOS...
# FIXME How to activate Go packages?

# NOTE Seeing this pop up on macOS.
# # tar: Ignoring unknown extended header keyword

koopa::install_go() { # {{{1
    koopa::install_app \
        --name='go' \
        --name-fancy='Go' \
        "$@"
}

koopa:::install_go() { # {{{1
    # """
    # Install Go.
    # @note Updated 2021-05-19.
    # """
    local arch file name os_id prefix url version
    prefix="${INSTALL_PREFIX:?}"
    version="${INSTALL_VERSION:?}"
    name='go'
    # e.g. 'amd64' for x86.
    arch="$(koopa::arch2)"
    if koopa::is_macos
    then
        os_id='darwin'
    else
        os_id='linux'
    fi
    file="${name}${version}.${os_id}-${arch}.tar.gz"
    url="https://dl.google.com/${name}/${file}"
    koopa::download "$url"
    koopa::extract "$file"
    # FIXME This step is failing because we need to rethink coreutils...
    koopa::cp -t "$prefix" "${name}/"*
    return 0
}
