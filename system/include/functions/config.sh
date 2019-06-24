#!/bin/sh

# Configuration functions.
# Modified 2019-06-24.



# Using unicode box drawings here.
# Note that we're truncating lines inside the box to 68 characters.
# Modified 2019-06-20.
_koopa_info_box() {
    local array
    local barpad

    array=("$@")
    barpad="$(printf "━%.0s" {1..70})"
    
    printf "\n  %s%s%s  \n"  "┏" "$barpad" "┓"
    for i in "${array[@]}"
    do
        printf "  ┃ %-68s ┃  \n"  "${i::68}"
    done
    printf "  %s%s%s  \n\n"  "┗" "$barpad" "┛"
}



# Get R_HOME, rather than exporting as global variable.
# Modified 2019-06-23.
_koopa_r_home() {
    _koopa_assert_is_installed R
    _koopa_assert_is_installed Rscript
    Rscript --vanilla -e 'cat(Sys.getenv("R_HOME"))'
}



# Update rJava configuration.
# The default Java path differs depending on the system.
#
# > R CMD javareconf -h
#
# Environment variables that can be used to influence the detection:
#   JAVA           path to a Java interpreter executable
#                  By default first 'java' command found on the PATH
#                  is taken (unless JAVA_HOME is also specified).
#   JAVA_HOME      home of the Java environment. If not specified,
#                  it will be detected automatically from the Java
#                  interpreter.
#   JAVAC          path to a Java compiler
#   JAVAH          path to a Java header/stub generator
#   JAR            path to a Java archive tool
#
# Modified 2019-06-24.
_koopa_r_javareconf() {
    _koopa_has_sudo || return 1
    _koopa_is_installed R || return 1
    _koopa_is_installed java || return 1
    
    local java_dir
    local java_flags
    
    if _koopa_is_darwin
    then
        java_dir="/Library/Java/JavaVirtualMachines"
        [ -d "$java_dir" ] || return 1
        java_dir="$(ls -1d "${java_dir}/"* | tail -n 1)"
        [ -d "$java_dir" ] || return 1
        java_dir="${java_dir}/Contents/Home"
        [ -d "$java_dir" ] || return 1
        java_flags=" \
            JAVA_HOME=${java_dir} \
            JAVA=/usr/bin/java \
            JAVAC=/usr/bin/javac \
            JAVAH=/usr/bin/javah \
            JAR=/usr/bin/jar \
        "
    else
        java_dir="/usr/lib/jvm"
        [ -d "$java_dir" ] || return 1
        if [ -d "${java_dir}/java-12-oracle" ]
        then
            # Ubuntu 18: openjdk-12-jdk.
            java_dir="${java_dir}/java-12-oracle"
        elif [ -d "${java_dir}/jre-12-openjdk" ]
        then
            # RHEL7: java-latest-openjdk.
            java_dir="${java_dir}/jre-12-openjdk"
        elif [ -d "${java_dir}/java" ]
        then
            java_dir="${java_dir}/java"
        else
            return 1
        fi
        java_flags=" \
            JAVA_HOME=${java_dir} \
            JAVA=${java_dir}/bin/java \
            JAVAC=${java_dir}/bin/javac \
            JAVAH=${java_dir}/bin/javah \
            JAR=${java_dir}/bin/jar \
        "
    fi
    
    [ -d "$java_dir" ] || return 1
    
    printf "Updating R Java configuration.\n"


    r_home="$(_koopa_r_home)"
    _koopa_build_set_permissions "$r_home"

    (
        unset -v R_HOME
        # shellcheck disable=SC2086
        sudo R --vanilla CMD javareconf $java_flags
        # shellcheck disable=SC2086
        R --vanilla CMD javareconf $java_flags
    )

    # > Rscript -e 'install.packages("rJava")'
}



# Update dynamic linker (LD) configuration.
# Modified 2019-06-23.
_koopa_update_ldconfig() {
    _koopa_is_linux || return 0
    _koopa_has_sudo || return 0
    
    if [ -d /etc/ld.so.conf.d ]
    then
        sudo ln -fs \
            "${KOOPA_HOME}/system/config/etc/ld.so.conf.d/"*".conf" \
            /etc/ld.so.conf.d/.
        sudo ldconfig
    fi
}



# Add shared `koopa.sh` configuration file to `/etc/profile.d/`.
# Modified 2019-06-23.
_koopa_update_profile() {
    _koopa_is_linux || return 0
    _koopa_has_sudo || return 0

    local file
    file="/etc/profile.d/koopa.sh"
    
    printf "Updating '%s'.\n" "$file"
    sudo mkdir -p "$(dirname file)"
    sudo rm -f "$file"
    
    sudo bash -c "cat << EOF > $file
#!/bin/sh

# koopa shell
# https://github.com/acidgenomics/koopa
# shellcheck source=/dev/null
. ${KOOPA_HOME}/activate
EOF"
}



# FIXME Need to add corresponding remove R config script.

# Add shared R configuration symlinks in `${R_HOME}/etc`.
# Modified 2019-06-23.
_koopa_update_r_config() {
    _koopa_has_sudo || return 0
    _koopa_is_installed R || return 0
    
    local r_home
    r_home="$(_koopa_r_home)"

    printf "Updating '%s'.\n" "$r_home"
    sudo ln -fs \
        "${KOOPA_HOME}/system/config/R/etc/"* \
        "${r_home}/etc/".

    if _koopa_is_linux
    then
        printf "Updating '/etc/rstudio/'.\n"
        sudo mkdir -p /etc/rstudio
        sudo ln -fs \
            "${KOOPA_HOME}/system/config/etc/rstudio/"* \
            /etc/rstudio/.
    fi

    _koopa_r_javareconf
}



# Update shell configuration.
# Modified 2019-06-21.
_koopa_update_shells() {
    _koopa_assert_has_sudo
    
    local shell
    shell="$1"
    shell="$(koopa build-prefix)/bin/${shell}"
    
    local shell_file
    shell_file="/etc/shells"
        
    if ! grep -q "$shell" "$shell_file"
    then
        printf "Updating '%s' to include '%s'.\n" "$shell_file" "$shell"
        sudo sh -c "echo ${shell} >> ${shell_file}"
    fi
    
    printf "Run 'chsh -s %s %s' to change default shell.\n" "$shell" "$USER"
}



# Update XDG local configuration.
# ~/.config/koopa
# Modified 2019-06-23.
_koopa_update_xdg_config() {
    local config_dir
    local home_dir
    
    config_dir="$(koopa config-dir)"
    home_dir="$(koopa home)"
    
    mkdir -p "$config_dir"
    
    if [ ! -e "${config_dir}/activate" ]
    then
        rm -f "${config_dir}/activate"
        ln -s "${home_dir}/activate" "${config_dir}/activate"
    fi

    if [ ! -e "${config_dir}/dotfiles" ]
    then
        rm -f "${config_dir}/dotfiles"
        ln -s "${home_dir}/system/config/dotfiles" "${config_dir}/dotfiles"
    fi

    if [ ! -e "${config_dir}/home" ]
    then
        rm -f "${config_dir}/home"
        ln -s "${home_dir}" "${config_dir}/home"
    fi

    if [ ! -e "${config_dir}/R" ]
    then
        rm -f "${config_dir}/R"
        ln -s "${home_dir}/system/config/R" "${config_dir}/R"
    fi
}
