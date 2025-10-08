#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G  # adjust as needed
#SBATCH -c 1 # Number of threads per process
#SBATCH --partition=common

TARBALL_NAME=$1
DIR_TO_TAR=$2

tar -czvf ${TARBALL_NAME}.tar.gz ${DIR_TO_TAR}
# Check if the tarball was created successfully
