#!/bin/python3

import argparse
import sys
import itertools
import shutil


class DefaultList(list):
    def __copy__(self):
        return []


# Initilize parser
msg = "Script to rename wgs samples based on bioinformatic samplesheet"
parser = argparse.ArgumentParser(description=msg, formatter_class=argparse.ArgumentDefaultsHelpFormatter)
# Adding arguments
parser.add_argument(
    "-i", "--input", help="Bioinformatics samplesheet defining workpackages, experiment, analysis etc.", required=True
)
parser.add_argument("-o", "--output", help="Output ending to be added to old samples and units files", default="_old")
parser.add_argument("--samples", help="Input samples.tsv file created with hydra genetics", default="samples.tsv")
parser.add_argument("--units", help="Input units.tsv file created with hydra genetics", default="units.tsv")
parser.add_argument(
    "-w",
    "--workpackage",
    action="append",
    help="Workpackages to include in output, one flag per workpackage e.g. -w wp2 -w wp3",
    default=DefaultList(["wp2"]),
)
parser.add_argument(
    "-a",
    "--analysis",
    action="append",
    help="Analysis to include, one flag per analysis, e.g. -a hg -a tm",
    default=DefaultList(["hg"]),
)

args = parser.parse_args()

args.workpackage = [x.lower() for x in args.workpackage]
args.analysis = [x.lower() for x in args.analysis]

# Cp original samples.tsv och units.tsv to keep original
shutil.copyfile(args.samples, args.samples + args.output)
shutil.copyfile(args.units, args.units + args.output)


# Parse bioinfo samplesheet
samplesheet_dict = {}
with open(args.input, "r") as samplesheet:
    header_line = samplesheet.readline().lower().strip().split(",")
    for lline in samplesheet:
        line = lline.strip().lower().split(",")
        if line[header_line.index("workpackage")] in args.workpackage and line[header_line.index("analysis")] in args.analysis:
            samplesheet_dict[line[header_line.index("sample_id")]] = {}
            i = 0
            for column in header_line:
                if column == "description":
                    i += 1
                    for description_field in line[header_line.index("description")].split("%"):
                        samplesheet_dict[line[header_line.index("sample_id")]][description_field.split(":")[0]] = (
                            description_field.split(":")[1]
                        )
                else:
                    samplesheet_dict[line[header_line.index("sample_id")]][header_line[i]] = line[i]
                    i += 1

if len(samplesheet_dict) == 0:
    raise Exception(
        "No samples with workpackage" + ", ".join(args.workpackage) + " and analysis " + ", ".join(args.analysis) + " found."
    )


# Check that pedegree id/trio does not have two or more sex nor project ids
dup_check_dict = {}
for sample_id, sample_info in samplesheet_dict.items():
    if sample_info["trio"] not in dup_check_dict:
        dup_check_dict[sample_info["trio"]] = {}
        dup_check_dict[sample_info["trio"]]["sex"] = sample_info["sex"]
        dup_check_dict[sample_info["trio"]]["cgu-project"] = sample_info["cgu-project"]
    elif dup_check_dict[sample_info["trio"]]["sex"] != sample_info["sex"]:
        sys.exit("Same sample have two different sex " + sample_info["trio"])
    elif dup_check_dict[sample_info["trio"]]["cgu-project"] != sample_info["cgu-project"]:
        sys.exit("Same sample have two different cgu projects " + sample_info["trio"])


# samples.tsv file
with open(args.samples, "w+") as outfile:
    with open(args.samples + args.output, "r") as samples_tsv:
        outlines = []
        header_line = samples_tsv.readline().strip() + "\tproject\tsex\n"
        outfile.write(header_line)
        for lline in samples_tsv:
            line = lline.strip().lower().split("\t")
            if line[0] in samplesheet_dict.keys():
                ped_name = samplesheet_dict[line[0]]["trio"]
                tc = line[1]
                project = samplesheet_dict[line[0]]["cgu-project"]
                sex = samplesheet_dict[line[0]]["sex"]
                if sex.lower() != "m" and sex.lower() != "k" and sex.lower() != "o":
                    sys.exit("Sex is neither M|K|O for sample " + line[0])

                outlines.append([ped_name.upper(), tc, project, sex.upper()])

    # Remove duplicate rows
    outlines.sort()
    for outline in [outlines for outlines, _ in itertools.groupby(outlines)]:
        outfile.write("\t".join(outline) + "\n")


# units.tsv file
with open(args.units, "w+") as outfile:
    with open(args.units + args.output, "r") as units_tsv:
        outlines = []
        header_line = units_tsv.readline()
        outfile.write(header_line)
        for lline in units_tsv:
            line = lline.strip().split("\t")
            if line[0].lower() in samplesheet_dict.keys():  # tar bort prov icke matchande workpackage analysis
                ped_name = samplesheet_dict[line[0].lower()]["trio"]
                sample_type = samplesheet_dict[line[0].lower()]["fragestallning"]
                if sample_type == "heltranskriptom":
                    sample_type = "r"
                if sample_type != "t" and sample_type != "n" and sample_type != "r":
                    sys.exit("Sample type/fragestallning is neither t|n|r|heltranskriptom " + sample_type)
                outline = [ped_name.upper(), sample_type.upper()] + line[2:]
                outfile.write("\t".join(outline) + "\n")
