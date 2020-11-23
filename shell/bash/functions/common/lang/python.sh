#!/usr/bin/env bash

koopa::activate_conda_env() { # {{{1
    # """
    # Activate a conda environment.
    # @note Updated 2020-11-09.
    #
    # Designed to work inside calling scripts and/or subshells.
    #
    # Currently, the conda activation script returns a 'conda()' function in
    # the current shell that doesn't propagate to subshells. This function
    # attempts to rectify the current situation.
    #
    # Note that the conda activation script currently has unbound variables
    # (e.g. PS1), that will cause this step to fail unless we temporarily
    # disable unbound variable checks.
    #
    # Alternate approach:
    # > eval "$(conda shell.bash hook)"
    #
    # See also:
    # - https://github.com/conda/conda/issues/7980
    # - https://stackoverflow.com/questions/34534513
    # """
    local conda_prefix env env_dir nounset
    koopa::assert_has_args_eq "$#" 1
    env="${1:?}"
    conda_prefix="$(koopa::conda_prefix)"
    # Locate latest version automatically, if necessary.
    if ! koopa::str_match "$env" '@'
    then
        koopa::assert_is_installed find
        env_dir="$( \
            find "${conda_prefix}/envs" \
                -mindepth 1 \
                -maxdepth 1 \
                -type d \
                -name "${env}@*" \
                -print \
            | sort \
            | tail -n 1 \
        )"
        if [[ ! -d "$env_dir" ]]
        then
            koopa::stop "Failed to locate '${env}' conda environment."
        fi
        env="$(basename "$env_dir")"
    fi
    nounset="$(koopa::boolean_nounset)"
    [[ "$nounset" -eq 1 ]] && set +u
    if ! type conda | grep -q conda.sh
    then
        # shellcheck source=/dev/null
        . "${conda_prefix}/etc/profile.d/conda.sh"
    fi
    conda activate "$env"
    [[ "$nounset" -eq 1 ]] && set -u
    return 0
}

koopa::conda_create_bioinfo_envs() { # {{{1
    # """
    # Create Conda bioinformatics environments.
    # @note Updated 2020-10-27.
    # """
    local all aligners chipseq data_mining env envs file_formats methylation \
        quality_control reticulate rnaseq trimming variation version workflows
    koopa::assert_is_installed conda
    all=0
    aligners=0
    chipseq=0
    data_mining=0
    file_formats=0
    methylation=0
    quality_control=0
    reticulate=0
    rnaseq=0
    trimming=0
    variation=0
    workflows=0
    # Set recommended defaults, if necessary.
    if [[ "$#" -eq 0 ]]
    then
        aligners=1
        chipseq=1
        data_mining=1
        file_formats=1
        reticulate=1
        rnaseq=1
        workflows=1
    fi
    while (("$#"))
    do
        case "$1" in
            --all)
                all=1
                shift 1
                ;;
            --aligners)
                aligners=1
                shift 1
                ;;
            --chipseq|--chip-seq)
                chipseq=1
                shift 1
                ;;
            --data-mining)
                data_mining=1
                shift 1
                ;;
            --file-formats)
                file_formats=1
                shift 1
                ;;
            --methylation)
                methylation=1
                shift 1
                ;;
            --qc|quality-control)
                quality_control=1
                shift 1
                ;;
            --reticulate)
                reticulate=1
                shift 1
                ;;
            --rnaseq|--rna-seq)
                rnaseq=1
                shift 1
                ;;
            --trimming)
                trimming=1
                shift 1
                ;;
            --variation)
                variation=1
                shift 1
                ;;
            --workflows)
                workflows=1
                shift 1
                ;;
            *)
                koopa::invalid_arg "$1"
                ;;
        esac
    done
    koopa::h1 'Installing conda environments for bioinformatics.'
    envs=()
    if [[ "$all" -eq 1 ]]
    then
        aligners=1
        chipseq=1
        data_mining=1
        file_formats=1
        methylation=1
        quality_control=1
        rnaseq=1
        reticulate=1
        trimming=1
        variation=1
        workflows=1
        envs+=('igvtools')
    fi
    if [[ "$aligners" -eq 1 ]]
    then
        # Consider: minimap2, novoalign
        envs+=(
            'bowtie2'
            'bwa'
            'hisat2'
            'rsem'
            'star'
        )
        if koopa::is_linux
        then
            envs+=('bwa-mem2')
        fi
    fi
    if [[ "$chipseq" -eq 1 ]]
    then
        envs+=(
            'chromhmm'
            'deeptools'
            'genrich'
            'homer'
            'macs2'
            'sicer2'
        )
    fi
    if [[ "$data_mining" -eq 1 ]]
    then
        envs+=('entrez-direct' 'sra-tools')
    fi
    if [[ "$file_formats" -eq 1 ]]
    then
        envs+=(
            'bamtools'
            'bcftools'
            'bedtools'
            'bioawk'
            'gffutils'
            'htslib'
            'sambamba'
            'samblaster'
            'samtools'
            'seqtk'
        )
        if koopa::is_linux
        then
            envs+=('biobambam')
        fi
    fi
    if [[ "$methylation" -eq 1 ]]
    then
        envs+=('bismark')
    fi
    if [[ "$quality_control" -eq 1 ]]
    then
        envs+=(
            'fastqc'
            'kraken'
            'kraken2'
            'multiqc'
            'qualimap'
        )
    fi
    if [[ "$rnaseq" -eq 1 ]]
    then
        # Consider: rapmap
        envs+=('kallisto' 'salmon')
    fi
    if [[ "$reticulate" -eq 1 ]]
    then
        envs+=(
            'pandas'
            'scikit-learn'
            'umap-learn'
        )
    fi
    if [[ "$trimming" -eq 1 ]]
    then
        envs+=('atropos' 'trimmomatic')
    fi
    if [[ "$variation" -eq 1 ]]
    then
        envs+=(
            'ericscript'
            'oncofuse'
            'peddy'
            'pizzly'
            'squid'
            'star-fusion'
            'vardict'
        )
        if koopa::is_linux
        then
            envs+=('arriba')
        fi
    fi
    if [[ "$workflows" -eq 1 ]]
    then
        # Consider: cromwell
        envs+=(
            'fgbio'
            'gatk4'
            'jupyterlab'
            'nextflow'
            'picard'
            'snakemake'
        )
    fi
    for i in ${!envs[*]}
    do
        env="${envs[$i]}"
        version="$(koopa::variable "conda-${env}")"
        envs[$i]="${env}@${version}"
    done
    koopa::conda_create_env "${envs[@]}"
    return 0
}

