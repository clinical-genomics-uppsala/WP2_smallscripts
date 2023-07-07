#!/bin/bash

INFOLDER=$1
OUTBASE=$2

module load singularity

# Loop through folder with bam and bai files to create somalier files with extract
for i in $(ls ${INFOLDER}/*bam); do 
        singularity exec --bind /projects/,/data/ docker://brentp/somalier:v0.2.17 somalier extract -s /projects/wp4/nobackup/workspace/arielle_test/twist/somalier_test/sites.hg19.vcf.gz -f /data/ref_genomes/hg19/genome_fasta/hg19.with.mt.fasta -d extract/ ${i} ;
done 

# Since beegfs system does not allow long one-lines the results need to be written on compute tmp then moved to runfolder
mkdir -p /tmp/${OUTBASE}
singularity exec --bind /projects/,/data/ docker://brentp/somalier:v0.2.17 somalier relate --unknown -o /tmp/${OUTBASE} extract/*somalier

cp -r /tmp/${OUTBASE}* .
