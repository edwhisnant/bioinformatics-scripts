#!/usr/bin/bash

#SBATCH --mem-per-cpu=3G   # Memory per CPU
#SBATCH -c 16               # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/logs/pezizomycotina_%a.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/logs/pezizomycotina_%a.err
#SBATCH --partition=scavenger
#SBATCH -t 15-00:00:00
#SBATCH --array=0-279 # Array range (change after quality control step)

################################################################################################
# NOTE 25.10.14:
# There is currently an issue with funannotate2 during the taxonmy lookup when busco is used 
# in the training step. 260/276 genomes have completeted their annotations successfully. Below are
# the remaining 16 genomes that are failing at various steps in the pipeline.

# === From the error files, the following jobs are failing:
# [150] Meliniomyces_bicolor_JGI_GCA_002865645.1. Fails to recognize taxonomy. Error occurs when `Getting taxonomy information` -- returns `false`
# [152] Metacordyceps_chlamydosporia_JGI_Mchlamy1. Fails to recognize taxonomy. Error occurs when `Getting taxonomy information` -- returns `false`
# [158]  Best busco lineage for Monascus_purpureus_NCBI_GCA_003184285.1 is recognized as asperigillaceae, but busco fails to search and download the lineage. Returns `KeyError: 'aspergillaceae'`
# [159]  Best busco lineage for Monascus_ruber_NCBI_GCA_002976275.1 is recognized as asperigillaceae, but busco fails to search and download the lineage. Returns `KeyError: 'aspergillaceae'
# [177] Unsure of what is causing the error for Ophiognomonia_clavigignenti-juglandacearum_NCBI_GCA_003013035.1. Fails after the initial BUSCO pass, when miniprot is launched and augustus/pyhammer is run for remaining steps.
# [183] Best busco lineage for Penicilliopsis_zonata_JGI_GCA_001890105.1 is recognized as asperigillaceae, but busco fails to search and download the lineage. Returns `KeyError: 'aspergillaceae'
# [211] Best busco lineage for Pseudogymnoascus_verrucosus_NCBI_GCA_001662655.1 is recognized as thelebolales, but busco fails to search and download the lineage. Returns `KeyError: 'thelebolales'`
# [246] Best busco lineage for Thelebolus_globosus_JGI_Theglo1 is recognized as thelebolales, but busco fails to search and download the lineage. Returns `KeyError: 'thelebolales'`
# [24] Unsure of what is causing the error for Bathelium_albidoporum_NCBI_GCA_021031095.1. Fails after the initial BUSCO pass, when miniprot is launched and augustus/pyhammer is run for remaining steps. Commonality with [177]: Both are using the augustus species [species=verticillium_longisporum1].
# [268] Unsure of what is causing the error for Valsa_mali_NCBI_GCA_000818155.1. Fails after the initial BUSCO pass, when miniprot is launched and augustus/pyhammer is run for remaining steps. Commonality with [177]: Both are using the sordariomycetes_odb12 lineage and in the Diaporthales.
# [275] Best busco lineage for Xeromyces_bisporus_NCBI_GCA_900006255.1 is recognized as asperigillaceae, but busco fails to search and download the lineage. Returns `KeyError: 'aspergillaceae'
# [35] Recognizing taxonomy for Byssochlamys_nivea_NCBI_GCA_003116535.1. Error occurs when `Getting taxonomy information` -- returns `false`
# [39] Cairneyella_variabilis_NCBI_GCA_001625345.1. Fails after the initial BUSCO pass, when miniprot is launched and augustus/pyhammer is run for remaining steps. Fails using [species=botrytis_cinerea]
# [62] Clarireedia_homoeocarpa_NCBI_GCA_002242835.1. Fails after the initial BUSCO pass, when miniprot is launched and augustus/pyhammer is run for remaining steps. Fails using [species=botrytis_cinerea]
# [67] Colletotrichum_falcatum_NCBI_GCA_001484525.1. Fails after the initial BUSCO pass, when miniprot is launched and augustus/pyhammer is run for remaining steps. Fails using [species=verticillium_longisporum1]
# [97] Epibryaceae_sp_IL1160_Unpublished_NA. Fails to recognize taxonomy. Error occurs when `Getting taxonomy information` -- returns `false`


################################################################################################
#############                   RUNNING FUNANNOTATE2 PIPELINE                       ############
################################################################################################

