#!/bin/python3

import sys

detected_variants_file = sys.argv[1]
outfilebase = sys.argv[2]

# genes of interest (make sure name match VEP annotation)
genes = ['ARHGEF10', 'ARID2', 'ASXL2', 'BCL10', 'BCL11B', 'BRCC3', 'BTG1', 'CCND3', 'CDKN1B', 'CDKN2B', 'CDKN2C', 'CHD4', 'CNOT3',
         'CREBBP', 'CRLF2', 'CSF1R', 'CSF2RB', 'CTNNB1', 'DCC', 'DDX23', 'DDX3X', 'DDX4', 'DDX54', 'DHX15', 'DHX33', 'DICER1',
         'DNM2', 'DNMT3B', 'EBF1', 'EED', 'EGFR', 'FAM175A', 'FGFR2', 'GFI1', 'GIGYF2', 'GNB1', 'H3F3A', 'H3F3B', 'HIPK2', 'IL7R',
         'INO80', 'IRF4', 'IRF8', 'JARID2', 'KDM5C', 'KMT2D', 'LEF1', 'LUC7L2', 'MED12', 'MGA', 'MYB', 'MYC', 'MYCN', 'NF2',
         'NFE2L2', 'NIPBL', 'NOTCH2', 'NT5C2', 'NSD2', 'NXF1', 'PHIP', 'PIK3CA', 'PIK3CD', 'PIK3R1', 'PRPF40A', 'PRPF40B',
         'PTPRF', 'RAC1', 'RAD50', 'RAD51', 'RASGRF1', 'RHOA', 'RIT1', 'RPL10', 'RPL22', 'RPL5', 'RRAS', 'SAMHD1', 'SETDB1',
         'SF1', 'SF3A1', 'SMARCA4', 'SMG1', 'SPRED2', 'SRCAP', 'STAT5A', 'SUZ12', 'TBL1XR1', 'TOX', 'TRRAP', 'U2AF2', 'UBA2',
         'USH2A', 'USP7', 'USP9X', 'YLPM1', 'ZBTB7A', 'ZEB2', 'ZMYM3']


header = ['Clinical Significance', 'Gene', 'Chr', 'Pos', 'Ref', 'Alt', 'Transcript', 'cDNA', 'ENSP', 'Consequence',
          'COSMIC id on position', 'dbSNP', 'Max PopAF', 'Max Pop', 'Samples', 'AFs', 'DPs']

pathogenic = {}
vus = {}
with open(detected_variants_file, 'r') as detected_variants:
    for line in detected_variants:
        row = line.split("\t")
        if 'HD829' not in row[1]:
            chr = row[3]
            pos = row[4]
            sample = row[1]+'_'+row[0]
            if row[2] in genes:
                tablerow = [row[15], row[2], chr, pos, row[5], row[6], row[9], row[10], row[11], row[12], row[13], row[16],
                            row[17], row[18], sample, row[7], row[8]]
                if any(item in row[15].split("&") for item in ['pathogenic', 'likely_pathogenic',
                                                               'conflicting_interpretations_of_pathogenicity']):
                    pathogenic.setdefault(chr+'_'+pos, []).append(tablerow)
                elif any(item in row[15].split("&") for item in ['drug_response', 'risk_factor', 'uncertain_significance',
                                                                 'not_provided', 'affects']):
                    vus.setdefault(chr+'_'+pos, []).append(tablerow)

# Remove duplicate rows from pathogenic
rows = []
samples = []
afs = []
dps = []

for chr_pos_dup in pathogenic.values():
    chr_pos = []
    for x in chr_pos_dup:
        if x not in chr_pos:
            chr_pos.append(x)

    for chr_pos_line in chr_pos:
        added = False
        for x in range(0, len(rows)):
            if chr_pos_line[0:14] == rows[x]:
                samples[x].append(chr_pos_line[14])
                afs[x].append(chr_pos_line[15])
                dps[x].append(chr_pos_line[16])
                added = True
                break
        if not added:
            rows.append(chr_pos_line[0:14])
            samples.append([chr_pos_line[14]])
            afs.append([chr_pos_line[15]])
            dps.append([chr_pos_line[16]])

# write pathogenic outfile
with open(outfilebase+'.pathogenic.txt', 'w+') as outfile:
    outfile.write("\t".join(header)+'\n')
    for i in range(0, len(rows)):
        outline = rows[i]+[";".join(samples[i])]+[";".join(afs[i])]+[";".join(dps[i])]
        outfile.write("\t".join(outline)+'\n')


# Remove duplicate rows from vus
rows = []
samples = []
afs = []
dps = []

for chr_pos_dup in vus.values():
    chr_pos = []
    for x in chr_pos_dup:
        if x not in chr_pos:
            chr_pos.append(x)

    for chr_pos_line in chr_pos:
        added = False
        for x in range(0, len(rows)):
            if chr_pos_line[0:14] == rows[x]:
                samples[x].append(chr_pos_line[14])
                afs[x].append(chr_pos_line[15])
                dps[x].append(chr_pos_line[16])
                added = True
                break
        if not added:
            rows.append(chr_pos_line[0:14])
            samples.append([chr_pos_line[14]])
            afs.append([chr_pos_line[15]])
            dps.append([chr_pos_line[16]])

# write vus outfile
with open(outfilebase+'.vus.txt', 'w+') as outfile:
    outfile.write("\t".join(header)+'\n')
    for i in range(0, len(rows)):
        outline = rows[i]+[";".join(samples[i])]+[";".join(afs[i])]+[";".join(dps[i])]
        outfile.write("\t".join(outline)+'\n')
