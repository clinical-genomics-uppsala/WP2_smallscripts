#!/bin/python3

import sys
import itertools

samples_file = sys.argv[1]
units_file = sys.argv[2]
samplesheet_file = sys.argv[3]

header_row = "Sample_ID,Sample_Name,Description,I7_Index_ID,index,I5_Index_ID,index2,Sample_Project\n"
header_row_split = header_row.strip().split(",")


def test_samplesheet_line(samplesheet_line):
    # length of Description
    if len(samplesheet_line[2].split("_")) != 5:
        sys.exit("Description field not 5 types for "+"\t".join(samplesheet_line))
    # type
    cell_type = samplesheet_line[2].split("_")[0]
    if cell_type.lower() != "t" and cell_type.lower() != "n" and cell_type.lower() != "heltranskriptom"
    and cell_type.lower() != "r":
        sys.exit("Cell type is neither T|N|Heltranskriptom for sample " + samplesheet_line[0])
    # sex
    sex = line[2].split("_")[1]
    if sex.upper() != "M" and sex.upper() != "F" and sex.upper() != "O" and sex.upper() != "NA":
        sys.exit("Sex is neither M|F|O for sample " + samplesheet_line[0])
    return True


samples = {}
header = False
with open(samplesheet_file, 'r') as samplesheet:
    for lline in samplesheet:
        if len(lline.split()) == 0:  # skip blank lines
            continue
        if header:
            line = lline.strip().split(",")
            if line[7] == "WGSWP2" and test_samplesheet_line(line):
                samples[line[0]] = {
                                        header_row_split[1]: line[1],
                                        "Type": line[2].split("_")[0],
                                        "Sex": line[2].split("_")[1],
                                        "Pedegree_id": line[2].split("_")[2],
                                        "Seq_run": line[2].split("_")[3],
                                        "Project": line[2].split("_")[4],
                                        header_row_split[3]: line[3],
                                        header_row_split[4]: line[4],
                                        header_row_split[5]: line[5],
                                        header_row_split[6]: line[6],
                                        header_row_split[7]: line[7],
                                    }
        if lline == header_row:
            header = True


if len(samples) == 0:
    raise Exception("No samples found, has the header in SampleSheet changed?")


# Check that the same Pedegree_id do not have two or more different sex nor project ids
ped_sex_dict = {}
ped_project_dict = {}
for sample_id, sample_info in samples.items():
    if sample_info["Pedegree_id"] not in ped_sex_dict.keys():
        ped_sex_dict[sample_info["Pedegree_id"]] = sample_info["Sex"]
    elif ped_sex_dict[sample_info["Pedegree_id"]] != sample_info["Sex"]:
        sys.exit("Same sample have two different sex " + sample_info["Pedegree_id"])

    if sample_info["Pedegree_id"] not in ped_project_dict.keys():
        ped_project_dict[sample_info["Pedegree_id"]] = sample_info["Project"]
    elif ped_project_dict[sample_info["Pedegree_id"]] != sample_info["Project"]:
        sys.exit("Same sample have two different projects " + sample_info["Pedegree_id"])


with open(samples_file.split(".")[0] + "_ped.tsv", 'w+') as out_samples:
    with open(samples_file, 'r') as samples_tsv:
        header = True
        outlines = []
        for lline in samples_tsv:
            if header:
                out_samples.write(lline.strip() + "\tproject\tsex\n")
                header = False
            else:
                line = lline.strip().split("\t")
                ped_name = samples[line[0]]["Pedegree_id"]
                tumor_content = line[1]
                project = samples[line[0]]["Project"]
                sex = samples[line[0]]["Sex"]

                outlines.append([ped_name.upper(), tumor_content, project, sex])

    outlines.sort()
    for outline in [outlines for outlines, _ in itertools.groupby(outlines)]:
        out_samples.write("\t".join(outline)+"\n")


with open(units_file.split(".")[0]+"_ped.tsv", "w+") as out_units:
    with open(units_file, 'r') as units_tsv:
        header = True
        for lline in units_tsv:
            if header:
                out_units.write(lline)
                header = False
            else:
                line = lline.strip().split("\t")
                ped_name = samples[line[0]]["Pedegree_id"]
                cell_type = samples[line[0]]["Type"]
                if cell_type.lower() == "heltranskriptom" or cell_type.lower() == "r":
                    cell_type = "R"
                outline = [ped_name.upper(), cell_type.upper()]+line[2:]
                out_units.write("\t".join(outline)+"\n")
