#!/usr/bin/bash

#SBATCH --mem-per-cpu=1G  # adjust as needed
#SBATCH -c 32 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/HiTE/lecanoromycetes_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/HiTE/lecanoromycetes_%a.err
#SBATCH --partition=scavenger
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=HiTE-v25.09.01
#SBATCH -t 2-00:00:00
#SBATCH --array=0-115 # Array range

# === Define variables ===
HiTE_DIR=/hpc/group/bio1/ewhisnant/software/HiTE
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/annotate_TEs/HiTE/
THREADS=32

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

# === Run HiTE
source $(conda info --base)/etc/profile.d/conda.sh
conda activate HiTE

# NOTE: For fungal neutral subsitution rate (u), we used 1.05e-9 per site per year
# References: Kasuga et al., 2002; Dhillon et al., 2014; Castanera et al., 2016; Guo et al., 2018
python ${HiTE_DIR}/main.py \
    --genome ${NFILE} \
    --thread ${THREADS} \
    --out_dir ${OUTDIR}/${BASENAME} \
    --plant 0 \
    --miu 1.05e-9 \
    --te_type all \
    --annotate 1 \
    --recover 1 \
    --search_struct 1 \
    --is_denovo_nonltr 1 \
    --use_HybridLTR 1 \
    --use_NeuralTE 1 \
    --is_wicker 0 \
    --is_output_LTR_lib 1 \
    --min_TE_len 80 \
    --flanking_len 50 \
    --fixed_extend_base_threshold 4000 \
    --tandem_region_cutoff 0.5 \
    --max_repeat_len 30000 \
    --chrom_seg_length 1000000

conda deactivate

##########################################################################
 # For information on running HiTE, see:
##########################################################################
#  python3 main.py -h

#      __  __     __     ______   ______    
#     /\ \_\ \   /\ \   /\__  _\ /\  ___\   
#     \ \  __ \  \ \ \  \/_/\ \/ \ \  __\   
#      \ \_\ \_\  \ \_\    \ \_\  \ \_____\ 
#       \/_/\/_/   \/_/     \/_/   \/_____/ version 3.3.3


# usage: main.py [-h] --genome genome [--out_dir [OUT_DIR]] [--work_dir [WORK_DIR]] [--thread thread_num] [--chunk_size chunk_size]
#                [--miu miu] [--plant is_plant] [--te_type te_type] [--curated_lib curated_lib] [--remove_nested is_remove_nested]
#                [--domain is_domain] [--recover is_recover] [--annotate is_annotate] [--search_struct search_struct] [--BM_RM2 BM_RM2]
#                [--BM_EDTA BM_EDTA] [--BM_HiTE BM_HiTE] [--EDTA_home EDTA_home] [--coverage_threshold coverage_threshold]
#                [--species species] [--skip_HiTE skip_HiTE] [--is_denovo_nonltr is_denovo_nonltr] [--debug is_debug]
#                [--use_HybridLTR use_HybridLTR] [--use_NeuralTE use_NeuralTE] [--is_wicker is_wicker]
#                [--is_output_LTR_lib is_output_LTR_lib] [--min_TE_len min_TE_len] [--flanking_len flanking_len]
#                [--fixed_extend_base_threshold fixed_extend_base_threshold] [--tandem_region_cutoff tandem_region_cutoff]
#                [--max_repeat_len max_repeat_len] [--chrom_seg_length chrom_seg_length] [--shared_prev_TE shared_prev_TE]

# ########################## HiTE, version 3.3.3 ##########################

