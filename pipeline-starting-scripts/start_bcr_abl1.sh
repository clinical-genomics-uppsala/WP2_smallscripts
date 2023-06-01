#!/bin/bash

# borde gora en specifik for abl pipeline!
source /projects/wp2/nobackup/BCR_ABL1/Bin/venv_bcr_abl/bin/activate
module load singularity/3.11.0 slurm-drmaa/1.1.3
echo "Module loaded"
seqrun=$1
snakemake_profile=/projects/wp2/nobackup/WP2_smallscripts/snakemake-profiles/bcr_abl/

outbox_dir=/projects/wp2/nobackup/BCR_ABL1/OUTBOX/
start_dir=$(pwd)
bin_dir=/projects/wp2/nobackup/BCR_ABL1/Bin/bcr_abl_pipeline

hydra-genetics create-input-files -d ${start_dir}/fastq/ -p MiSeq \
            -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA,AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -t R -s "(R[0-9]{2}-[0-9]{5})" -b NNNNNNNN && \
sed -i 's/\t000000000-/\t/' units.tsv && \
echo "Hydra genetics create input files done, and remove miseq 00000-" && \
cp ${snakemake_profile}/marvin_config/*yaml ./ && \
echo "Cp configfiles to ${start_dir} done" && \
# Cp SampleSheet.csv sample.tsv units.tsv resources.yaml config.yaml to scratch
mkdir -p /scratch/wp2/abl/${seqrun}/ && \
rsync -ruvp *sv /scratch/wp2/abl/${seqrun}/ && \
rsync -ruvp *yaml /scratch/wp2/abl/${seqrun}/ && \

cd /scratch/wp2/abl/${seqrun}/ && \
echo "Cp files to scratch and move to scratch done" && \
snakemake --profile ${snakemake_profile} --configfile config.yaml && \

echo "Snakemake done" && \
mkdir -p ${outbox_dir}/${seqrun} && \
rsync -ruvp -r Results/ ${outbox_dir}/${seqrun} && \
touch ${outbox_dir}/${seqrun}/Done.txt && \
echo "Cp to outbox done" && \
rsync -ruvp -r Results ${start_dir}/ && \
echo "Done!"
