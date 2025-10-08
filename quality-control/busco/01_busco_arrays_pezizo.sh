#!/usr/bin/bash

#SBATCH --mem-per-cpu=16G  # Memory per CPU
#SBATCH -c 16               # Number of threads per process
#SBATCH --output=/work/edw36/comp-genomics/quality-control/logs/busco/busco_%a.out
#SBATCH --error=/work/edw36/comp-genomics/quality-control/logs/busco/busco_%a.err
#SBATCH --partition=scavenger
#SBATCH -t 07:00:00      
#SBATCH --array=0-289 # Array range

GENOMES=/work/edw36/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/unmasked
OUTPUT=/work/edw36/comp-genomics/quality-control/busco

set -euo pipefail

# Activate conda
source $(conda info --base)/etc/profile.d/conda.sh
conda activate busco

cd "${OUTPUT}"

GENOME_FILES=($(ls "${GENOMES}"/*.fasta))
FILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]}
BASENAME=$(basename "$FILE" .fasta)


################################################################################################
#############                    RUNNING A FILE CHECKPOINT                          ############
################################################################################################
# RUN THE CHECKPOINT
# VALIDATE FILE
if [ -z "${FILE}" ]; then
    echo "=== [Error]: No genome file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}. Exiting."
    exit 1
fi

# VALIDATE BASENAME
if [ -z "${BASENAME}" ]; then
    echo "=== [Error]: BASENAME is empty. Exiting."
    exit 1
fi

################################################################################################
#############                 PREPARE DIRECTORIES AND SET VARS                      ############
################################################################################################
# Output directories
OUTDIR="${OUTPUT}/pezizomycotina/${BASENAME}"
SUMMARY_TSV="${OUTPUT}/BUSCO_summary/all_summary/tsv"
SUMMARY_JSON="${OUTPUT}/BUSCO_summary/all_summary/json"
BUSCO_SUMMARY_DIR=${OUTPUT}/BUSCO_summary/all_summary

mkdir -p "${OUTDIR}" "${SUMMARY_TSV}" "${SUMMARY_JSON}" "${BUSCO_SUMMARY_DIR}"



cd "${OUTPUT}/pezizomycotina"

################################################################################################
echo "# 1. Running BUSCO for $BASENAME"
################################################################################################
#############                 PREPARE DIRECTORIES AND SET VARS                      ############
################################################################################################

busco -i "$FILE" \
      -o "$BASENAME" \
      -l ascomycota_odb12 \
      -m genome \
      -f \
      -c 16

cp "${OUTDIR}/short_summary."*.txt "${SUMMARY_TSV}/" || true
cp "${OUTDIR}/short_summary."*.json "${SUMMARY_JSON}/" || true

echo "=== BUSCO analysis for ${BASENAME} completed"
echo "=== Next step is to run the BUSCO summary script. The results from the raw BUSCO results are found in ${OUTPUT}/BUSCO_summary/"

conda deactivate


#####################
# How to run BUSCO:
#####################
# busco -h
# usage: busco -i [SEQUENCE_FILE] -l [LINEAGE] -o [OUTPUT_NAME] -m [MODE] [OTHER OPTIONS]

# Welcome to BUSCO 6.0.0: the Benchmarking Universal Single-Copy Ortholog assessment tool.
# For more detailed usage information, please review the README file provided with this distribution and the BUSCO user guide. Visit this page https://gitlab.com/ezlab/busco#how-to-cite-busco to see how to cite BUSCO

# optional arguments:
#   -i SEQUENCE_FILE, --in SEQUENCE_FILE
#                         Input sequence file in FASTA format. Can be an assembled genome or transcriptome (DNA), or protein sequences from an annotated gene set. Also possible to use a path to a directory containing multiple input files.
#   -o OUTPUT, --out OUTPUT
#                         Give your analysis run a recognisable short name. Output folders and files will be labelled with this name. The path to the output folder is set with --out_path.
#   -m MODE, --mode MODE  Specify which BUSCO analysis mode to run.
#                         There are three valid modes:
#                         - geno or genome, for genome assemblies (DNA)
#                         - tran or transcriptome, for transcriptome assemblies (DNA)
#                         - prot or proteins, for annotated gene sets (protein)
#   -l LINEAGE, --lineage_dataset LINEAGE
#                         Specify the name of the BUSCO lineage to be used.
#   --augustus            Use augustus gene predictor for eukaryote runs
#   --augustus_parameters "--PARAM1=VALUE1,--PARAM2=VALUE2"
#                         Pass additional arguments to Augustus. All arguments should be contained within a single string with no white space, with each argument separated by a comma.
#   --augustus_species AUGUSTUS_SPECIES
#                         Specify a species for Augustus training.
#   --auto-lineage        Run auto-lineage to find optimum lineage path
#   --auto-lineage-euk    Run auto-placement just on eukaryote tree to find optimum lineage path
#   --auto-lineage-prok   Run auto-lineage just on non-eukaryote trees to find optimum lineage path
#   -c N, --cpu N         Specify the number (N=integer) of threads/cores to use.
#   --config CONFIG_FILE  Provide a config file
#   --contig_break n      Number of contiguous Ns to signify a break between contigs. Default is n=10.
#   --datasets_version DATASETS_VERSION
#                         Specify the version of BUSCO datasets, e.g. odb10, odb12 (default odb12)
#   --download [dataset ...]
#                         Download dataset. Possible values are a specific dataset name, "all", "prokaryota", "eukaryota", or "virus". If used together with other command line arguments, make sure to place this last.
#   --download_base_url DOWNLOAD_BASE_URL
#                         Set the url to the remote BUSCO dataset location
#   --download_path DOWNLOAD_PATH
#                         Specify local filepath for storing BUSCO dataset downloads
#   -e N, --evalue N      E-value cutoff for BLAST searches. Allowed formats, 0.001 or 1e-03 (Default: 1e-03)
#   -f, --force           Force rewriting of existing files. Must be used when output files with the provided name already exist.
#   -h, --help            Show this help message and exit
#   --limit N             How many candidate regions (contig or transcript) to consider per BUSCO (default: 3)
#   --list-datasets [LIST_DATASETS]
#                         Print the list of available BUSCO datasets
#   --long                Optimization Augustus self-training mode (Default: Off); adds considerably to the run time, but can improve results for some non-model organisms
#   --metaeuk             Use Metaeuk gene predictor
#   --metaeuk_parameters "--PARAM1=VALUE1,--PARAM2=VALUE2"
#                         Pass additional arguments to Metaeuk for the first run. All arguments should be contained within a single string with no white space, with each argument separated by a comma.
#   --metaeuk_rerun_parameters "--PARAM1=VALUE1,--PARAM2=VALUE2"
#                         Pass additional arguments to Metaeuk for the second run. All arguments should be contained within a single string with no white space, with each argument separated by a comma.
#   --miniprot            Use Miniprot gene predictor
#   --skip_bbtools        Skip BBTools for assembly statistics
#   --offline             To indicate that BUSCO cannot attempt to download files
#   --opt-out-run-stats   Opt out of data collection. Information on the data collected is available in the user guide.
#   --out_path OUTPUT_PATH
#                         Optional location for results folder, excluding results folder name. Default is current working directory.
#   --plot WORKING_DIRECTORY
#                         Generate a BUSCO summary plot for all short summary files in the given working directory.
#   --plot_percentages    Plot the percentages of BUSCOs instead of the number of BUSCOs. To be used as an option with --plot.
#   -q, --quiet           Disable the info logs, displays only errors
#   -r, --restart         Continue a run that had already partially completed.
#   --scaffold_composition
#                         Writes ACGTN content per scaffold to a file scaffold_composition.txt
#   --tar                 Compress some subdirectories with many files to save space
#   -v, --version         Show this version and exit