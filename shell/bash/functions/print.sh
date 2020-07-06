#!/usr/bin/env bash

koopa::coffee_time() { # {{{1
    # """
    # Coffee time.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_no_args "$#"
    koopa::note 'This step takes a while. Time for a coffee break! ☕☕'
    return 0
}

koopa::exit() { # {{{1
    # """
    # Exit showing note, without error.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args_eq "$#" 1
    koopa::note "${1:?}"
    exit 0
}

koopa::install_start() { # {{{1
    # """
    # Inform the user about start of installation.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args "$#"
    local msg name version prefix
    name="${1:?}"
    version=
    prefix=
    if [ "$#" -eq 2 ]
    then
        prefix="${2:?}"
    elif [ "$#" -eq 3 ]
    then
        version="${2:?}"
        prefix="${3:?}"
    elif [ "$#" -ge 4 ]
    then
        koopa::stop "Invalid number of arguments."
    fi
    if [ -n "$prefix" ] && [ -n "$version" ]
    then
        msg="Installing ${name} ${version} at '${prefix}'."
    elif [ -n "$prefix" ]
    then
        msg="Installing ${name} at '${prefix}'."
    else
        msg="Installing ${name}."
    fi
    koopa::h1 "$msg"
    return 0
}

koopa::install_success() { # {{{1
    # """
    # Installation success message.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args_eq "$#" 1
    koopa::success "Installation of ${1:?} was successful."
    return 0
}

koopa::restart() { # {{{1
    # """
    # Inform the user that they should restart shell.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_no_args "$#"
    koopa::note "Restart the shell."
    return 0
}

koopa::status_fail() { # {{{1
    koopa::assert_has_args "$#"
    koopa::_status "FAIL" "red" "$@" >&2
    return 0
}

koopa::status_note() { # {{{1
    koopa::assert_has_args "$#"
    koopa::_status "NOTE" "yellow" "$@"
    return 0
}

koopa::status_ok() { # {{{1
    koopa::assert_has_args "$#"
    koopa::_status "OK" "green" "$@"
    return 0
}

koopa::success() { # {{{1
    # """
    # Success message.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args "$#"
    koopa::_msg "green-bold" "green" "OK" "$@"
    return 0
}

koopa::uninstall_start() { # {{{1
    # """
    # Inform the user about start of uninstall.
    # @note Updated 2020-03-05.
    # """
    local name
    name="${1:?}"
    local prefix
    prefix="${2:-}"
    local msg
    if [ -n "$prefix" ]
    then
        msg="Uninstalling ${name} at '${prefix}'."
    else
        msg="Uninstalling ${name}."
    fi
    koopa::h1 "$msg"
    return 0
}

koopa::uninstall_success() { # {{{1
    # """
    # Uninstall success message.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args_eq "$#" 1
    koopa::success "Uninstallation of ${1:?} was successful."
    return 0
}

koopa::update_start() { # {{{1
    # """
    # Inform the user about start of update.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args "$#"
    local name msg prefix
    name="${1:?}"
    prefix="${2:-}"
    if [ -n "$prefix" ]
    then
        msg="Updating ${name} at '${prefix}'."
    else
        msg="Updating ${name}."
    fi
    koopa::h1 "$msg"
    return 0
}

koopa::update_success() { # {{{1
    # """
    # Update success message.
    # @note Updated 2020-07-01.
    # """
    koopa::assert_has_args_eq "$#" 1
    koopa::success "Update of ${1:?} was successful."
    return 0
}
