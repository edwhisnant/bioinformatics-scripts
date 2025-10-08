#!/usr/bin/bash

#SBATCH --mem-per-cpu=4G  # adjust as needed
#SBATCH -c 16 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/annotate_ogs/annotate_ogroups_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/annotate_ogs/annotate_ogroups_%a.err
#SBATCH --partition=common
#SBATCH --array=1-200 # Array range


# === Define variables ===
VERSION=v25.08.19
RESULTS=Results_Aug22
EGGNOG_DATA=/hpc/group/bio1/ewhisnant/databases/eggnog-mapper-data
INTERPROSCAN=/hpc/group/bio1/ewhisnant/software/my_interproscan/interproscan-5.75-106.0
LIST=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroups/OGs_for_annotation_list.txt
FASTA_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/Orthogroup_Sequences
EGG_OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/eggnog
IPR_OUTDIR=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/${VERSION}/${RESULTS}/iprscan-annotations
HMMER_DB=/hpc/group/bio1/ewhisnant/databases/eggnog-mapper-data/hmmer/Ascomycota

# === Get the correct orthogroup file and ensure it is in unix format ===
dos2unix ${LIST}
FASTA_FILE=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$LIST")
BASENAME=$(basename "$FASTA_FILE" .fa)

# === Checkpoint to ensure there is a real file
if [ -z "$FASTA_FILE" ]; then
  echo "No FASTA file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}"
  exit 1
fi

if [ -z "${BASENAME}" ]; then
  echo "BASENAME empty"
  exit 1
fi

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate eggnog

cd ${FASTA_DIR}
mkdir -p "${EGG_OUTDIR}"
mkdir -p "${IPR_OUTDIR}"

# 1. === Run eggNOG-mapper ===
echo "Running eggNOG mapper on ${BASENAME}"

emapper.py --version

emapper.py \
  -i ${FASTA_DIR}/${FASTA_FILE} \
  -o ${BASENAME} \
  --override \
  --itype proteins \
  -m hmmer \
  --database Ascomycota \
  --evalue 0.00001 \
  --go_evidence all \
  --cpu 16 \
  --output_dir ${EGG_OUTDIR} \
  --data_dir ${EGGNOG_DATA}

conda deactivate

# 2. === Run InterProScan ===
# Run InterProScan on the same FASTA file (adjust path to InterProScan accordingly)

# === CALLING CONDA ENVIRONMENT ===
source $(conda info --base)/etc/profile.d/conda.sh
conda activate java11 #InterProScan5 requires Java 11

echo "Running InterProScan on ${BASENAME}"

bash ${INTERPROSCAN}/interproscan.sh --version

bash ${INTERPROSCAN}/interproscan.sh \
  -i "${FASTA_DIR}/${FASTA_FILE}" \
  --seqtype p \
  -f TSV \
  -o "${IPR_OUTDIR}/${BASENAME}.interproscan.tsv" \
  --disable-precalc \
  --iprlookup --goterms --pathways \
  -pa \
  -cpu 16

conda deactivate

echo "Done with ${BASENAME}"