koopa::conda_create_env() { # {{{1
    # """
    # Create a conda environment.
    # @note Updated 2020-07-21.#
    #
    # Creates a unique environment for each recipe requested.
    # Supports versioning, which will return as 'star@2.7.5a' for example.
    # """
    local conda_prefix force env env_name pos prefix
    koopa::assert_has_args "$#"
    force=0
    pos=()
    while (("$#"))
    do
        case "$1" in
            --force)
                force=1
                shift 1
                ;;
            --)
                shift 1
                break
                ;;
            --*|-*)
                koopa::invalid_arg "$1"
                ;;
            *)
                pos+=("$1")
                shift 1
                ;;
        esac
    done
    [[ "${#pos[@]}" -gt 0 ]] && set -- "${pos[@]}"
    koopa::assert_has_args "$#"
    koopa::activate_conda
    koopa::assert_is_installed conda
    conda_prefix="$(koopa::conda_prefix)"
    for env in "$@"
    do
        env="${env//@/=}"
        # Get supported version.
        if ! koopa::str_match "$env" '='
        then
            koopa::stop "Version is required. Specify as 'NAME=VERSION'."
        fi
        env_name="${env//=/@}"
        prefix="${conda_prefix}/envs/${env_name}"
        if [[ -d "$prefix" ]]
        then
            if [[ "$force" -eq 1 ]]
            then
                conda remove --name "$env_name" --all
            else
                koopa::note "Conda environment '${env_name}' exists."
                continue
            fi
        fi
        koopa::info "Creating '${env_name}' conda environment."
        conda create --name="$env_name" --quiet --yes "$env"
        koopa::sys_set_permissions -r "$prefix"
    done
    return 0
}

koopa::conda_env_list() { # {{{1
    # """
    # Return a list of conda environments in JSON format.
    # @note Updated 2019-06-30.
    # """
    local x
    koopa::assert_has_no_args "$#"
    koopa::assert_is_installed conda
    x="$(conda env list --json)"
    koopa::print "$x"
    return 0
}

koopa::conda_env_prefix() { # {{{1
    # """
    # Return prefix for a specified conda environment.
    # @note Updated 2020-07-05.
    #
    # Note that we're allowing env_list passthrough as second positional
    # variable, to speed up loading upon activation.
    #
    # Example: koopa::conda_env_prefix 'deeptools'
    # """
    local env_dir env_list env_name x
    koopa::assert_has_args_le "$#" 2
    koopa::assert_is_installed conda
    env_name="${1:?}"
    [[ -n "$env_name" ]] || return 1
    env_list="${2:-$(koopa::conda_env_list)}"
    env_list="$(koopa::print "$env_list" | grep "$env_name")"
    if [[ -z "$env_list" ]]
    then
        koopa::stop "Failed to detect prefix for '${env_name}'."
    fi
    env_dir="$( \
        koopa::print "$env_list" \
        | grep "/envs/${env_name}" \
        | head -n 1 \
    )"
    x="$(koopa::print "$env_dir" | sed -E 's/^.*"(.+)".*$/\1/')"
    koopa::print "$x"
    return 0
}

koopa::conda_remove_env() { # {{{1
    # """
    # Remove conda environment.
    # @note Updated 2020-06-30.
    # """
    local arg
    koopa::assert_has_args "$#"
    koopa::activate_conda
    koopa::assert_is_installed conda
    for arg in "$@"
    do
        conda remove --yes --name="$arg" --all
    done
    return 0
}

