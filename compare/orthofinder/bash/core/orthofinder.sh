#!/usr/bin/bash

#SBATCH --mem 500G  # adjust as needed
#SBATCH -c 64 # Number of threads
#SBATCH --output=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-v25.08.19.out
#SBATCH --error=/hpc/group/bio1/ewhisnant/comp-genomics/compare/logs/orthofinder/lecanoromycetes-v25.08.19.err
#SBATCH --partition=common
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=edw36@duke.edu
#SBATCH --job-name=orthofinder-v25.08.19
#SBATCH -t 7-00:00:00

# === Define variables ===
IN_DIR=/hpc/group/bio1/ewhisnant/comp-genomics/funannotate2-out/lecanoromycetes
OUTPUT=/hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/lecanoromycetes/v25.08.19/
PHYLING_TREE=/hpc/group/bio1/ewhisnant/comp-genomics/compare/phyling/lecanoromycetes/v25.08.19/consensus/2000-models/final_tree.nw
PRIMARY_TRANSCRIPT_PY=/hpc/group/bio1/ewhisnant/miniconda3/envs/orthofinder/bin/primary_transcript.py

cd ${IN_DIR}

# If the output already exists, orthofinder will report an error
# rm -r ${OUTPUT}

# Create a temporary directory for input files
TEMP_DIR=$(mktemp -d /hpc/group/bio1/ewhisnant/comp-genomics/compare/orthofinder/temp-dir.XXXXXX)

# Find all protein FASTA files in the specified directory and copy them to the temporary directory
echo "Copying protein FASTA files to temporary directory: ${TEMP_DIR}"
find "${IN_DIR}" -path "*/annotate_results/*proteins.fa" -exec cp {} ${TEMP_DIR} \;

################################################################################################
############                          RUN ORTHOFINDER                               ############
################################################################################################

# CALLING CONDA ENVIRONMENT
source $(conda info --base)/etc/profile.d/conda.sh
conda activate orthofinder

# OrthoFinder v3.1.0 now suggests too run a cleaning step for each proteome
# It will extract the longest protein variant from each proteome
echo "Extracting the longest protein variant from each genome/proteome with `primary_transcript.py`"
for f in ${TEMP_DIR}/*.proteins.fa ; do python3 ${PRIMARY_TRANSCRIPT_PY} $f ; done

# Print the version of OrthoFinder being used
orthofinder -v

# Run OrthoFinder with the primary transcripts
orthofinder \
    -f ${TEMP_DIR}/primary_transcripts \
    -T fasttree \
    -t 64 \
    -a 16 \
    -M msa \
    -A mafft \
    -S diamond \
    -y \
    -s ${PHYLING_TREE} \
    -o ${OUTPUT}

conda deactivate

# Clean up the temporary directory
echo "Cleaning up temporary directory: ${TEMP_DIR}"
rm -rf ${TEMP_DIR}

################################################################################################
# For help with OrthoFinder usage, see below
################################################################################################
# orthofinder -h

# SIMPLE USAGE:
#  Run full OrthoFinder analysis on FASTA format proteomes in <dir>
#    orthofinder [options] -f <dir>

#  To assign species from <dir1> to existing OrthoFinder orthogroups in <dir2>
#    orthofinder [options] --assign <dir1> --core <dir2>

# OPTIONS:
#  -t <int>                Number of parallel sequence search threads [Default = 8]                      
#  -a <int>                Number of parallel analysis threads                                           
#  -M <txt>                Method for gene tree inference. Options "dendroblast" & "msa" [Default = msa] 
#  -S <txt>                Sequence search program [Default = diamond]                                   
#                          Options: diamond, diamond_ultra_sens, blastp, mmseqs, blastn                  
#  -A <txt>                MSA program, requires "-M msa" [Default = famsa]                              
#                          Options: muscle, mafft, famsa                                                 
#  -T <txt>                Tree inference method, requires "-M msa" [Default = FastTree]                 
#                          Options: fasttree, fasttree_fastest, raxml, iqtree3, iqtree3_LG               
#  -s <file>               User-specified rooted species tree                                            
#  -I <int>                MCL inflation parameter [Default = 1.2]                                       
#  -n <txt>                Name to append to the results directory                                       
#  -o <txt>                Non-default results directory                                                 
#  -d                      Input is DNA sequences.                                                       
#  -X                      Don't add species names to sequence IDs                                       
#  -y                      Split paralogous clades below root of a HOG into separate HOGs                
#  -z                      Don't trim MSAs (columns>=90% gap, min. alignment length 500)                 
#  -h                      Print this help text                                                          

# WORKFLOW STOPPING OPTIONS:
#  -op                     Stop after preparing input files for BLAST 

# WORKFLOW RESTART COMMANDS:
#  -b <dir>                Start OrthoFinder from pre-computed BLAST results in <dir> 

# VERSION:
#  -v                      Show the current version number 

# LICENSE:
#  Distributed under the GNU General Public License (GPLv3). See License.md


# CITATION:
#  When publishing work that uses OrthoFinder please cite:
#  Emms D.M., Liu Y., Belcher L., Holmes J. & Kelly S. (2025), bioRxiv
#  Emms D.M. & Kelly S. (2019), Genome Biology 20:238

#  If you use the species tree in your work then please also cite:
#  Emms D.M. & Kelly S. (2017), MBE 34(12): 3267-3278
#  Emms D.M. & Kelly S. (2018), bioRxiv https://doi.org/10.1101/267914
