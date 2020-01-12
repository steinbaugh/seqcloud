#!/bin/sh
# shellcheck disable=SC2039

_koopa_prefix() {                                                         # {{{1
    # """
    # Koopa prefix (home).
    # Updated 2020-01-12.
    # """
    echo "${KOOPA_PREFIX:?}"
}

_koopa_app_prefix() {                                                     # {{{1
    # """
    # Custom application install prefix.
    # Updated 2020-01-12.
    #
    # Inspired by HMS RC devops approach on O2 cluster.
    # """
    local prefix
    if _koopa_is_shared_install
    then
        if _koopa_is_darwin
        then
            # Catalina doesn't allow directory creation at volume root.
            prefix="$(_koopa_make_prefix)"
        else
            # This approach allows us to save apps on a network share.
            # Particularly useful for AWS, Azure, and GCP VMs.
            prefix="/n/app"
        fi
    else
        prefix="${XDG_DATA_HOME:?}"
    fi
    echo "$prefix"
}

_koopa_cellar_prefix() {                                                  # {{{1
    # """
    # Cellar prefix.
    # Updated 2019-11-14.
    #
    # Ensure this points to a local mount (e.g. '/usr/local') instead of our
    # app dir (e.g. '/n/app'), otherwise you can run into login shell activation
    # issues on some virtual machines.
    # """
    echo "$(_koopa_make_prefix)/cellar"
}

_koopa_config_prefix() {                                                  # {{{1
    # """
    # Local koopa config directory.
    # Updated 2020-01-12.
    # """
    echo "${XDG_CONFIG_HOME:?}/koopa"
}

_koopa_make_prefix() {                                                    # {{{1
    # """
    # Return the installation prefix to use.
    # Updated 2020-01-12.
    # """
    local prefix
    if _koopa_is_shared_install && _koopa_has_sudo
    then
        prefix="/usr/local"
    else
        # This is the top-level directory of XDG_DATA_HOME.
        prefix="${HOME:?}/.local"
    fi
    echo "$prefix"
}

_koopa_aspera_prefix() {                                                  # {{{1
    # """
    # Aspera Connect prefix.
    # Updated 2020-01-12.
    # """
    echo "${HOME:?}/.aspera/connect"
}

_koopa_autojump_prefix() {                                                # {{{1
    # """
    # autojump prefix.
    # Updated 2020-01-12.
    # """
    local prefix
    local make_prefix
    make_prefix="$(_koopa_make_prefix)"
    # Shared installation (Linux).
    if [ -x "${make_prefix}/bin/autojump" ]
    then
        # This is the current target of cellar script.
        prefix="$make_prefix"
    elif [ -x "/usr/bin/autojump" ]
    then
        # Also support installation via package manager.
        prefix="/usr"
    else
        # Local user installation (macOS).
        prefix="${HOME:?}/.autojump"
    fi
    echo "$prefix"
}

_koopa_bcbio_prefix() {                                                   # {{{1
    # """
    # bcbio-nextgen prefix.
    # Updated 2020-01-12.
    _koopa_assert_is_linux
    local prefix
    local host_id
    host_id="$(_koopa_host_id)"
    if [ "$host_id" = "harvard-o2" ]
    then
        prefix="/n/app/bcbio/tools"
    elif [ "$host_id" = "harvard-odyssey" ]
    then
        prefix="/n/regal/hsph_bioinfo/bcbio_nextgen"
    else
        prefix="$(_koopa_app_prefix)/bcbio/stable/tools"
    fi
    echo "$prefix"
}

_koopa_conda_prefix() {                                                   # {{{1
    # """
    # Conda prefix
    # Updated 2019-11-21.
    # """
    _koopa_assert_is_installed conda
    conda info --base
}

_koopa_ensembl_perl_api_prefix() {                                        # {{{1
    # """
    # Ensembl Perl API prefix.
    # Updated 2019-11-15.
    local prefix
    prefix="$(_koopa_app_prefix)/ensembl"
    echo "$prefix"
}

_koopa_java_home() {                                                      # {{{1
    # """
    # Java home.
    # Updated 2019-11-16.
    #
    # See also:
    # - https://www.mkyong.com/java/
    #       how-to-set-java_home-environment-variable-on-mac-os-x/
    # - https://stackoverflow.com/questions/22290554
    # """
    _koopa_is_installed java || return 0
    # Early return if environment variable is set.
    if [ -n "${JAVA_HOME:-}" ]
    then
        echo "$JAVA_HOME"
        return 0
    fi
    local home
    if _koopa_is_darwin
    then
        home="$(/usr/libexec/java_home)"
    else
        local java_exe
        java_exe="$(_koopa_which_realpath "java")"
        home="$(dirname "$(dirname "${java_exe}")")"
    fi
    echo "$home"
}

_koopa_perlbrew_prefix() {                                                # {{{1
    # """
    # Perlbrew prefix.
    # Updated 2020-01-11.
    # """
    local prefix
    prefix="$(_koopa_app_prefix)/perl/perlbrew"
    echo "$prefix"
}

_koopa_pyenv_prefix() {                                                   # {{{1
    # """
    # Python pyenv prefix.
    # Updated 2020-01-12.
    #
    # See also approach used for rbenv.
    # """
    local prefix
    # Shared installation (Linux).
    local shared_prefix
    shared_prefix="$(_koopa_app_prefix)/python/pyenv"
    if [ -d "$shared_prefix" ]
    then
        prefix="$shared_prefix"
    else
        # Local user installation (macOS).
        prefix="${XDG_DATA_HOME:?}/pyenv"
    fi
    echo "$prefix"
}

_koopa_r_home() {                                                         # {{{1
    # """
    # Get 'R_HOME', rather than exporting as global variable.
    # Updated 2020-01-12.
    # """
    _koopa_assert_is_installed R Rscript
    local home
    home="$(Rscript --vanilla -e 'cat(Sys.getenv("R_HOME"))')"
    echo "$home"
}

_koopa_rbenv_prefix() {                                                   # {{{1
    # """
    # Ruby rbenv prefix.
    # Updated 2020-01-12.
    #
    # See also:
    # - RBENV_ROOT
    # - https://gist.github.com/saegey/5499096
    # """
    local prefix
    # Shared installation (Linux).
    local shared_prefix
    shared_prefix="$(_koopa_app_prefix)/ruby/rbenv"
    if [ -d "$shared_prefix" ]
    then
        prefix="$shared_prefix"
    else
        # Local user installation (macOS).
        prefix="${XDG_DATA_HOME:?}/rbenv"
    fi
    echo "$prefix"
}

_koopa_rust_cargo_prefix() {                                              # {{{1
    # """
    # Rust cargo install prefix.
    # Updated 2020-01-12.
    #
    # See also:
    # - https://github.com/rust-lang/rustup#environment-variables
    # - CARGO_HOME
    # - RUSTUP_HOME
    # """
    local prefix
    # Shared installation (Linux).
    local shared_prefix
    shared_prefix="$(_koopa_app_prefix)/rust/cargo"
    if [ -d "$shared_prefix" ]
    then
        prefix="$shared_prefix"
    else
        # Local user installation, used on macOS.
        prefix="${HOME:?}/.cargo"
    fi
    echo "$prefix"
}

_koopa_venv_prefix() {                                                    # {{{1
    # """
    # Python venv prefix.
    # Updated 2020-01-12.
    # """
    echo "${XDG_DATA_HOME:?}/virtualenvs"
}
