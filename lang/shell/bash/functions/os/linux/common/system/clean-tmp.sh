#!/usr/bin/env bash

koopa::linux_clean_tmp() { # {{{1
    # """
    # Clean temporary directory.
    # @note Updated 2021-05-21.
    # """
    local dir dirs find matches
    koopa::assert_has_no_args "$#"
    koopa::assert_has_sudo
    find="$(koopa::locate_find)"
    dirs=('/tmp')
    if [[ "${TMPDIR:-}" != '/tmp' ]]
    then
        dirs+=("$TMPDIR")
    fi
    for dir in "${dirs[@]}"
    do
        readarray -t matches <<< "$( \
        sudo "$find" "$dir" \
            -mindepth 1 \
            -maxdepth 1 \
            -ctime +30 \
            -print \
        )"
        koopa::rm -S "${matches[@]}"
    done
    return 0
}
