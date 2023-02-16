import typing
import pandas as pd
import snakemake
### Read samples and unit file

samples = pd.read_table(config["samples"], dtype=str).set_index("sample", drop=False)
units = pd.read_table(config["units"], dtype=str).set_index(["sample", "type"], drop=False).sort_index()
localrules: calculate_background_pisces_gvcf

rule all:
    input:
        "background_file_230215.tsv"


rule calculate_background_pisces_gvcf:
    input:
        gvcfs=expand("snv_indels/pisces/{sample}_T.normalized.sorted.vcf.gz", sample=[sample.Index for sample in samples.itertuples()]),
    output:
        background_file="background_file_230215.tsv",
    log:
        "background_file_230215.tsv.log"
    threads: 1
    container:
        "docker://hydragenetics/common:0.1.5"
    script:
        "scripts/calculate_background_pisces_gvcf.py"