# optional arguments:
#   -h, --help            show this help message and exit
#   --genome genome       Input genome assembly path
#   --out_dir [OUT_DIR]   The path of output directory; It is recommended to use a new directory to avoid automatic deletion of
#                         important files.
#   --work_dir [WORK_DIR]
#                         The temporary work directory for HiTE.
#   --thread thread_num   Input thread num, default = [ 8 ]
#   --chunk_size chunk_size
#                         The chunk size of genome, default = [ 400 MB ]
#   --miu miu             The neutral mutation rate (per bp per ya), default = [ 1.3e-08 ]
#   --plant is_plant      Is it a plant genome, 1: true, 0: false. default = [ 1 ]
#   --te_type te_type     Retrieve specific type of TE output [ltr|tir|helitron|non-ltr|all]. default = [ all ]
#   --curated_lib curated_lib
#                         Provide a fully trusted curated library, which will be used to pre-mask highly homologous sequences in the
#                         genome. We recommend using TE libraries from Repbase and ensuring the format follows >header#class_name.
#                         default = [ None ]
#   --remove_nested is_remove_nested
#                         Whether to remove nested TE, 1: true, 0: false. default = [ 1 ]
#   --domain is_domain    Whether to obtain TE domains, HiTE uses RepeatPeps.lib from RepeatMasker to obtain TE domains, 1: true, 0:
#                         false. default = [ 0 ]
#   --recover is_recover  Whether to enable recovery mode to avoid starting from the beginning, 1: true, 0: false. default = [ 0 ]
#   --annotate is_annotate
#                         Whether to annotate the genome using the TE library generated, 1: true, 0: false. default = [ 0 ]
#   --search_struct search_struct
#                         Is the structural information of full-length copies being searched, 1: true, 0: false. default = [ 1 ]
#   --BM_RM2 BM_RM2       Whether to conduct benchmarking of RepeatModeler2, 1: true, 0: false. default = [ 0 ]
#   --BM_EDTA BM_EDTA     Whether to conduct benchmarking of EDTA, 1: true, 0: false. default = [ 0 ]
#   --BM_HiTE BM_HiTE     Whether to conduct benchmarking of HiTE, 1: true, 0: false. default = [ 0 ]
#   --EDTA_home EDTA_home
#                         When conducting benchmarking of EDTA, you will be asked to input EDTA home path.
#   --coverage_threshold coverage_threshold
#                         The coverage threshold of benchmarking methods.
#   --species species     Which species you want to conduct benchmarking, six species support (dmel, rice, cb, zebrafish, maize, ath).
#   --skip_HiTE skip_HiTE
#                         Whether to skip_HiTE, 1: true, 0: false. default = [ 0 ]
#   --is_denovo_nonltr is_denovo_nonltr
#                         Whether to detect non-ltr de novo, 1: true, 0: false. default = [ 1 ]
#   --debug is_debug      Open debug mode, and temporary files will be kept, 1: true, 0: false. default = [ 0 ]
#   --use_HybridLTR use_HybridLTR
#                         Whether to use HybridLTR to identify LTRs, 1: true, 0: false. default = [1 ]
#   --use_NeuralTE use_NeuralTE
#                         Whether to use NeuralTE to classify TEs, 1: true, 0: false. default = [1 ]
#   --is_wicker is_wicker
#                         Use Wicker or RepeatMasker classification labels, 1: Wicker, 0: RepeatMasker. default = [ 0 ]
#   --is_output_LTR_lib is_output_LTR_lib
#                         Whether to output LTR library. default = [ 1 ]
#   --min_TE_len min_TE_len
#                         The minimum TE length, default = [ 80 bp ]
#   --flanking_len flanking_len
#                         The flanking length of candidates to find the true boundaries, default = [ 50 ]
#   --fixed_extend_base_threshold fixed_extend_base_threshold
#                         The length of variation can be tolerated during pairwise alignment, default = [ 4000 ]
#   --tandem_region_cutoff tandem_region_cutoff
#                         Cutoff of the candidates regarded as tandem region, default = [ 0.5 ]
#   --max_repeat_len max_repeat_len
#                         The maximum length of a single repeat, default = [ 30000 ]
#   --chrom_seg_length chrom_seg_length
#                         The length of genome segments, default = [ 1000000 ]
#   --shared_prev_TE shared_prev_TE
#                         The path of shared previous TEs