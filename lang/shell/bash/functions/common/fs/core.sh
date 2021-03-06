#!/usr/bin/env bash

koopa::cd() { # {{{1
    # """
    # Change directory quietly.
    # @note Updated 2021-05-26.
    # """
    local prefix
    koopa::assert_has_args_eq "$#" 1
    prefix="${1:?}"
    cd "$prefix" >/dev/null 2>&1 || return 1
    return 0
}

koopa::chgrp() { # {{{1
    # """
    # GNU chgrp.
    # @note Updated 2021-05-25.
    # """
    local chgrp pos sudo which_chgrp
    sudo=0
    pos=()
    while (("$#"))
    do
        case "$1" in
            -S)
                sudo=1
                shift 1
                ;;
            *)
                pos+=("$1")
                shift 1
                ;;
        esac
    done
    [[ "${#pos[@]}" -gt 0 ]] && set -- "${pos[@]}"
    koopa::assert_has_args "$#"
    which_chgrp="$(koopa::locate_chgrp)"
    if [[ "$sudo" -eq 1 ]]
    then
        chgrp=('sudo' "$which_chgrp")
    else
        chgrp=("$which_chgrp")
    fi
    "${chgrp[@]}" "$@"
    return 0
}

koopa::chmod() { # {{{1
    # """
    # GNU chmod.
    # @note Updated 2021-05-21.
    # """
    local chmod pos sudo which_chmod
    sudo=0
    pos=()
    while (("$#"))
    do
        case "$1" in
            -S)
                sudo=1
                shift 1
                ;;
            *)
                pos+=("$1")
                shift 1
                ;;
        esac
    done
    [[ "${#pos[@]}" -gt 0 ]] && set -- "${pos[@]}"
    koopa::assert_has_args "$#"
    which_chmod="$(koopa::locate_chmod)"
    if [[ "$sudo" -eq 1 ]]
    then
        chmod=('sudo' "$which_chmod")
    else
        chmod=("$which_chmod")
    fi
    "${chmod[@]}" "$@"
    return 0
}

koopa::chown() { # {{{1
    # """
    # GNU chown.
    # @note Updated 2021-05-21.
    # """
    local chown pos sudo which_chown
    sudo=0
    pos=()
    while (("$#"))
    do
        case "$1" in
            -S)
                sudo=1
                shift 1
                ;;
            *)
                pos+=("$1")
                shift 1
                ;;
        esac
    done
    [[ "${#pos[@]}" -gt 0 ]] && set -- "${pos[@]}"
    koopa::assert_has_args "$#"
    which_chown="$(koopa::locate_chown)"
    if [[ "$sudo" -eq 1 ]]
    then
        chown=('sudo' "$which_chown")
    else
        chown=("$which_chown")
    fi
    "${chown[@]}" "$@"
    return 0
}

koopa::cp() { # {{{1
    # """
    # Hardened version of GNU coreutils copy.
    # @note Updated 2021-05-22.
    #
    # getopts info:
    # - http://mywiki.wooledge.org/BashFAQ/035#getopts
    # - https://wiki.bash-hackers.org/howto/getopts_tutorial
    # """
    local OPTIND cp cp_args mkdir rm sudo symlink target_dir
    local target_parent which_cp
    sudo=0
    symlink=0
    target_dir=''
    OPTIND=1
    while getopts 'Sst:' opt
    do
        case "$opt" in
            S)
                sudo=1
                ;;
            s)
                symlink=1
                ;;
            t)
                target_dir="$OPTARG"
                ;;
            \?)
                koopa::invalid_arg
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    koopa::assert_has_args "$#"
    which_cp="$(koopa::locate_cp)"
    if [[ "$sudo" -eq 1 ]]
    then
        # NOTE Don't run sudo check here, can slow down functions.
        cp=('sudo' "$which_cp")
        mkdir=('koopa::mkdir' '-S')
        rm=('koopa::rm' '-S')
    else
        cp=("$which_cp")
        mkdir=('koopa::mkdir')
        rm=('koopa::rm')
    fi
    cp_args=('-af')
    [[ "$symlink" -eq 1 ]] && cp_args+=('-s')
    if [[ -n "$target_dir" ]]
    then
        koopa::assert_is_existing "$@"
        target_dir="$(koopa::strip_trailing_slash "$target_dir")"
        cp_args+=('-t' "$target_dir")
        [[ -d "$target_dir" ]] || "${mkdir[@]}" "$target_dir"
    else
        koopa::assert_has_args_eq "$#" 2
        source_file="${1:?}"
        koopa::assert_is_existing "$source_file"
        target_file="${2:?}"
        [[ -e "$target_file" ]] && "${rm[@]}" "$target_file"
        target_parent="$(dirname "$target_file")"
        [[ -d "$target_parent" ]] || "${mkdir[@]}" "$target_parent"
    fi
    "${cp[@]}" "${cp_args[@]}" "$@"
    return 0
}

