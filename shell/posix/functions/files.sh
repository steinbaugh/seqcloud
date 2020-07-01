#!/bin/sh
# shellcheck disable=SC2039

_koopa_basename() { # {{{1
    # """
    # Extract the file basename.
    # @note Updated 2020-06-30.
    #
    # Parameterized, supporting multiple basename extractions.
    # """
    [ "$#" -gt 0 ] || return 1
    if _koopa_is_installed basename
    then
        _koopa_print "$(basename -a "$@")"
    else
        local arg
        for arg in "$@"
        do
            _koopa_print "${arg##*/}"
        done
    fi
    return 0
}

_koopa_basename_sans_ext() { # {{{1
    # """
    # Extract the file basename without extension.
    # @note Updated 2020-06-30.
    #
    # Examples:
    # _koopa_basename_sans_ext "dir/hello-world.txt"
    # ## hello-world
    #
    # _koopa_basename_sans_ext "dir/hello-world.tar.gz"
    # ## hello-world.tar
    #
    # See also: _koopa_file_ext
    # """
    [ "$#" -gt 0 ] || return 1
    local file str
    for file in "$@"
    do
        str="$(_koopa_basename "$file")"
        if _koopa_has_file_ext "$str"
        then
            str="${str%.*}"
        fi
        _koopa_print "$str"
    done
    return 0
}

_koopa_basename_sans_ext2() { # {{{1
    # """
    # Extract the file basename prior to any dots in file name.
    # @note Updated 2020-06-30.
    #
    # Examples:
    # _koopa_basename_sans_ext2 "dir/hello-world.tar.gz"
    # ## hello-world
    #
    # See also: _koopa_file_ext2
    # """
    [ "$#" -gt 0 ] || return 1
    local file str
    for file in "$@"
    do
        str="$(_koopa_basename "$file")"
        if _koopa_has_file_ext "$str"
        then
            str="$(_koopa_print "$str" | cut -d '.' -f 1)"
        fi
        _koopa_print "$str"
    done
    return 0
}

_koopa_ensure_newline_at_end_of_file() { # {{{1
    # """
    # Ensure output CSV contains trailing line break.
    # @note Updated 2020-07-01.
    #
    # Otherwise 'readr::read_csv()' will skip the last line in R.
    # https://unix.stackexchange.com/questions/31947
    #
    # Slower alternatives:
    # vi -ecwq file
    # paste file 1<> file
    # ed -s file <<< w
    # sed -i -e '$a\' file
    # """
    [ "$#" -eq 1 ] || return 1
    local file
    file="${1:?}"
    [ -n "$(tail -c1 "$file")" ] && printf '\n' >>"$file"
    return 0
}

_koopa_file_ext() { # {{{1
    # """
    # Extract the file extension from input.
    # @note Updated 2020-04-27.
    #
    # Examples:
    # _koopa_file_ext "hello-world.txt"
    # ## txt
    #
    # _koopa_file_ext "hello-world.tar.gz"
    # ## gz
    #
    # See also: _koopa_basename_sans_ext
    # """
    [ "$#" -gt 0 ] || return 1
    local file x
    for file in "$@"
    do
        if _koopa_has_file_ext "$file"
        then
            x="${file##*.}"
        else
            x=""
        fi
        _koopa_print "$x"
    done
    return 0
}

_koopa_file_ext2() { # {{{1
    # """
    # Extract the file extension after any dots in the file name.
    # @note Updated 2020-06-30.
    #
    # This assumes file names are not in dotted case.
    #
    # Examples:
    # _koopa_file_ext2 "hello-world.tar.gz"
    # ## tar.gz
    #
    # See also: _koopa_basename_sans_ext2
    # """
    [ "$#" -gt 0 ] || return 1
    local file x
    for file in "$@"
    do
        if _koopa_has_file_ext "$file"
        then
            x="$(_koopa_print "$file" | cut -d '.' -f 2-)"
        else
            x=""
        fi
        _koopa_print "$x"
    done
    return 0
}

_koopa_find_broken_symlinks() { # {{{1
    # """
    # Find broken symlinks.
    # @note Updated 2020-07-01.
    #
    # Note that 'grep -v' is more compatible with macOS and BusyBox than use of
    # 'grep --invert-match'.
    # """
    [ "$#" -le 1 ] || return 1
    _koopa_is_installed find grep || return 1
    local dir
    dir="${1:-"."}"
    [ -d "$dir" ] || return 0
    dir="$(realpath "$dir")"
    local x
    x="$( \
        find "$dir" \
            -xdev \
            -mindepth 1 \
            -xtype l \
            -print \
            2>&1 \
            | grep -v "Permission denied" \
            | sort \
    )"
    _koopa_print "$x"
    return 0
}

