#!/usr/bin/env bash

set -euxo pipefail

echo "RUNNING: wp2 tm"
# cwd is scratch
git_repo_url_tm="https://github.com/clinical-genomics-uppsala/pomfrey.git"
git_repo_url_smallscripts="https://github.com/clinical-genomics-uppsala/WP2_smallscripts.git"

# Initialize variables
bin_path="/projects/bin/wp2_tm/"
inbox_path=""
analysis_path=$(pwd)
pomfrey_version=""
smallscripts_version=""
sequenceid=""
samplesheet=""

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
    --pomfrey-version)
        pomfrey_version="$2"
        shift 2
        ;;
    --smallscripts-version)
        smallscripts_version="$2"
        shift 2
        ;;
    --sequenceid)
        sequenceid="$2"
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

if [ -z "$pomfrey_version" ]; then
    echo "Error: --pomfrey-version is required."
    exit 3
fi

if [ -z "$smallscripts_version" ]; then
    echo "Error: --smallscripts-version is required."
    exit 4
fi

# If no sequence-id is defined, set it to current folder name
if [ -z "$sequenceid" ]; then
    sequenceid=${PWD##*/}
fi

pomfrey_path=${bin_path}/pomfrey/${pomfrey_version}/ &&
    smallscripts_path=${bin_path}/wp2_smallscripts/${smallscripts_version}/ &&

    # If correct pomfrey version not avail locally download and configure
    if [ ! -d ${pomfrey_path} ]; then
        echo "New version of Pomfrey needed; ${pomfrey_version}. Cloning repo, setup and activating env" &&
            mkdir -p ${pomfrey_path} &&
            cd ${pomfrey_path} &&
            git clone --branch $pomfrey_version $git_repo_url_tm &&
            echo "Cloning Pomfrey done, creating and activating env" &&
            python3.9 -m venv venv_tm &&
            source venv_tm/bin/activate &&
            pip install -r pomfrey/requirements.txt &&
            cd ${analysis_path}
    else
        source ${pomfrey_path}/venv_tm/bin/activate
    fi

# If correct version of WP2_smallscripts not avail locally, clone from github
if [ ! -d ${smallscripts_path} ]; then
    echo "New version of smallscripts needed; ${smallscripts_version}. Cloning repo" &&
        mkdir -p ${smallscripts_path} &&
        cd ${smallscripts_path} &&
        git clone --branch $smallscripts_version $git_repo_url_smallscripts &&
        cd ${analysis_path}
fi

module load slurm-drmaa/1.1.3 &&
    echo "Set up config and start pipeline" &&
    # Set up config and merge fastqs samples per lane into same file
    mkdir -p fastq_merged/ &&
    config=${smallscripts_path}/WP2_smallscripts/pipeline-starting-scripts/Pomfrey_Twist_Myeloid/config_defaults_latest.yaml &&
    python3.9 ${smallscripts_path}/WP2_smallscripts/pipeline-starting-scripts/Pomfrey_Twist_Myeloid/set_up_config.py -i ${config} -s ${sequenceid} -fi ${inbox_path}/fastq/ &&

    # Run pomfrey-snakemake line
    snakemake -p -j 120 --restart-times 1 --drmaa " --nodes=1-1 -A wp2 -p core -t {cluster.time} -n {cluster.n} " \
        -s ${pomfrey_path}/pomfrey/src/somaticPipeline.smk \
        --configfile ${sequenceid}_config.yaml \
        --use-singularity --singularity-prefix /projects/wp4/nobackup/singularity_cache/ \
        --singularity-args "--cleanenv --bind /data --bind /projects " --latency-wait 5 \
        --cluster-config ${pomfrey_path}/pomfrey/cluster-config-uppsala.json \
        --rerun-incomplete \
        --keep-going &&
    rm slurm-*