koopa::df() { # {{{1
    # """
    # Human friendlier version of GNU df.
    # @note Updated 2021-05-21.
    # """
    local df
    df="$(koopa::locate_df)"
    "$df" \
        --portability \
        --print-type \
        --si \
        "$@"
    return 0
}

koopa::ln() { # {{{1
    # """
    # Create a symlink quietly with GNU ln.
    # @note Updated 2021-05-222.
    # """
    local OPTIND ln ln_args mkdir rm source_file target_file target_dir
    local target_parent which_ln
    sudo=0
    target_dir=''
    OPTIND=1
    while getopts 'St:' opt
    do
        case "$opt" in
            S)
                sudo=1
                ;;
            t)
                target_dir="$OPTARG"
                ;;
            \?)
                koopa::invalid_arg
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    koopa::assert_has_args "$#"
    which_ln="$(koopa::locate_ln)"
    if [[ "$sudo" -eq 1 ]]
    then
        # NOTE Don't run sudo check here, can slow down functions.
        ln=('sudo' "$which_ln")
        mkdir=('koopa::mkdir' '-S')
        rm=('koopa::rm' '-S')
    else
        ln=("$which_ln")
        mkdir=('koopa::mkdir')
        rm=('koopa::rm')
    fi
    ln_args=('-fns')
    if [[ -n "$target_dir" ]]
    then
        koopa::assert_is_existing "$@"
        target_dir="$(koopa::strip_trailing_slash "$target_dir")"
        ln_args+=('-t' "$target_dir")
        [[ -d "$target_dir" ]] || "${mkdir[@]}" "$target_dir"
    else
        koopa::assert_has_args_eq "$#" 2
        source_file="${1:?}"
        koopa::assert_is_existing "$source_file"
        target_file="${2:?}"
        [[ -e "$target_file" ]] && "${rm[@]}" "$target_file"
        target_parent="$(dirname "$target_file")"
        [[ -d "$target_parent" ]] || "${mkdir[@]}" "$target_parent"
    fi
    "${ln[@]}" "${ln_args[@]}" "$@"
    return 0
}

koopa::mkdir() { # {{{1
    # """
    # Create directories with parents automatically.
    # @note Updated 2021-05-21.
    local OPTIND mkdir sudo which_mkdir
    sudo=0
    OPTIND=1
    while getopts 'S' opt
    do
        case "$opt" in
            S)
                sudo=1
                ;;
            \?)
                koopa::invalid_arg
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    koopa::assert_has_args "$#"
    which_mkdir="$(koopa::locate_mkdir)"
    if [[ "$sudo" -eq 1 ]]
    then
        # NOTE Don't run sudo check here, can slow down functions.
        mkdir=('sudo' "$which_mkdir")
    else
        mkdir=("$which_mkdir")
    fi
    "${mkdir[@]}" -p "$@"
    return 0
}

koopa::mv() { # {{{1
    # """
    # Move a file or directory with GNU mv.
    # @note Updated 2021-05-22.
    #
    # This function works on 1 file or directory at a time.
    # It ensures that the target parent directory exists automatically.
    #
    # Useful GNU mv args, for reference (non-POSIX):
    # - -T: no-target-directory
    # - --strip-trailing-slashes
    # """
    local OPTIND mkdir mv mv_args rm source_file sudo target_file
    local target_parent which_mv
    sudo=0
    target_dir=''
    OPTIND=1
    while getopts 'St:' opt
    do
        case "$opt" in
            S)
                sudo=1
                ;;
            t)
                target_dir="$OPTARG"
                ;;
            \?)
                koopa::invalid_arg
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    koopa::assert_has_args "$#"
    which_mv="$(koopa::locate_mv)"
    if [[ "$sudo" -eq 1 ]]
    then
        # NOTE Don't run sudo check here, can slow down functions.
        mkdir=('koopa::mkdir' '-S')
        mv=('sudo' "$which_mv")
        rm=('koopa::rm' '-S')
    else
        mkdir=('koopa::mkdir')
        mv=("$which_mv")
        rm=('koopa::rm')
    fi
    mv_args=('-f')
    if [[ -n "$target_dir" ]]
    then
        koopa::assert_is_existing "$@"
        target_dir="$(koopa::strip_trailing_slash "$target_dir")"
        mv_args+=('-t' "$target_dir")
        [[ -d "$target_dir" ]] || "${mkdir[@]}" "$target_dir"
    else
        koopa::assert_has_args_eq "$#" 2
        source_file="$(koopa::strip_trailing_slash "${1:?}")"
        koopa::assert_is_existing "$source_file"
        target_file="$(koopa::strip_trailing_slash "${2:?}")"
        [[ -e "$target_file" ]] && "${rm[@]}" "$target_file"
        target_parent="$(dirname "$target_file")"
        [[ -d "$target_parent" ]] || "${mkdir[@]}" "$target_parent"
    fi
    "${mv[@]}" "${mv_args[@]}" "$@"
    return 0
}