# SET VARIABLES
THREADS=16
COMP_GENOMICS=/hpc/group/bio1/ewhisnant/comp-genomics  # Base directory for outputs for comp-genomics
GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/raw # Directory containing genome files
UNMASKED=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/ascomycota/select_pezizomycotina_25.09.24/unmasked 
GENOME_FILES=($(ls ${GENOMES}/*.fa)) #List of genome files to process
GFILE=${GENOME_FILES[$SLURM_ARRAY_TASK_ID]} # Create the index for the array job
BASENAME=$(basename "${GFILE}" .fa) # Extract the base name of the genome file

# Output directory for the funannotate2 pipeline
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/pezizomycotina

F2_INTERMEDIATE=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2/v25.09.29/f2-intermediate-files
MASKED_DIR=${F2_INTERMEDIATE}/masked-genomes/other-pezizomycotina    # Directory for masked genomes
CLEANED_DIR=${F2_INTERMEDIATE}/cleaned-genomes/other-pezizomycotina

################################################################################################
#############                    RUNNING A FILE CHECKPOINT                          ############
################################################################################################
# RUN THE CHECKPOINT

# HAS THE GENOME BEEN ANNOTATED ALREADY? IF SO, SKIP IT AND EXIT
if [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.gbk" ] && \
   [ -f "${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.proteins.fa" ]; then
    echo "Genome ${BASENAME} has already been processed. Skipping."
    exit 0
fi

# VALIDATE GFILE
if [ -z "${GFILE}" ]; then
    echo "Error: No genome file found for SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}. Exiting."
    exit 1
fi

# VALIDATE BASENAME
if [ -z "${BASENAME}" ]; then
    echo "Error: BASENAME is empty. Exiting."
    exit 1
fi

# VALIDATE OUTPUT/BASENAME BEFORE DELETION
if [ -d "${OUTPUT}/${BASENAME}" ]; then
    echo "Removing the previous output of ${BASENAME} if it exists"
    rm -r ${OUTPUT}/${BASENAME}
else
    echo "${BASENAME} output is empty. Continuing with the pipeline."
    
fi

###############################################################################################
echo "# 1. Pre-processing genome: ${BASENAME}"
################################################################################################
############          PRE-PROCESSING: UNMASK GENOME & REMOVE MITO CONTIGS           ############
################################################################################################
## NOTE: NCBI genomes are pre-soft masked, so to ensure they are properly processed, we need to unmask them first

mkdir -p ${F2_INTERMEDIATE} # Create the intermediate file

source $(conda info --base)/etc/profile.d/conda.sh
conda activate seqkit

# === Unmasking the genome
echo "=== Ensuring genome is not masked. Unmasking ${BASENAME} genome file ==="

UNMASKED_ASSEMBLY=${UNMASKED}/${BASENAME}.fasta

seqkit seq -u ${GFILE} -o ${UNMASKED_ASSEMBLY}


###############################################################################################
echo "# 2. Cleaning genome: ${BASENAME}"
################################################################################################
############                          CLEANING GENOME                               ############
################################################################################################

# === Cleaning with F2 clean
source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

export FUNANNOTATE2_DB=/hpc/group/bio1/ewhisnant/databases/funannotate2_db

mkdir -p ${CLEANED_DIR}/cleaned # Make the cleaned directory to store the cleaned genomes
CLEANED_ASSEMBLY=${CLEANED_DIR}/cleaned/${BASENAME}_cleaned.fa

# === Check to see if the file already exists
# === If not, run f2 clean
# === If it does, skip and move on...

if [ -f "$CLEANED_ASSEMBLY" ]; then
    echo "=== Cleaned assembly detected -- skipping this step! ==="
else
    echo "=== Running funannotate2 clean for ${BASENAME} ==="
    funannotate2 clean \
        -f ${UNMASKED_ASSEMBLY} \
        -o ${CLEANED_ASSEMBLY}

    # sanity check
    if [ -f "$CLEANED_ASSEMBLY" ]; then
        echo "=== Cleaned genome file created: $CLEANED_ASSEMBLY ==="
    else
        echo "[Error]: funannotate2 clean failed for ${BASENAME}"
        exit 1
    fi
fi

conda deactivate


###############################################################################################
echo "# 3. Masking genome with EarlGrey: ${BASENAME}"
################################################################################################
############                           MASKING GENOME                               ############
################################################################################################
### === note 25.09.19: This part of the pipleline is under revision. We may need to adjust the masking parameters, as we are noticing that some genomes are beinf UNDER masked.
### For example, some genomes have ~50% of the genome as TEs (depending on the program method), but RepeatMasker is only masking 1-2% of the genome.

# === Run EarlGrey
source $(conda info --base)/etc/profile.d/conda.sh
conda activate earlgrey

mkdir -p ${MASKED_DIR}/${BASENAME}

# Create the softmasked genome variable
SOFTMASKED_ASSEMBLY=${MASKED_DIR}/${BASENAME}/${BASENAME}_EarlGrey/${BASENAME}_summaryFiles/${BASENAME}.softmasked.fasta

# === Check to see if earlgrey has been run on the genome previously
# === If so, then skip to the next step
# === If not, run earlgrey to annotate TEs and repeats

if [ -f ${SOFTMASKED_ASSEMBLY} ]; then

    echo "=== Soft-masked genome detected, moving on to gene prediction ==="
    echo "=== Path to soft-masked genome: ${SOFTMASKED_ASSEMBLY} ==="

else
    echo "=== Masking ${BASENAME} genome file with EarlGrey ==="

    earlGrey \
        -g ${CLEANED_ASSEMBLY} \
        -s ${BASENAME} \
        -o ${MASKED_DIR}/${BASENAME} \
        -t ${THREADS} \
        -e yes \
        -i 10 \
        -f 1000 \
        -c no \
        -m no \
        -d yes \
        -n 20 \
        -a 3

    conda deactivate

    # Check to see if the masking was completed
    if [ -f ${SOFTMASKED_ASSEMBLY} ]; then
        echo "=== Soft-masked genome file created: ${SOFTMASKED_ASSEMBLY} ==="
    else
        echo "[Error]: Soft-masked genome file not found for ${BASENAME}!"
        exit 1
    fi
fi


###############################################################################################
echo "# 4. Training ab initio gene predictions: ${BASENAME}"
################################################################################################
############                TRAINING AB INITIO GENE PREDICTIONS                     ############
################################################################################################

source $(conda info --base)/etc/profile.d/conda.sh
conda activate funannotate2

# Using a pre-masked genome from EarlGrey

funannotate2 train \
    -f ${SOFTMASKED_ASSEMBLY} \
    --cpus ${THREADS}  \
    -s ${BASENAME} \
    -o ${OUTPUT}/${BASENAME}

###############################################################################################
echo "# 5. Predicting genes: ${BASENAME}"
################################################################################################
############                        RUN GENE PREDICTION                             ############
################################################################################################

funannotate2 predict -i ${OUTPUT}/${BASENAME} --cpus ${THREADS}


###############################################################################################
echo "# 6. Annotating genes: ${BASENAME}"
################################################################################################
############                        RUN GENE ANNOTATION                             ############
################################################################################################

funannotate2 annotate -i ${OUTPUT}/${BASENAME} --cpus ${THREADS}

conda deactivate


###############################################################################################
echo "# 7. Renaming F2 output files: ${BASENAME}"
################################################################################################
############             ENSURE FILES ARE RENAMED TO PROPER FORMAT                  ############
################################################################################################

TARGET_DIR=${OUTPUT}/${BASENAME}/annotate_results # Directory containing the files to rename

# Change to the target directory
cd "${TARGET_DIR}"

# Define the extensions to match
EXTENSIONS=("fasta" "gbk" "gff3" "proteins.fa" "summary.json" "tbl" "transcripts.fa")

# Loop through all files with the specified extensions
for ext in "${EXTENSIONS[@]}"; do
    for file in *."${ext}"; do
        # Check if the file exists
        if [ -e "$file" ]; then
            # Rename the file
            mv "$file" "${BASENAME}.${ext}"
            
            # Check if the rename was successful
            if [ $? -eq 0 ]; then
                echo "=== Renamed $file to ${BASENAME}.${ext} ==="
            else
                echo "=== Error in renaming $file. Skipping. ==="
            fi
        fi
    done
done


###############################################################################################
echo "# 8. Splitting mito contigs: ${BASENAME}"
################################################################################################
############                          REMOVE MITO DNA                               ############
################################################################################################
# Note 09.30.25: Need to see what the annotation is once the trial has finished running 
echo "=== If mito DNA was identified, funannotate2 has edited the FASTA headers accordingly."

echo "=== Remaining mitochondrial contigs (if present) will be printed below:"
grep "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta

echo "=== Separating newly identified mitochondrial contigs with seqkit (if present) ==="

seqkit grep -nvrip "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta > ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta # Keeps only the nuclear DNA
seqkit grep -nrip "mito" ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.fasta > ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta # Keeps only the mito DNA

echo "=== Saved nuclear contigs to: ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.nuclear.fasta"
echo "=== Saved mito contigs to: ${OUTPUT}/${BASENAME}/annotate_results/${BASENAME}.mito.fasta"

