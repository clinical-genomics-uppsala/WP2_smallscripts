## Execute CNVkit on Twist Myloid samples 
This directory contains a snakemake file and a python script to run CNVkit on Twist Myloid samples. Needs a pomfrey config file with paths to bam and corresponding vcf file. Outputs into a results directory and creates an excel sheet.
- run\_CNVkit.smk
- vcf2excel\_cnvkit.py 

## Threshold calculator
R script that calculates threshold values for CNVkit in case of impure samples.
- cnvkit\_threshold\_calculator.R 

run as `Rscript cnvkit_threshold_calculator.R <ploidy> <purity>`
