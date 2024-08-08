# WP2_smallscripts
Random small scripts and pipelines for WP2

## Directories
- CNVkit
- Pipeline starting scripts
- Small scripts
- Snakemake-profiles
- Snakemake-rules


## Content of Directories
### CNVkit
This directory contains a snakemake file and a python script to run CNVkit on Twist Myloid samples. Needs a pomfrey config file with paths to bam and corresponding vcf file. Outputs into a results directory and creates an excel sheet.
- `run_CNVkit.smk`
- `vcf2excel_cnvkit.py`

R script that calculates threshold values for CNVkit in case of impure samples.
- `cnvkit_threshold_calculator.R`: run as `Rscript cnvkit_threshold_calculator.R <ploidy> <purity>`

### Pipeline-starting-scripts
A folder for bash (or similar) scripts used by Stanley to start clinical pipelines.
- `start_bcr_abl1.sh`: BCR::ABL1 fusion detection pipline. Stand in sequence folder inside INBOX. Run as `bash start_bcr_abl1.sh <sequenceid>`
- `Pomfrey_Twist_Myeloid`: folder with files to help create config-files for [Pomfrey](https://github.com/clinical-genomics-uppsala/pomfrey). Is used in start_tm.sh, but can be used stand-alone `python3 set_up_config.yaml -h`.

### Small scripts
This directory contains useful small scripts
- `wgs_rename_samples.py`: renames samples in `samples.tsv` and `units.tsv` to pedegree_id from a "bioinformatic SampleSheet". Only includes sample from defined workpackages and analysis, also checks for duplicate sex, cgu-project ids and that cell type is known. Usage `python3 wgs_rename_samples.py --help`
- `get_pathogenic_variants.py`:  file for extracting pathogenic (and likley path osv) and vus variants from a detected variant list (e.g. `/projects/wp2/nobackup/Twist_Myeloid/DetectedVariants/twistVariants-NewDesign2021-10.txt` for TM). `python3 get_pathogenic_variants.py variantlist.txt <basename of output>`
- `somalier_relate.sh`: script to run `[somalier](https://github.com/brentp/somalier/) relate` from bam on hg19 samples. If needed, [change sites file to hg38](https://github.com/brentp/somalier/releases/tag/v0.2.17). Takes one infolder and the basename for outfiles. Is very quick!
    ```
    $> sbatch -A wp2 -p core -n 1 -t 12:00:00 -J somalier WP2_smallscripts/small_scripts/somalier_relate.sh bam_files/ somalier_results
    ```
- `run_gms_pgx.sh [--step-one | --step-two | --help]`: script to clone and run gms [pgx pipeline](https://github.com/genomic-medicine-sweden/pgx/). Consists of two steps. First step; clone repo and checkout correct version (v0.2.0 as of 240214 since same as gms560). Manually softlink bamfiles and edit samples.tsv and units.tsv files then procceed to step-two. Step-two; creates venv and run snakemake.


### Snakemake-profiles
Directory for snakemake profiles to run piplines. Each pipeline should have a folder containg the snakemake profile config.yaml file as well as a folder inside that called marvin_config which contains resources.yaml and config.yaml for running the pipeline on marvin.
```
${pipeline}/config.yaml
${pipeline}/marvin_config/config.yaml
${pipeline}/marvin_config/resources.yaml
```
As of now it contains the configs for the following pipelines:
- [BCR_ABL1](https://github.com/clinical-genomics-uppsala/bcr_abl_pipeline/) :snake:
- [Niffler](https://github.com/clinical-genomics-uppsala/niffler_small_cnv) :moneybag: :gem:
- [wgs_leukemia_konigskobra](https://github.com/clinical-genomics-uppsala/wgs_leukemia_konigskobra) :crown: :snake:

### Snakemake-rules
This directory contains snakemake files and (if needed) acompanied scripts located in snakemake/scripts. Snakefile and script should have the same name.
- `{snakerule}.smk`
- `scripts/{snakerule}.{ext}`
