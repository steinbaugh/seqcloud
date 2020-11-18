#!/usr/bin/env bash

koopa::install() { # {{{1
    # """
    # Install commands.
    # @note Updated 2020-11-18.
    # """
    local fun name
    name="${1:-}"
    if [[ -z "$name" ]]
    then
        koopa::stop 'Program name to install is required.'
    fi
    fun="koopa::install_${name//-/_}"
    if ! koopa::is_function "$fun"
    then
        koopa::stop "No install script available for '${name}'."
    fi
    shift 1
    "$fun" "$@"
    return 0
}

koopa::install_py_koopa() { # {{{1
    # """
    # Install Python koopa package.
    # @note Updated 2020-08-12.
    # """
    local url
    url='https://github.com/acidgenomics/koopa/archive/python.tar.gz'
    koopa::pip_install "$@" "$url"
    return 0
}

koopa::install_r_koopa() { # {{{1
    # """
    # Install koopa R package.
    # @note Updated 2020-11-17.
    # """
    local script
    koopa::assert_has_no_args "$#"
    koopa::is_installed Rscript || return 0
    script="$(koopa::rscript_prefix)/install.R"
    koopa::assert_is_file "$script"
    Rscript "$script"
    return 0
}