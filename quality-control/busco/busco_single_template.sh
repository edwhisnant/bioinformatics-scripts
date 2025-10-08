#!/usr/bin/bash

#SBATCH --mem-per-cpu=64G  # adjust as needed
#SBATCH -c 10 # Number of threads per process
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/busco.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/logs/busco.err
#SBATCH --partition=scavenger

GENOMES=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/temp-genomes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/quality-control/busco
GENERATE_PLOT=/hpc/group/bio1/ewhisnant/miniconda3/envs/busco/bin/generate_plot.py

cd ${OUTPUT}

################################################################################################
############                        STEP 1: RUN BUSCO                               ############
################################################################################################

# ACTIVATE CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate busco

echo "Starting BUSCO analysis"
echo `date`

# Change the directory to send the output to the correct location
cd ${OUTPUT}

# # Create a directory for the summary
# mkdir -p ${OUTPUT}/BUSCO_summary

INPUT=/hpc/group/bio1/ewhisnant/comp-genomics/genomes/lecanoromycetes/Fitzroyomyces_cyperi_CBS_143170_JGI_NA.fa
basename=$(basename "${INPUT}" .fa)
mkdir -p ${OUTPUT}/${basename}

    # Run BUSCO
    busco -i "${INPUT}" \
        -o "${basename}" \
        -l ascomycota_odb12 \
        -m genome \
        -f \
        -c 10

    # COPY A SUMMARY FILE TO THE BUSCO_SUMMARY DIRECTORY
    cp ${OUTPUT}/${basename}/short_summary.*.txt ${OUTPUT}/BUSCO_summary/

done

# Run the comparison:
echo "Running the genomes comparison and summarizing the results"
sbatch /hpc/group/bio1/ewhisnant/comp-genomics/scripts/quality-control/busco/02_busco_analysis_template.sh
