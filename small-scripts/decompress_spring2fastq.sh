#!/bin/bash
#SBATCH --time=24:00:00
#SBATCH --partition core,core_bkup
#SBATCH --ntasks=8

## To decompress spring compressed files into fastqs again. Fastq will end up in same dir as springfile

module load singularity #does not work with apptainer for some reason but using 3.11.0 it works
spring_file_full=$1

if [ "${spring_file_full:0:1}" = "/" ]; then
        wd_dir=$(dirname $spring_file_full)
else
        wd_dir=$(pwd)"/"$(dirname $spring_file_full)
fi

last_dir=$(echo $wd_dir | rev | cut -f1 -d"/" | rev)
spring_file=$(basename $spring_file_full)
outbase=$(basename $spring_file_full .spring)
# Add sleep so when in loop does not write to same tmp-folder
sleep 5
echo "singularity exec --bind ${wd_dir}/ docker://hydragenetics/spring:1.0.1 spring -t 8 -d -g -i ${last_dir}/${spring_file} -o ${last_dir}/${outbase}_R1.fastq.gz ${last_dir}/${outbase}_R2.fastq.gz"

singularity exec --bind ${wd_dir}/ docker://hydragenetics/spring:1.0.1 spring -t 8 -d -g -i ${last_dir}/${spring_file} -o ${last_dir}/${outbase}_R1.fastq.gz ${last_dir}/${outbase}_R2.fastq.gz