koopa::parent_dir() { # {{{1
    # """
    # Get the parent directory path.
    # @note Updated 2021-05-26.
    #
    # This requires file to exist and resolves symlinks.
    # """
    local OPTIND cd_tail file n parent sed 
    sed="$(koopa::locate_sed)"
    cd_tail=''
    n=1
    OPTIND=1
    while getopts 'n:' opt
    do
        case "$opt" in
            n)
                n="${OPTARG}"
                ;;
            \?)
                koopa::invalid_arg "$opt"
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    [[ "$n" -ge 1 ]] || n=1
    if [[ "$n" -ge 2 ]]
    then
        n="$((n-1))"
        cd_tail="$( \
            printf "%${n}s" \
            | "$sed" 's| |/..|g' \
        )"
    fi
    for file in "$@"
    do
        [[ -e "$file" ]] || return 1
        parent="$(koopa::dirname "$file")"
        parent="${parent}${cd_tail}"
        parent="$(koopa::cd "$parent" && pwd -P)"
        koopa::print "$parent"
    done
    return 0
}

koopa::relink() { # {{{1
    # """
    # Re-create a symbolic link dynamically, if broken.
    # @note Updated 2020-07-07.
    # """
    local OPTIND dest_file ln rm source_file sudo
    sudo=0
    OPTIND=1
    while getopts 'S' opt
    do
        case "$opt" in
            S)
                sudo=1
                ;;
            \?)
                koopa::invalid_arg
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    koopa::assert_has_args_eq "$#" 2
    if [[ "$sudo" -eq 1 ]]
    then
        ln=('koopa::ln' '-S')
        rm=('koopa::rm' '-S')
    else
        ln=('koopa::ln')
        rm=('koopa::rm')
    fi
    source_file="${1:?}"
    dest_file="${2:?}"
    # Keep this check relaxed, in case dotfiles haven't been cloned.
    [[ -e "$source_file" ]] || return 0
    [[ -L "$dest_file" ]] && return 0
    "${rm[@]}" "$dest_file"
    "${ln[@]}" "$source_file" "$dest_file"
    return 0
}

koopa::rm() { # {{{1
    # """
    # Remove files/directories quietly with GNU rm.
    # @note Updated 2021-05-21.
    # """
    local OPTIND rm sudo which_rm
    sudo=0
    OPTIND=1
    while getopts 'S' opt
    do
        case "$opt" in
            S)
                sudo=1
                ;;
            \?)
                koopa::invalid_arg
                ;;
        esac
    done
    shift "$((OPTIND-1))"
    koopa::assert_has_args "$#"
    which_rm="$(koopa::locate_rm)"
    if [[ "$sudo" -eq 1 ]]
    then
        # NOTE Don't run sudo check here, can slow down functions.
        rm=('sudo' "$which_rm")
    else
        rm=("$which_rm")
    fi
    "${rm[@]}" -fr "$@"
    return 0
}

koopa::which() { # {{{1
    # """
    # Locate which program.
    # @note Updated 2021-05-26.
    #
    # Example:
    # koopa::which bash
    # """
    local cmd
    koopa::assert_has_args "$#"
    for cmd in "$@"
    do
        if koopa::is_alias "$cmd"
        then
            unalias "$cmd"
        elif koopa::is_function "$cmd"
        then
            unset -f "$cmd"
        fi
        cmd="$(command -v "$cmd")"
        [[ -x "$cmd" ]] || return 1
        koopa::print "$cmd"
    done
    return 0
}

koopa::which_realpath() { # {{{1
    # """
    # Locate the realpath of a program.
    # @note Updated 2021-06-03.
    #
    # This resolves symlinks automatically.
    # For 'which' style return, use 'koopa::which' instead.
    #
    # @seealso
    # - https://stackoverflow.com/questions/7665
    # - https://unix.stackexchange.com/questions/85249
    # - https://stackoverflow.com/questions/7522712
    # - https://thoughtbot.com/blog/input-output-redirection-in-the-shell
    #
    # @examples
    # koopa::which_realpath bash vim
    # """
    local cmd
    koopa::assert_has_args "$#"
    for cmd in "$@"
    do
        cmd="$(koopa::which "$cmd")"
        [[ -n "$cmd" ]] || return 1
        cmd="$(koopa::realpath "$cmd")"
        [[ -x "$cmd" ]] || return 1
        koopa::print "$cmd"
    done
    return 0
}
