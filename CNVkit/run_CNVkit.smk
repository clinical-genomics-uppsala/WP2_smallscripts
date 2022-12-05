rule all:
    input:
        expand("resultsNH/{sample}/{sample}-diagram.pdf", sample=config["samples"]),
        expand("resultsNH/{sample}/{sample}.cnr", sample=config["samples"]),
        expand("resultsNH/{sample}/{sample}.cns", sample=config["samples"]),
        expand("resultsNH/{sample}/{sample}.loh.cns", sample=config["samples"]),
        expand("resultsNH/{sample}/{sample}-loh.png", sample=config["samples"]),
        expand(
            "resultsNH/{sample}/{sample}-cna-{chr}.png",
            sample=config["samples"],
            chr=["chr" + str(i) for i in range(1, 23)] + ["chrX", "chrY"],
        ),
        expand(
            "resultsNH/{sample}/{sample}.xlsx",
            sample=config["samples"],
        ),


rule cnvkit_batch:
    input:
        bam=lambda wildcards: config["samples"][wildcards.sample],
        bai=lambda wildcards: config["samples"][wildcards.sample] + ".bai",
        ref=config["pool"]["reference"],
    output:
        regions="resultsNH/{sample}/{sample}.cnr",
        segments="resultsNH/{sample}/{sample}.cns",
        segments_called="resultsNH/{sample}/{sample}.call.cns",
        bins="resultsNH/{sample}/{sample}.bintest.cns",
        target_coverage="resultsNH/{sample}/{sample}.targetcoverage.cnn",
        antitarget_coverage="resultsNH/{sample}/{sample}.antitargetcoverage.cnn",
    singularity:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py batch {input.bam} -r {input.ref} -d resultsNH/{wildcards.sample}/"


rule cnvkit_diagram:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
    output:
        pdf="resultsNH/{sample}/{sample}-diagram.pdf",
    singularity:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py diagram -s {input.cns} {input.cnr} -o {output.pdf}"


rule cnvkit_scatter:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}-b-allele-freq.png",
    singularity:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -o {output}"


rule cnvkit_call:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}.loh.cns",
    singularity:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py call {input.cns} -v {input.vcf} -o {output}"


rule cnvkit_scatter_loh:
    input:
        cns="resultsNH/{sample}/{sample}.loh.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}-loh.png",
    singularity:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -o {output}"


rule cnvkit_scatter_cna_genes:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}-cna-{chr}.png",
    singularity:
        "docker://hydragenetics/cnvkit:0.9.9"
    params:
        gene=lambda wildcards: config["CNA"][wildcards.chr],
    shell:
        """
        if [ -z {params.gene} ]
        then
        cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -c {wildcards.chr} -o {output}
        else
        cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -c {wildcards.chr} -o {output} -g {params.gene}
        fi
        """


rule vcf2excel:
    input:
        cnvkit_artefact=config["bed"]["cnvkitartefact"],
        cyto_coord_convert=config["CNV"]["cyto"],
        cnvkit_scatter="resultsNH/{sample}/{sample}-loh.png",
        cnvkit_calls="resultsNH/{sample}/{sample}.loh.cns",
        cnvkit_scatter_perchr=expand(
            "resultsNH/{{sample}}/{{sample}}-cna-{chr}.png", chr=["chr" + str(i) for i in range(1, 23)] + ["chrX", "chrY"]
        ),
    output:
        "resultsNH/{sample}/{sample}.xlsx",
    log:
        "logsNH/report/{sample}.vcf2excel.log",
    params:
        sample=lambda wildcards: wildcards.sample,
    container:
        config["singularitys"]["python"]
    script:
        "vcf2excel_cnvkit.py"
