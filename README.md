# WP2_smallscripts
Random small scripts and pipelines for WP2

## Directories
- CNVkit
- Snakemake-profiles
- Snakemake-rules


## Content of Directories
### CNVkit
This directory contains a snakemake file and a python script to run CNVkit on Twist Myloid samples. Needs a pomfrey config file with paths to bam and corresponding vcf file. Outputs into a results directory and creates an excel sheet.
- `run_CNVkit.smk`
- `vcf2excel_cnvkit.py`

R script that calculates threshold values for CNVkit in case of impure samples.
- `cnvkit_threshold_calculator.R` 

run as `Rscript cnvkit_threshold_calculator.R <ploidy> <purity>`

### Snakemake-profiles
Directory for snakemake profiles to run piplines. Each pipeline should have a folder containg the snakemake profile config.yaml file as well as a folder inside that called marvin_config which contains resources.yaml and config.yaml for running the pipeline in marvin.
```
${pipeline}/config.yaml
${pipeline}/marvin_config/config.yaml
${pipeline}/marvin_config/resources.yaml
```
As of now it contains the configis for the following pipelines:
- [Niffler](https://github.com/clinical-genomics-uppsala/niffler_small_cnv) :moneybag: :gem:
- [wgs_leukemia_konigskobra](https://github.com/clinical-genomics-uppsala/wgs_leukemia_konigskobra) :crown: :snake:

### Snakemake-rules
This directory contains snakemake files and (if needed) acompanied scripts located in snakemake/scripts. Snakefile and script should have the same name.
- `{snakerule}.smk`
- `scripts/{snakerule}.{ext}`

