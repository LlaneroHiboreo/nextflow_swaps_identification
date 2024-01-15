#!/bin/bash

nextflow run main.nf \
-profile singularity \
--tools crosscheckfingerprints,somalier \
--input /path/to/assets/samplesheet.csv \
--outdir results \
--fasta /path/to/reference.fasta \
--fai /path/to/reference.fasta.fai \
--sites /path/to/SOMALIER/sites.hg38.vcf.gz \
--haplomap /path/to/haplotypemap/haplotype_map.txt