#!/bin/bash

set -e
# cwd is scratch

git_repo_url="https://github.com/clinical-genomics-uppsala/pickett_bcr_abl_pipeline.git"

# Initialize variables
inbox_path=""
analysis_path=""
pipeline_version=""
snakemake_profile="/projects/wp2/nobackup/WP2_smallscripts/snakemake-profiles/bcr_abl/"

# Process options and arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --inbox-path)
            inbox_path="$2"
            shift 2
            ;;
        --analysis-path)
            analysis_path="$2"
            shift 2
            ;;
		--pipeline-version)
            pipeline_version="$2"
            shift 2
            ;;
        *)
            echo "Error: Unknown option or missing argument: $1"
            exit 1
            ;;
    esac
done

# Check if required options are provided
if [ -z "$inbox_path" ]; then
    echo "Error: --inbox-path is required."
    exit 1
fi

if [ -z "$analysis_path" ]; then
    echo "Error: --analysis-path is required."
    exit 2
fi

if [ -z "$pipeline_version" ]; then
    echo "Error: --pipeline-version is required."
    exit 3
fi

cd $analysis_path

# Build env and activate it
echo "clone repo, build and activate env" && \
git clone --branch $pipeline_version $git_repo_url && \
python3 -m venv pickett_venv && \
source pickett_venv/bin/activate && \
pip install -r pickett_bcr_abl_pipeline/requirements.txt && \

# Prep data
echo "use hydra to build samples and units"  && \
hydra-genetics create-input-files -d fastq/ -p MiSeq \
            -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA,AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -t R -s "(R[0-9]{2}-[0-9]{5})" -b NNNNNNNN && \
sed -i 's/\t000000000-/\t/' units.tsv && \
cp ${snakemake_profile}/marvin_config/*.yaml ./ && \


# Run snakemake pipeline
echo "Load slurm-drmaa and run snakemake pipeline"
module load slurm-drmaa/1.1.3 && \
snakemake --profile ${snakemake_profile} --configfile config.yaml && \

# Cp to inbox?
echo "Cp Results to inbox"
rsync -ru Results ${inbox_path}/ 
