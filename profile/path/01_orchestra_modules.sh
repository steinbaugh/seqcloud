if [[ $orchestra = true ]]; then
    # Unload everything
    module load null

    # dev
    module load dev/boost-1.57.0
    module load dev/compiler/cmake-3.3.1
    module load dev/compiler/llvm-3.8.0
    module load dev/gcc-4.8.5
    # module load dev/gcc-5.2.0
    module load dev/java/jdk1.8
    module load dev/lapack
    module load dev/leiningen/stable-feb032016
    module load dev/openblas/0.2.14
    module load dev/openssl/1.0.1
    module load dev/python/3.4.2
    module load dev/ruby/2.2.4
    
    # image
    module load image/imageMagick/6.9.1

    # seq
    module load seq/bcl2fastq/2.17.1.14
    module load seq/sratoolkit/2.8.1

    # stats
    module load stats/R/3.3.1
    
    # utils
    module load utils/pandoc/1.17.0.3
    module load utils/xz/5.2.2
fi
