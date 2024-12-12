#!/bin/bash
dir=$1

for sample in $(tail -n+2 ${dir}/samples.tsv | cut -f1 )
do

        echo $sample

        types=$(awk -v sample=$sample '$1==sample {a[$2]++} END{for(b in a) print b}' units.tsv | tr "\n" " " )

        echo $types

        if [[ "$types" == *"T"* ]]
        then

                sbatch -A wp4 -p low -n20 -N 1-1 -t 24:00:00 -J t_$sample --wrap "singularity exec --bind /beegfs-scratch,/scratch,/projects/,/data,/home,/beegfs-storage docker://hydragenetics/manta:1.6.0 /usr/local/bin/configManta.py \
                                 --tumorBam=$dir/parabricks/pbrun_fq2bam/${sample}_T.bam \
                                           --referenceFasta=/beegfs-storage/data/ref_genomes/GRCh38/reference_grasnatter/homo_sapiens.fasta \
                                                      --runDir=$dir/cnv_sv/manta_run_workflow_t/${sample}

                singularity exec --bind /projects/,/data,/home,/beegfs-storage,/beegfs-scratch,/scratch \
                docker://hydragenetics/manta:1.6.0 $dir/cnv_sv/manta_run_workflow_t/${sample}/runWorkflow.py -j 20 -g unlimited 
                touch  $dir/cnv_sv/manta_run_workflow_t/${sample}/manta_t.benchmark.tsv
                "

                echo "T submitted"

        fi


        if [[ "$types" == *"T"*  &&  "$types" == *"N"* ]] 
        then

                sbatch -A wp4 -p low -n20 -N 1-1 -t 24:00:00 -J tn_$sample --wrap "singularity exec --bind /beegfs-scratch,/scratch,/projects/,/data,/home,/beegfs-storage docker://hydragenetics/manta:1.6.0 /usr/local/bin/configManta.py \
                                 --tumorBam=$dir/parabricks/pbrun_fq2bam/${sample}_T.bam --normalBam=$dir/parabricks/pbrun_fq2bam/${sample}_N.bam \
                                           --referenceFasta=/beegfs-storage/data/ref_genomes/GRCh38/reference_grasnatter/homo_sapiens.fasta \
                                                      --runDir=$dir/cnv_sv/manta_run_workflow_tn/${sample}

                singularity exec --bind /projects/,/data,/home,/beegfs-storage,/beegfs-scratch,/scratch \
                docker://hydragenetics/manta:1.6.0 $dir/cnv_sv/manta_run_workflow_tn/${sample}/runWorkflow.py -j 20 -g unlimited 
                touch  $dir/cnv_sv/manta_run_workflow_tn/${sample}/manta_tn.benchmark.tsv"

                echo "TN submitted "
        fi


done 
