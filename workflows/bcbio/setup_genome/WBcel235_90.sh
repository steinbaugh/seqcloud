#!/bin/bash

# Build bcbio genome
# Caenorhabditis elegans
# 2018-03-16

# SLURM
# https://slurm.schedmd.com/sbatch.html

#SBATCH --job-name=genome              # Job name
#SBATCH --partition=medium             # Partition name
#SBATCH --time=1-00:00                 # Runtime in D-HH:MM format
#SBATCH --nodes=1                      # Number of nodes (keep at 1)
#SBATCH --ntasks=1                     # Number of tasks per node (keep at 1)
#SBATCH --cpus-per-task=8              # CPU cores requested per task (change for threaded jobs)
#SBATCH --mem-per-cpu=8G               # Memory needed per CPU
#SBATCH --error=jobid_%j.err           # File to which STDERR will be written, including job ID
#SBATCH --output=jobid_%j.out          # File to which STDOUT will be written, including job ID
#SBATCH --mail-type=ALL                # Type of email notification (BEGIN, END, FAIL, ALL)

# User-defined =================================================================
biodata="/n/shared_db/bcbio/biodata"
ens_name="Caenorhabditis_elegans"
ens_build="WBcel235"
ens_release=90
name="Celegans"

# Ensembl ======================================================================
ens_dir=$(echo "$ens_name" | tr '[:upper:]' '[:lower:]')

# bcbio ========================================================================
# -c --cores
# -f --fasta
# -g --gtf
# -n --name (organism name)
# -b --build (genome build)
cores=8
fasta="${ens_name}.${ens_build}.dna.toplevel.fa"
gtf="${ens_name}.${ens_build}.${ens_release}.gtf"
build="${ens_build}_${ens_release}"

cd "$biodata"
mkdir -p "$build"
cd "$build"

# FASTA
if [[ ! -f "$fasta" ]]; then
    wget "ftp://ftp.ensembl.org/pub/release-${ens_release}/fasta/${ens_dir}/dna/${fasta}.gz"
    gunzip -c "${fasta}.gz" > "$fasta"
fi

# GTF
if [[ ! -f "$gtf" ]]; then
    wget "ftp://ftp.ensembl.org/pub/release-${ens_release}/gtf/${ens_dir}/${gtf}.gz"
    gunzip -c "${gtf}.gz" > "$gtf"
fi

# Execute bcbio script from home directory
# cloudbiolinux will be installed
bcbio_setup_genome.py -c "$cores" -f "$fasta" -g "$gtf" -i bowtie2 star seq bwa -n "$name" -b "$build"
