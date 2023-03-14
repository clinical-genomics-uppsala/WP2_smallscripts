rule all:
    input:
        expand("resultsNH/{sample}/{sample}-diagram.pdf", sample=config["bams"]),
        expand("resultsNH/{sample}/{sample}.cnr", sample=config["bams"]),
        expand("resultsNH/{sample}/{sample}.cns", sample=config["bams"]),
        expand("resultsNH/{sample}/{sample}.loh.cns", sample=config["bams"]),
        expand("resultsNH/{sample}/{sample}-loh.png", sample=config["bams"]),
        expand(
            "resultsNH/{sample}/{sample}-cna-{chr}.png",
            sample=config["bams"],
            chr=["chr" + str(i) for i in range(1, 23)] + ["chrX", "chrY"],
        ),
        expand("resultsNH/{sample}/{sample}.xlsx", sample=config["bams"]),


rule cnvkit_batch:
    input:
        bam=lambda wildcards: config["bams"][wildcards.sample],
        bai=lambda wildcards: config["bams"][wildcards.sample] + ".bai",
        ref=config["cnvkit_batch"]["normalpool"],
    output:
        regions="resultsNH/{sample}/{sample}.cnr",
        segments="resultsNH/{sample}/{sample}.cns",
        segments_called="resultsNH/{sample}/{sample}.call.cns",
        bins="resultsNH/{sample}/{sample}.bintest.cns",
        target_coverage="resultsNH/{sample}/{sample}.targetcoverage.cnn",
        antitarget_coverage="resultsNH/{sample}/{sample}.antitargetcoverage.cnn",
    params:
        extra=config.get("cnvkit_batch", {}).get("extra", "")
    container:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py batch {input.bam} -r {input.ref} -d resultsNH/{wildcards.sample}/ {params.extra}"


rule cnvkit_diagram:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
    output:
        pdf="resultsNH/{sample}/{sample}-diagram.pdf",
    params:
        extra=config.get("cnvkit_diagram", {}).get("extra", "")
    container:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py diagram -s {input.cns} {input.cnr} -o {output.pdf} {params.extra}"


rule cnvkit_scatter:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}-b-allele-freq.png",
    params:
        extra=config.get("cnvkit_scatter", {}).get("extra", "")
    container:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -o {output} {params.extra}"


rule cnvkit_call:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}.loh.cns",
    params:
        tc=lambda wildcards: config.get("cnvkit_call", {}).get("tc", {}).get(wildcards.sample, ""),
        extra=config.get("cnvkit_call", {}).get("extra", "")
    container:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        """
        if [ -z {params.tc} ]
        then
        cnvkit.py call {input.cns} -v {input.vcf} -o {output} {params.extra}
        else
        cnvkit.py call {input.cns} -v {input.vcf}  --purity {params.tc} -o {output} {params.extra}
        fi
        """

rule cnvkit_scatter_loh:
    input:
        cns="resultsNH/{sample}/{sample}.loh.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}-loh.png",
    params:
        extra=config.get("cnvkit_scatter_loh", {}).get("extra", "")
    container:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        "cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -o {output} {params.extra}"


rule cnvkit_scatter_cna_genes:
    input:
        cns="resultsNH/{sample}/{sample}.cns",
        cnr="resultsNH/{sample}/{sample}.cnr",
        vcf=lambda wildcards: config["vcf"][wildcards.sample],
    output:
        "resultsNH/{sample}/{sample}-cna-{chr}.png",
    params:
        gene=lambda wildcards: config.get("cnv_scatter_cna_genes", {}).get("cna", {}).get(wildcards.chr, ""),
        extra=config.get("cnvkit_scatter_cna_genes", {}).get("extra", ""),
    container:
        "docker://hydragenetics/cnvkit:0.9.9"
    shell:
        """
        if [ -z {params.gene} ]
        then
        cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -c {wildcards.chr} -o {output} {params.extra}
        else
        cnvkit.py scatter -s {input.cns} {input.cnr} -v {input.vcf} -c {wildcards.chr} -o {output} -g {params.gene} {params.extra}
        fi
        """


rule vcf2excel:
    input:
        cnvkit_artefact=config["vcf2excel"]["cnvkitartefact"],
        cyto_coord_convert=config["vcf2excel"]["cyto"],
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
        "/projects/wp2/nobackup/Twist_Myeloid/Containers/python3.6-pysam-xlsxwriter-yaml.simg"
    script:
        "vcf2excel_cnvkit.py"
