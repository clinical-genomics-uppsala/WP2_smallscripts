import statistics
import sys
from pysam import VariantFile

gvcf_files = snakemake.input.gvcfs

background_dict = {}


for file_name in gvcf_files:
    sample_name = file_name.split("/")[-1].split(".")[0] # ? {sample}_{type}
    print(sample_name)
    vcf_in = VariantFile(file_name)
    for record in vcf_in.fetch():
        #ska alla positioner med? eller bara PASS och SB?
        key = str(record.contig) + "_" + str(record.pos)
        if record.samples[sample_name]["DP"] != 0: #hogre grans? samma som mindp?
            if key in background_dict:
                # if variant higher af than X should we have opposite? 1-VF?
                background_dict[key].append(record.samples[sample_name]["VF"][0])
            else:
                background_dict[key] = [record.samples[sample_name]["VF"][0]]

# import pdb; pdb.set_trace()
with open(snakemake.output.background_file, "w+") as background_file:
    background_file.write("Chr\tPos\tMedian\tSD\tMedian+5SD\tNumSamplesSD\tMaxAF\n")
    for key in background_dict:
        background_dict[key].sort()
        nr_obs = len(background_dict[key])
        if nr_obs >= 4:
            median_background = statistics.median(background_dict[key])
            '''This is the sample variance s² with Bessel’s correction, also known as variance with N-1 degrees of freedom.
            Provided that the data points are representative (e.g. independent and identically distributed),
            the result should be an unbiased estimate of the true population variance.'''
            background_five_under = [x for x in background_dict[key] if x <= 0.05]
            stdev_background = "-"
            median_five_sd = "-"
            if len(background_five_under) >= 4:
                stdev_background = statistics.stdev(background_five_under)
                median_five_sd = median_background + 5* stdev_background
            outline = [
                    key.split("_")[0],
                    key.split("_")[1],
                    str(median_background),
                    str(stdev_background),
                    str(median_five_sd),
                    str(len(background_five_under)),
                    str(max(background_dict[key]))
                    ]
            background_file.write("\t".join(outline) + "\n")
