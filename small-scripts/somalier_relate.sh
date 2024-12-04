#!/usr/bin/env bash

# Run on compute node! 1 core
set -euxo pipefail

echo "RUNNING: somalier relate"

# Initialize variables
bam_folder=""
outfolderbase=""
sites_file=""
ref_fasta=""
extract_folder="extract/"
options_relate="--unknown "

# Process options and arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
    --bam-folder)
        bam_folder="$2"
        shift 2
        ;;
    --outfolderbase)
        outfolderbase="$2"
        shift 2
        ;;
    --sites-file)
        sites_file="$2"
        shift 2
        ;;
    --ref-fasta)
        ref_fasta="$2"
        shift 2
        ;;
    --extract-folder)
	extract_folder="$2"
	shift 2
	;;
    --options-relate)
        options_relate="$2"
	shift 2
	;;
    *)
        echo "Error: Unknown option or missing argument: $1"
        exit 1
        ;;
    esac
done

# Check if required options are provided
if [ -z "$bam_folder" ]; then
    echo "Error: --bam-folder is required."
    exit 1
fi

if [ -z "$outfolderbase" ]; then
    echo "Error: --outfolderbase is required."
    exit 2
fi

if [ -z "$sites_file" ]; then
    echo "Error: --sites-file is required."
    exit 3
fi

if [ -z "$ref_fasta" ]; then
    echo "Error: --ref-fasta is required."
    exit 4
fi

module load singularity

echo "Loop through folder with bam and bai files to create somalier files with extract" &&
for i in $(ls ${bam_folder}/*bam); do
	echo "Extracting ${i}"  &&
        echo "somalier extract -s ${sites_file} -f ${ref_fasta} -d ${extract_folder} ${i} " &&
        singularity exec --bind /projects/,/data/ docker://brentp/somalier:v0.2.18 somalier extract -s ${sites_file} -f ${ref_fasta} -d ${extract_folder} ${i} ;
done 
echo "Extracting done" &&
# Since beegfs system does not allow long one-lines the results need to be written on compute tmp then moved to runfolder
echo "Creating folder /tmp/" &&
mkdir -p /tmp/${outfolderbase} &&
echo "somalier relate ${options_relate} -o /tmp/${outfolderbase} ${extract_folder}/*somalier" &&
singularity exec --bind /projects/,/data/ docker://brentp/somalier:v0.2.18 somalier relate ${options_relate} -o /tmp/${outfolderbase} ${extract_folder}/*somalier &&

echo "Relate done, cp /tmp to current folder" && 
mkdir -p ${outfolderbase}/ &&
cp -r /tmp/${outfolderbase}* ${outfolderbase}/ 
