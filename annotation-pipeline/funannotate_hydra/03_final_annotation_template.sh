#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/armaleo-data/logs/funannotate-logs/trial-hydra-04/trial-hydra-FINAL.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/armaleo-data/logs/funannotate-logs/trial-hydra-04/trial-hydra-FINAL.err
#SBATCH --partition=common

# This script is for compiling and finalizing the annotatiosn from the intermediate annotations
    # The intermediate annotations produce the following:
    # 1. InterProScan5 XML file
    # 2. SignalP pre-computed results (a .txt file)
    # 3. antiSMASH secondary metabolism results (GBK file from output)
    # 4. DeepLoc pre-computed results (a .csv file)
    # 5. EffectorP pre-computed results (a .txt file)

# NOTE: This is untested as of (3.19.25) and is incomplete

# SET VARIABLES
PREDICT_DIR=/hpc/group/bio1/ewhisnant/armaleo-data/Clagr3/funannotations/test-w-repeatsuite
INTERMEDIATE_FILES=${PREDICT_DIR}/intermediate_annotations
ANNOTATE_DIR=${PREDICT_DIR}/annotate

# OUTPUTS FROM STEP 2: INTERMEDIATE ANNOTATIONS
IPRSCAN=${INTERMEDIATE_FILES}/interproscan_results
SIGNALP=${INTERMEDIATE_FILES}/signalp
EFFECTORP=${INTERMEDIATE_FILES}/effectorp
ANTISMASH=${INTERMEDIATE_FILES}/antismash
DEEPLOC=${INTERMEDIATE_FILES}/deeploc_out

################################################################################################
############         STEP 3: COMPILE INTERMEDIATE ANNOTATIONS AND FINALIZE          ############
################################################################################################

rm -r /hpc/group/bio1/ewhisnant/armaleo-data/Clagr3/funannotations/test-w-repeatsuite/annotate_misc
rm -r /hpc/group/bio1/ewhisnant/armaleo-data/Clagr3/funannotations/test-w-repeatsuite/annotate_results

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate_hydra

funannotate annotate \
    -i ${PREDICT_DIR} \
    -o ${ANNOTATE_DIR} \
    --species "Cladonia_grayi" \
    --antismash ${ANTISMASH}/Cladonia_grayi.gbk \
    --iprscan ${IPRSCAN}/interproscan_results.xml \
    --signalp ${SIGNALP}/prediction_results.txt \
    --busco_db pezizomycotina \
    --renumber_antismash \
    --tmpdir ${PREDICT_DIR}/tmp \
    --cpus 16

conda deactivate

################################################################################################
############          CHECK OUTPUT AND MOVE ONTO COMPARATIVE GENOMICS               ############
################################################################################################

# NOTE: UNSURE ABOUT THESE ARGUMENTS:
    # --deeploc ${DEEPLOC}/results_20250319-134446.csv \
    # --effectorp ${EFFECTORP}/effectors.txt \