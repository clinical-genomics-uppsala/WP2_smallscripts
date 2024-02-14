#!/bin/bash

# Initialize variables
step_one=false
step_two=false

# Process options and arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --step-one)
        step_one=true
        shift 1
        ;;
    --step-two)
        step_two=true
        shift 1
        ;;
    --help)
        echo "Either use --step-one for git cloning, prepping folders and tsv files to then edit manually, or --step-two for creating venv and running pgx"
        exit 1
        ;;
    *)
        echo "Error: Unknown option or missing argument: $1. Need either --step-one or --step-two"
        exit 1
        ;;
  esac
done



if $step_one
    then
        git clone https://github.com/genomic-medicine-sweden/pgx.git
        cd pgx/
        git checkout v0.2.0
        cp config/samples.tsv .
        cp config/units.tsv .
        mkdir -p alignment/samtools_merge_bam/
        echo -e "Create softlink to markduplicate bamfiles\nln -s /projects/wp2/nobackup/Twist_Myeloid/Workarea/{seqid}/Results/{sample}_{seqid}/Data/{sample}_{seqid}-dedup.bam alignment/samtools_merge_bam/{sample}_{type}.bam\nln -s /projects/wp2/nobackup/Twist_Myeloid/Workarea/{seqid}/Results/{sample}_{seqid}/Data/{sample}_{seqid}-dedup.bam.bai alignment/samtools_merge_bam/{sample}_{type}.bam.bai\n"
        echo "Don't forget to change samplename in samples.tsv and units.tsv"

elif $step_two
    then
        cd pgx/
        python3.9 -m venv venv_pgx
        source venv_pgx/bin/activate
        pip install -r requirements.txt
        pip install hydra-genetics==1.10.0 cyvcf2==0.30.16 drmaa snakemake==7.18.0 pulp==2.7.0
        snakemake --profile profiles/uppsala/ --notemp -p --keep-going
fi
