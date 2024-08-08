#!/usr/bin/env bash

set -euxo pipefail

echo "RUNNING: wp2 abl"
# cwd is scratch

git_repo_url="https://github.com/clinical-genomics-uppsala/pickett_bcr_abl_pipeline.git"
git_repo_url_smallscripts="https://github.com/clinical-genomics-uppsala/WP2_smallscripts.git"

# Initialize variables
bin_path="/projects/bin/wp2_abl/"
inbox_path=""
analysis_path=$(pwd)
pickett_version=""
smallscripts_version=""

# Process options and arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --bin-path)
        bin_path="$2"
        shift 2
        ;;
    --inbox-path)
        inbox_path="$2"
        shift 2
        ;;
    --pickett-version)
        pickett_version="$2"
        shift 2
        ;;
    --smallscripts-version)
        smallscripts_version="$2"
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

if [ -z "$pickett_version" ]; then
    echo "Error: --pickett-version is required."
    exit 2
fi

if [ -z "$smallscripts_version" ]; then
    echo "Error: --smallscripts-version is required."
    exit 3
fi

pickett_path=${bin_path}/pickett_bcr_abl/${pickett_version}/ &&
    smallscripts_path=${bin_path}/wp2_smallscripts/${smallscripts_version}/ &&

    # If correct pickett version not avail locally download and configure
    if [ ! -d ${pickett_path}/pickett_bcr_abl_pipeline/ ]; then
        # Build env and activate it
        echo "New version on pickett; ${pickett_version}. Clone repo, build and activate env" &&
            mkdir -p ${pickett_path} &&
            cd ${pickett_path} &&
            git clone --branch $pickett_version $git_repo_url &&
            echo "Cloning Pickett done, build and activate env" &&
            python3.9 -m venv venv_pickett &&
            source venv_pickett/bin/activate &&
            pip install -r pickett_bcr_abl_pipeline/requirements.txt &&
            cd ${analysis_path}
    else
        source ${pickett_path}/venv_pickett/bin/activate
    fi

# If correct version of WP2_smallscripts not avail locally, clone from github
if [ ! -d ${smallscripts_path}/WP2_smallscripts/ ]; then
    echo "New version of smallscripts needed; ${smallscripts_version}. Cloning repo" &&
        mkdir -p ${smallscripts_path} &&
        cd ${smallscripts_path} &&
        git clone --branch $smallscripts_version $git_repo_url_smallscripts &&
        cd ${analysis_path}
fi

# Prep data
echo "use hydra to build samples and units" &&
    hydra-genetics create-input-files -d ${inbox_path}/fastq/ -p MiSeq \
        -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCA,AGATCGGAAGAGCGTCGTGTAGGGAAAGAGTGT -t R -s "(R[0-9]{2}-[0-9]{5})" -b NNNNNNNN &&
    sed -i 's/\t000000000-/\t/' units.tsv &&
    sed -i 's/\/\//\//g' units.tsv &&
    cp ${smallscripts_path}/WP2_smallscripts/snakemake-profiles/pickett_bcr_abl/marvin_config/*.yaml ./ &&

    # Run snakemake pipeline
    echo "Load slurm-drmaa and run snakemake pipeline" &&
    module load slurm-drmaa &&
    snakemake --profile ${smallscripts_path}/WP2_smallscripts/snakemake-profiles/pickett_bcr_abl/ -s ${pickett_path}/pickett_bcr_abl_pipeline/workflow/Snakefile --configfile config.yaml --config PATH_TO_REPO=${pickett_path}