koopa::pip_install() { # {{{1
    # """
    # Internal pip install command.
    # @note Updated 2020-08-13.
    # """
    local pip_install_flags pos python reinstall target
    koopa::assert_has_args "$#"
    python="$(koopa::python)"
    reinstall=0
    pos=()
    while (("$#"))
    do
        case "$1" in
            --python=*)
                python="${1#*=}"
                shift 1
                ;;
            --reinstall)
                reinstall=1
                shift 1
                ;;
            '')
                shift 1
                ;;
            --)
                shift 1
                break
                ;;
            --*|-*)
                koopa::invalid_arg "$1"
                ;;
            *)
                pos+=("$1")
                shift 1
                ;;
        esac
    done
    [[ "${#pos[@]}" -gt 0 ]] && set -- "${pos[@]}"
    koopa::is_installed "$python" || return 0
    # Install pip automatically, if necessary.
    ! koopa::is_python_package_installed pip && koopa::install_pip
    target="$(koopa::python_site_packages_prefix "$python")"
    koopa::sys_mkdir "$target"
    koopa::dl \
        'Packages' "$(koopa::to_string "$@")" \
        'Target' "$target"
    pip_install_flags=(
        "--target=${target}"
        '--no-warn-script-location'
        '--upgrade'
    )
    if [[ "$reinstall" -eq 1 ]]
    then
        pip_flags+=(
            '--force-reinstall'
            '--ignore-installed'
        )
    fi
    "$python" -m pip install "${pip_install_flags[@]}" "$@"
    return 0
}

koopa::pyscript() { # {{{1
    # """
    # Execute a Python script.
    # @note Updated 2020-11-19.
    # """
    local name prefix python script
    koopa::assert_has_args "$#"
    python="$(koopa::python)"
    prefix="$(koopa::pyscript_prefix)"
    name="${1:?}"
    shift 1
    script="${prefix}/${name}.py"
    koopa::assert_is_file "$script"
    "$python" "$script" "$@"
    return 0
}

koopa::python_add_site_packages_to_sys_path() { # {{{1
    # """
    # Add our custom site packages library to sys.path.
    # @note Updated 2020-11-23.
    #
    # @seealso
    # > "$python" -m site
    # """
    local file k_site_pkgs python sys_site_pkgs
    python="${1:-}"
    [[ -z "$python" ]] && python="$(koopa::python)"
    sys_site_pkgs="$(koopa::python_system_site_packages_prefix "$python")"
    k_site_pkgs="$(koopa::python_site_packages_prefix "$python")"
    [[ ! -d "$k_site_pkgs" ]] && koopa::sys_mkdir "$k_site_pkgs"
    file="${sys_site_pkgs}/koopa.pth"
    koopa::info "Adding '${file}' path file in '${sys_site_pkgs}'."
    if koopa::is_symlinked_app "$python"
    then
        koopa::write_string "$k_site_pkgs" "$file"
        koopa::link_app python
    else
        koopa::sudo_write_string "$k_site_pkgs" "$file"
    fi
    # This step will print the site packages configuration.
    "$python" -m site
    return 0
}

koopa::python_remove_pycache() { # {{{1
    # """
    # Remove Python '__pycache__/' from site packages.
    # @note Updated 2020-08-13.
    #
    # These directories can create permission issues when attempting to rsync
    # installation across multiple VMs.
    # """
    local pos prefix python
    koopa::assert_has_args_le "$#" 1
    koopa::assert_is_installed find
    python="$(koopa::python)"
    while (("$#"))
    do
        case "$1" in
            --python=*)
                python="${1#*=}"
                shift 1
                ;;
            *)
                koopa::invalid_arg "$1"
                ;;
        esac
    done
    koopa::assert_has_no_args "$#"
    python="$(koopa::which_realpath "$python")"
    prefix="$(koopa::parent_dir -n 2 "$python")"
    koopa::info "Removing pycache in '${prefix}'."
    find "$prefix" \
        -type d \
        -name '__pycache__' \
        -print0 \
        | xargs -0 -I {} rm -frv '{}'
    return 0
}

koopa::venv_create() { # {{{1
    # """
    # Create Python virtual environment.
    # @note Updated 2020-07-21.
    # """
    local name prefix python venv_python
    python="$(koopa::python)"
    koopa::assert_has_no_envs
    koopa::assert_is_installed "$python"
    name="${1:?}"
    prefix="$(koopa::venv_prefix)/${name}"
    [[ -d "$prefix" ]] && return 0
    shift 1
    koopa::info "Installing Python '${name}' venv at '${prefix}'."
    koopa::mkdir "$prefix"
    "$python" -m venv "$prefix"
    venv_python="${prefix}/bin/python3"
    "$venv_python" -m pip install --upgrade pip setuptools wheel
    if [[ "$#" -gt 0 ]]
    then
        "$venv_python" -m pip install --upgrade "$@"
    elif [[ "$name" != 'base' ]]
    then
        "$venv_python" -m pip install "$name"
    fi
    koopa::sys_set_permissions -r "$prefix"
    "$venv_python" -m pip list
    return 0
}

koopa::venv_create_base() { # {{{1
    # """
    # Create base Python virtual environment.
    # @note Updated 2020-07-20.
    # """
    koopa::assert_has_no_args "$#"
    koopa::venv_create 'base'
    return 0
}
