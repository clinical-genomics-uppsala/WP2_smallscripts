#!/usr/bin/env bash

set -e
# cwd is scratch
git_repo_url_tm="https://github.com/clinical-genomics-uppsala/pomfrey"
git_repo_url_smallscripts="https://github.com/clinical-genomics-uppsala/WP2_smallscripts.git"

# Initialize variables
inbox_path=""
analysis_path=""
pipeline_version=""
smallscripts_version=""
sequenceid=""
samplesheet=""

# Process options and arguments
while[[ $# -gt 0 ]]; do
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
    --smallscripts-version)
        smallscripts_version="$2"
        shift 2
        ;;
    --sequenceid)
        sequenceid="$2"
        shift 2
        ;;
    --samplesheet)
        samplesheet="$2"
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

if [ -z "$smallscripts_version" ]; then
    echo "Error: --smallscripts-version is required."
    exit 4
fi

if [ -z "$sequenceid" ]; then
  echo "Error: --sequenceid is required."
  exit 5
fi

# If no samplesheet defined, set samplesheet to inbox samplesheet, and cp to cwd
if [ -z "$samplesheet" ]; then
  samplesheet=$(echo ${inbox_path}"/SampleSheet.csv")
fi

# Clone repos, setup and activate envs
echo "git clone --branch $pipeline_version $git_repo_url_tm & git clone --branch $smallscripts_version $git_repo_url_smallscript " && \
git clone --branch $pipeline_version $git_repo_url_tm && \
git clone --branch $smallscripts_version $git_repo_url_smallscripts && \

python3.11 -m venv venv_tm;  && \
source venv_tm/bin/activate;  && \
pip install -r pomfrey/requirements.txt;  && \
module load slurm-drmaa/1.1.3 && \

# Merge fastqs samples per lane into same file
mkdir -p fastqs/ && \
for i in $(cat ${samplesheet} | grep -i "wp2_tm_" |awk -F "," '{print $1}' ); do 
  $(echo $(basename ${inbox_path}/fastq-perLane/${i}_S*L001_R1_001.fastq.gz ) |cut -d '_' -f1-2); # If not L001 anymore, change
  echo ${sample}
  cat ${inbox_path}/fastq-perLane/${i}_S*R1_001.fastq.gz >fastqs/${sample}_R1_001.fastq.gz && \
  cat ${inbox_path}/fastq-perLane/${i}_S*R2_001.fastq.gz >fastqs/${sample}_R2_001.fastq.gz
done && \

# Create config-file
cp ${samplesheet} . && \
config=WP2_smallscripts/pipeline-starting-scripts/Pomfrey_Twist_Myeloid/config_defaults_latest.yaml && \
python3.9 WP2_smallscripts/pipeline-starting-scripts/Pomfrey_Twist_myeloid/set_up_config.py -i ${config} -s ${sequenceid} && \


# Run pomfrey-snakemake line
snakemake -p -j 120 --restart-times 1 --drmaa " --nodes=1-1 -A wp2 -p core -t {cluster.time} -n {cluster.n} " \
-s pomfrey/src/somaticPipeline.smk \
--configfile ${sequenceid}_config.yaml \
--use-singularity  --singularity-prefix /projects/wp4/nobackup/singularity_cache/ \
--singularity-args "--cleanenv --bind /data --bind /projects " --latency-wait 5 \
--cluster-config pomfrey/cluster-config-uppsala.json \
--rerun-incomplete \
&& \
# Remove files?
rm slurm-* && \
rm -r ${inbox_path}/fastq-perLane && \
# Cp to inbox?
rsync -ru Results ${inbox_path}/ && \
rsync -ru variantCalls ${inbox_path}/ 