_koopa_find_dotfiles() { # {{{1
    # """
    # Find dotfiles by type.
    # @note Updated 2020-07-01.
    #
    # This is used internally by 'list-dotfiles' script.
    #
    # 1. Type ('f' file; or 'd' directory).
    # 2. Header message (e.g. "Files")
    # """
    [ "$#" -eq 2 ] || return 1
    _koopa_is_installed awk find || return 1
    local header type x
    type="${1:?}"
    header="${2:?}"
    x="$( \
        find "$HOME" \
            -mindepth 1 \
            -maxdepth 1 \
            -name ".*" \
            -type "$type" \
            -print0 \
            | xargs -0 -n1 basename \
            | sort \
            | awk '{print "  ",$0}' \
    )"
    _koopa_print "\n%s:\n\n" "$header"
    _koopa_print "$x"
    return 0
}

_koopa_find_empty_dirs() { # {{{1
    # """
    # Find empty directories.
    # @note Updated 2020-07-01.
    # """
    [ "$#" -le 1 ] || return 1
    _koopa_is_installed find grep || return 1
    local dir x
    dir="${1:-"."}"
    dir="$(realpath "$dir")"
    x="$( \
        find "$dir" \
            -xdev \
            -mindepth 1 \
            -type d \
            -not -path "*/.*/*" \
            -empty \
            -print \
            2>&1 \
            | grep -v "Permission denied" \
            | sort \
    )"
    _koopa_print "$x"
    return 0
}

_koopa_find_large_dirs() { # {{{1
    # """
    # Find large directories.
    # @note Updated 2020-07-01.
    # """
    [ "$#" -le 1 ] || return 1
    _koopa_is_installed du || return 1
    local dir x
    dir="${1:-"."}"
    dir="$(realpath "$dir")"
    x="$( \
        du \
            --max-depth=20 \
            --threshold=100000000 \
            "${dir}"/* \
            2>/dev/null \
        | sort -n \
        | head -n 100 \
        || true \
    )"
    _koopa_print "$x"
    return 0
}

_koopa_find_large_files() { # {{{1
    # """
    # Find large files.
    # @note Updated 2020-07-01.
    #
    # Note that use of 'grep --null-data' requires GNU grep.
    #
    # Usage of '-size +100M' isn't POSIX.
    #
    # @seealso
    # https://unix.stackexchange.com/questions/140367/
    # """
    [ "$#" -le 1 ] || return 1
    _koopa_is_installed find grep || return 1
    local dir x
    dir="${1:-"."}"
    dir="$(realpath "$dir")"
    x="$( \
        find "$dir" \
            -xdev \
            -mindepth 1 \
            -type f \
            -size +100000000c \
            -print0 \
            2>&1 \
            | grep \
                --null-data \
                --invert-match "Permission denied" \
            | xargs -0 du \
            | sort -n \
            | tail -n 100 \
    )"
    _koopa_print "$x"
    return 0
}

_koopa_find_non_cellar_make_files() { # {{{1
    # """
    # Find non-cellar make files.
    # @note Updated 2020-06-30.
    #
    # Standard directories: bin, etc, include, lib, lib64, libexec, man, sbin,
    # share, src.
    # """
    [ "$#" -eq 0 ] || return 1
    _koopa_assert_is_installed find || return 1
    local prefix x
    prefix="$(_koopa_make_prefix)"
    x="$( \
        find "$prefix" \
            -xdev \
            -mindepth 1 \
            -type f \
            -not -path "${prefix}/cellar/*" \
            -not -path "${prefix}/koopa/*" \
            -not -path "${prefix}/opt/*" \
            -not -path "${prefix}/share/applications/mimeinfo.cache" \
            -not -path "${prefix}/share/emacs/site-lisp/*" \
            -not -path "${prefix}/share/zsh/site-functions/*" \
            | sort \
    )"
    _koopa_print "$x"
    return 0
}

_koopa_line_count() { # {{{1
    # """
    # Return the number of lines in a file.
    # @note Updated 2020-06-30.
    #
    # Example: _koopa_line_count tx2gene.csv
    # """
    [ "$#" -gt 0 ] || return 1
    local file x
    for file in "$@"
    do
        x="$( \
            wc -l "$file" \
                | xargs \
                | cut -d ' ' -f 1 \
        )"
        _koopa_print "$x"
    done    
    return 0
}

_koopa_realpath() { # {{{1
    # """
    # Real path to file/directory on disk.
    # @note Updated 2020-06-30.
    #
    # Note that 'readlink -f' doesn't work on macOS.
    #
    # @seealso
    # - https://github.com/bcbio/bcbio-nextgen/blob/master/tests/run_tests.sh
    # """
    [ "$#" -gt 0 ] || return 1
    local arg x
    if _koopa_is_installed realpath
    then
        x="$(realpath "$@")"
        _koopa_print "$x"
    elif _koopa_has_gnu readlink
    then
        x="$(readlink -f "$@")"
        _koopa_print "$x"
    elif _koopa_is_installed perl
    then
        for arg in "$@"
        do
            x="$(perl -MCwd -e 'print Cwd::abs_path shift' "$arg")"
            _koopa_print "$x"
        done
    else
        return 1
    fi
    return 0
}

_koopa_stat_access_human() { # {{{1
    # """
    # Get the current access permissions in human readable form.
    # @note Updated 2020-06-30.
    # """
    [ "$#" -gt 0 ] || return 1
    local x
    x="$(stat -c '%A' "$@")"
    _koopa_print "$x"
    return 0
}

_koopa_stat_access_octal() { # {{{1
    # """
    # Get the current access permissions in octal form.
    # @note Updated 2020-06-30.
    # """
    [ "$#" -gt 0 ] || return 1
    local x
    x="$(stat -c '%a' "$@")"
    _koopa_print "$x"
    return 0
}

_koopa_stat_dereference() { # {{{1
    # """
    # Dereference input files.
    # @note Updated 2020-06-30.
    #
    # Return quoted file with dereference if symbolic link.
    # """
    [ "$#" -gt 0 ] || return 1
    local x
    x="$(stat --printf='%N\n' "$@")"
    _koopa_print "$x"
    return 0
}

_koopa_stat_group() { # {{{1
    # """
    # Get the current group of a file or directory.
    # @note Updated 2020-06-30.
    # """
    [ "$#" -gt 0 ] || return 1
    local x
    x="$(stat -c '%G' "$@")"
    _koopa_print "$x"
    return 0
}

_koopa_stat_modified() {
    # """
    # Get file modification time.
    # @note Updated 2020-03-06.
    #
    # Linux uses GNU coreutils variant.
    # macOS uses BSD variant.
    #
    # Both approaches return seconds since Unix epoch with 'stat' and then
    # pass to 'date' with flags for expected epoch seconds input. Note that
    # '@' usage in date for Linux requires coreutils 5.3.0+.
    #
    # _koopa_stat_modified 'file.pdf' '%Y-%m-%d'
    # """
    [ "$#" -eq 2 ] || return 1
    local file format x
    file="${1:?}"
    format="${2:?}"
    if _koopa_is_macos
    then
        x="$(/usr/bin/stat -f '%m' "$file")"
        # Convert seconds since Epoch into a useful format.
        x="$(/bin/date -j -f '%s' "$x" +"$format")"
    else
        x="$(stat -c '%Y' "$file")"
        # Convert seconds since Epoch into a useful format.
        # https://www.gnu.org/software/coreutils/manual/html_node/
        #     Examples-of-date.html
        x="$(date -d "@${x}" +"$format")"
    fi
    _koopa_print "$x"
    return 0
}

_koopa_stat_user() { # {{{1
    # """
    # Get the current user (owner) of a file or directory.
    # @note Updated 2020-06-30.
    # """
    [ "$#" -gt 0 ] || return 1
    local x
    x="$(stat -c '%U' "$@")"
    _koopa_print "$x"
    return 0
}

_koopa_sudo_write_string() { # {{{1
    # """
    # Write a string to disk using root user.
    # @note Updated 2020-07-01.
    #
    # Alternatively, 'tee -a' can be used to append file.
    # """
    [ "$#" -eq 2 ] || return 1
    local file string
    string="${1:?}"
    file="${2:?}"
    _koopa_print "$string" | sudo tee "$file" >/dev/null
    return 0
}
