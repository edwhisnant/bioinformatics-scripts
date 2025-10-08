#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/EDTA/lecanoromycetes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/EDTA/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=EDTA-v25.09.01
#SBATCH -t 7-00:00:00
#SBATCH --array=30 # Array range

##########################################################################
####          Extensive de-novo TE Annotator (EDTA) v2.2.2           #####
##########################################################################

# ==== Set paths and variables
EDTA_PL=/hpc/group/bio1/ewhisnant/miniconda3/envs/EDTA/bin/EDTA.pl
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/annotate_TEs/EDTA
THREADS=16

# === Create the index for the array job ===
NUC_FILES=($(ls ${IN_DIR}/*/annotate_results/*.nuclear.unmasked.fa))
NFILE=${NUC_FILES[$SLURM_ARRAY_TASK_ID]}
BASENAME=$(basename "${NFILE}" .nuclear.unmasked.fa)

# === Validate input files exist ===
if [ -z "${NFILE}" ]; then
    echo "Error: No genome file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}. Exiting."
    exit 1
fi

if [ -z "${BASENAME}" ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi

# === Run EDTA
source $(conda info --base)/etc/profile.d/conda.sh
conda activate EDTA

mkdir -p ${OUTDIR}/${BASENAME}
cd ${OUTDIR}/${BASENAME}

# NOTE: For fungal neutral subsitution rate (u), we used 1.05e-9 per site per year
# References: Kasuga et al., 2002; Dhillon et al., 2014; Castanera et al., 2016; Guo et al., 2018

# Keaton metnioned that it is best to run EDTA with the standard settings.
# There is also some suggestion predict genes and provide the CDS file so that EDTA can avoid masking perfectly good genes.
# The only issue with this is that funannotate2 does not output the "CDS" file and rather provides the "transcripts" file, which may include data that EDTA does not want.
# So, for now, we are running EDTA without the CDS file.


perl ${EDTA_PL} \
    --genome ${NFILE} \
    --species others \
    --step all \
    --overwrite 1 \
    --force 1 \
    --sensitive 1 \
    --u 1.3e-8  \
    --threads ${THREADS} \
    --anno 1 \
    --evaluate 1

conda deactivate


##########################################################################
 # For information on running EDTA, see:
##########################################################################

# perl /hpc/group/bio1/ewhisnant/miniconda3/envs/EDTA/bin/EDTA.pl -h

# #########################################################
# ##### Extensive de-novo TE Annotator (EDTA) v2.2.2  #####
# ##### Shujun Ou (shujun.ou.1@gmail.com)             #####
# #########################################################


# Parameters: -h



# This is the Extensive de-novo TE Annotator that generates a high-quality
# structure-based TE library. Usage:

# perl EDTA.pl [options]
#         --genome [File]         The genome FASTA file. Required.
#         --species [Rice|Maize|others]   Specify the species for identification of TIR
#                                         candidates. Default: others
#         --step [all|filter|final|anno]  Specify which steps you want to run EDTA.
#                                         all: run the entire pipeline (default)
#                                         filter: start from raw TEs to the end.
#                                         final: start from filtered TEs to finalizing the run.
#                                         anno: perform whole-genome annotation/analysis after
#                                                 TE library construction.
#         --overwrite [0|1]       If previous raw TE results are found, decide to overwrite
#                                 (1, rerun) or not (0, default).
#         --cds [File]    Provide a FASTA file containing the coding sequence (no introns,
#                         UTRs, nor TEs) of this genome or its close relative.
#         --curatedlib [File]     Provided a curated library to keep consistant naming and
#                                 classification for known TEs. TEs in this file will be
#                                 trusted 100%, so please ONLY provide MANUALLY CURATED ones.
#                                 This option is not mandatory. It's totally OK if no file is
#                                 provided (default).
#         --rmlib [File]  Provide the RepeatModeler library containing classified TEs to enhance
#                         the sensitivity especially for LINEs. If no file is provided (default),
#                         EDTA will generate such file for you.
#         --sensitive [0|1]       Use RepeatModeler to identify remaining TEs (1) or not (0,
#                                 default). This step may help to recover some TEs.
#         --anno [0|1]    Perform (1) or not perform (0, default) whole-genome TE annotation
#                         after TE library construction.
#         --rmout [File]  Provide your own homology-based TE annotation instead of using the
#                         EDTA library for masking. File is in RepeatMasker .out format. This
#                         file will be merged with the structural-based TE annotation. (--anno 1
#                         required). Default: use the EDTA library for annotation.
#         --maxdiv [0-100]        Maximum divergence (0-100%, default: 40) of repeat fragments comparing to 
#                                 library sequences.
#         --evaluate [0|1]        Evaluate (1) classification consistency of the TE annotation.
#                                 (--anno 1 required). Default: 1.
#         --exclude [File]        Exclude regions (bed format) from TE masking in the MAKER.masked
#                                 output. Default: undef. (--anno 1 required).
#         --force [0|1]   When no confident TE candidates are found: 0, interrupt and exit
#                         (default); 1, use rice TEs to continue.
#         --u [float]     Neutral mutation rate to calculate the age of intact LTR elements.
#                         Intact LTR age is found in this file: *EDTA_raw/LTR/*.pass.list.
#                         Default: 1.3e-8 (per bp per year, from rice).
#         --repeatmodeler [path]  The directory containing RepeatModeler (default: read from ENV)
#         --repeatmasker  [path]  The directory containing RepeatMasker (default: read from ENV)
#         --annosine      [path]  The directory containing AnnoSINE_v2 (default: read from ENV)
#         --ltrretriever  [path]  The directory containing LTR_retriever (default: read from ENV)
#         --check_dependencies Check if dependencies are fullfiled and quit
#         --threads|-t [int]      Number of theads to run this script (default: 4)
#         --debug  [0|1]  Retain intermediate files (default: 0)
#         --help|-h       Display this help info