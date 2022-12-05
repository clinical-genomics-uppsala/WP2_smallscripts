#!/bin/python3.6
import sys
import csv
from pysam import VariantFile
import xlsxwriter
from datetime import date
import subprocess
import yaml
import gzip

# Define sys.argvs

today = date.today()
emptyList = ['', '', '', '', '', '']

sample_purity = 0.8
sample = snakemake.params.sample


# VEP fileds in list to get index
def index_vep(variantfile):
    csqIndex = []
    for x in variantfile.header.records:
        if 'CSQ' in str(x):
            csqIndex = str(x).split('Format: ')[1].strip().strip('">').split('|')
    return csqIndex


# Return matching lines in file
def extractMatchingLines(expressionMatch, artefactFile, grepvarible):
    if grepvarible == '':
        grepvarible = '-wE '
    cmdArt = 'grep '+grepvarible+' '+str(expressionMatch)+' '+artefactFile
    matchLines = subprocess.run(cmdArt, stdout=subprocess.PIPE, shell='TRUE').stdout.decode('utf-8').strip()
    return matchLines


def file_length(fname):
    with open(fname) as f:
        for i, l in enumerate(f):
            pass
    return i + 1


def float_or_na(value):
    return float(value) if value != '' else None


def int_or_na(value):
    return int(value) if value != '' else None


# cytocoordinates
chrBands = []
with open(snakemake.input.cyto_coord_convert, 'r') as chrBandFile:
    for line in chrBandFile:
        chrBands.append(line.split("\t"))


# Process CNVkit cns file

chromosomes = ['chr'+str(i) for i in range(1, 23)]+['chrX', 'chrY']
relevant_cnvs = {i: [] for i in chromosomes}
relevant_cnvs_header = ['Sample', 'Chromosome', 'Start', 'End', 'CytoCoordinates', 'Log2',
                        'CI high', 'CI low', 'BAF', 'Copy Number',
                        'Copies Allele 1', 'Copies Allele 2', 'Depth', 'Probes', 'Weight', 'Genes']
with open(snakemake.input.cnvkit_calls, 'r+') as cnsfile:
    cns_header = next(cnsfile).rstrip().split("\t")
    for cnv_line in cnsfile:
        cnv = cnv_line.strip().split("\t")
        if not (cnv[cns_header.index('cn')] == '2' and cnv[cns_header.index('cn1')] == '1'):
            cnv_chr = cnv[cns_header.index('chromosome')]
            cnv_start = int(cnv[cns_header.index('start')])
            cnv_end = int(cnv[cns_header.index('end')])
    #        import pdb; pdb.set_trace()
            cnv_baf = float_or_na(cnv[cns_header.index('baf')])
            cytoCoord = ['', '']
            for chrBand in chrBands:
                if chrBand[0] == cnv_chr:
                    if (cnv_start >= int(chrBand[1]) and cnv_start <= int(chrBand[2])):
                        cytoCoord[0] = chrBand[3]
                    if (cnv_end >= int(chrBand[1]) and cnv_end <= int(chrBand[2])):
                        cytoCoord[1] = chrBand[3]
            if cytoCoord[0] == cytoCoord[1]:
                cytoCoordString = cnv_chr[3:]+cytoCoord[0]
            else:
                cytoCoordString = cnv_chr[3:]+cytoCoord[0]+'-'+cytoCoord[1]
            outline = [sample, cnv_chr, cnv_start, cnv_end, cytoCoordString, float(cnv[cns_header.index('log2')]),
                       float(cnv[cns_header.index('ci_hi')]), float(cnv[cns_header.index('ci_lo')]), cnv_baf,
                       cnv[cns_header.index('cn')], int_or_na(cnv[cns_header.index('cn1')]),
                       int_or_na(cnv[cns_header.index('cn2')]), cnv[cns_header.index('depth')],
                       cnv[cns_header.index('probes')], cnv[cns_header.index('weight')], str(cnv[cns_header.index('gene')])]
            relevant_cnvs[cnv_chr].append(outline)

# XLSX Sheet
workbook = xlsxwriter.Workbook(snakemake.output[0])
worksheetCNVkit = workbook.add_worksheet('CNVkit')

# Define formats to be used.
headingFormat = workbook.add_format({'bold': True, 'font_size': 18})
lineFormat = workbook.add_format({'top': 1})
tableHeadFormat = workbook.add_format({'bold': True, 'text_wrap': True})
textwrapFormat = workbook.add_format({'text_wrap': True})
italicFormat = workbook.add_format({'italic': True})
redFormat = workbook.add_format({'font_color': 'red'})

greenFormat = workbook.add_format({'bg_color': '#85e085'})
orangeFormat = workbook.add_format({'bg_color': '#ffd280'})
green_italicFormat = workbook.add_format({'bg_color': '#85e085', 'italic': 'True'})
orange_italicFormat = workbook.add_format({'bg_color': '#ffd280', 'italic': 'True'})


# CNVkit
worksheetCNVkit.set_column('C:D', 10)
worksheetCNVkit.set_column('B:B', 12)
worksheetCNVkit.set_column('E:E', 15)

worksheetCNVkit.write('A1', 'CNVkit calls', headingFormat)
worksheetCNVkit.write('A3', 'Sample: '+str(sample))
worksheetCNVkit.write('A5', 'Only non-diploid calls or calls with allelic imbalance included')
worksheetCNVkit.write('A7', 'Variant in artefact list ', orangeFormat)

worksheetCNVkit.insert_image('A9', snakemake.input.cnvkit_scatter)

worksheetCNVkit.write_row('A31', relevant_cnvs_header, tableHeadFormat)
row = 31
col = 0
for chromosome in chromosomes:
    for line in relevant_cnvs[chromosome]:
        if len(extractMatchingLines('"' + str(line[1]) + ' ' + str(line[2]) + ' ' +
                                    str(line[3]) + ' ' + str(line[9]) + ' ' + str(line[10]) +
                                    ' ' + str(line[11]) + '"',
                                    snakemake.input.cnvkit_artefact, '-wE')) > 0:
            worksheetCNVkit.write_row(row, col, line, orangeFormat)
            row += 1
        else:
            worksheetCNVkit.write_row(row, col, line)
            row += 1


relevant_chroms = [key for key, value in relevant_cnvs.items() if value != []]
row = row+2
worksheetCNVkit.write(row, col, 'Results per chromosome with aberrant calls',
                      workbook.add_format({'bold': True, 'font_size': 14}))
row = row+1

for i in relevant_chroms:
    if i == 'chrX':
        chr_int = 22
    elif i == 'chrY':
        chr_int = 23
    else:
        chr_int = int(i.replace('chr', ''))-1
    worksheetCNVkit.write(row, col, str(i),  workbook.add_format({'bold': True, 'font_size': 14}))
    row += 1
    worksheetCNVkit.insert_image(row, col, snakemake.input.cnvkit_scatter_perchr[chr_int])
    row += 22
    worksheetCNVkit.write_row(row, col, relevant_cnvs_header, tableHeadFormat)
    row += 1
    for line in relevant_cnvs[i]:
        if len(extractMatchingLines('"' + str(line[1]) + ' ' + str(line[2]) + ' ' +
                                    str(line[3]) + ' ' + str(line[9]) + ' ' + str(line[10]) +
                                    ' ' + str(line[11]) + '"',
                                    snakemake.input.cnvkit_artefact, '-wE')) > 0:
            worksheetCNVkit.write_row(row, col, line, orangeFormat)
            row += 1
        else:
            worksheetCNVkit.write_row(row, col, line)
            row += 1
    row = row+2


workbook.close()
