#!/bin/bash

#  Prerequisite:  
#    1. Install all dependent packages via `uv sync`
#    2. activate the virtual environment by `source .venv/bin/activate`
#  After this, the python program will be called from the virtual environment where the dependent python packages were installed in.

######################################
# 0. Setup data directories
######################################
# Please unzip the dataset in the same directory as scSplit.
# DATASET=TestData4PipelineSmall
# BAM="${DATASET}/test_dataset/outs/pooled.sorted.bam"
DATASET=TestData4PipelineFull
BAM="${DATASET}/test_dataset/possorted_genome_bam.bam"
BARCODES="${DATASET}/test_dataset/outs/filtered_gene_bc_matrices/Homo_sapiens_GRCh38p10/barcodes.tsv"
SCSPLIT_OUTDIR="${DATASET}/output"
# Use the Emsembl format FASTA
FASTA="Homo_sapiens.GRCh38.dna.primary_assembly.fa"
# N obtained from ${DATASET}/samplesheet.txt
N=14
# optional
VCF="${DATASET}/test_dataset.vcf"

# Make sure output directory exists
mkdir -p ${SCSPLIT_OUTDIR}


# Check if the BAM file is in Emsembl style
# if it is like the following it is Emsembl style
#  @SQ	SN:1	LN:248956422
# And download the FASTA data from
#     http://ftp.ensembl.org/pub/release-110/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna.primary_assembly.fa.gz
# Otherwise if it is like SN:chr1, SN:chr2, then it is the UCSC/10x Style. The downloading URL is
#     https://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz
samtools view -H "${BAM}" | grep "@SQ"  | head -5


###############################################
# 1. Prepare BAM file
###############################################
echo "Preparing BAM file..."

# Filter BAM: keep mapped reads (quality > 10), remove duplicates/failed/secondary alignments
# -F 3844 filters out: unmapped (4), secondary (256), QC failed (512), optical/PCR duplicates (1024), supplementary (2048)
samtools view -b -S -q 10 -F 3844 "${BAM}" > "${SCSPLIT_OUTDIR}/filtered_bam.bam"

# Remove duplicates (using rmdup as per tutorial, though markdup is preferred in newer pipelines)
samtools rmdup "${SCSPLIT_OUTDIR}/filtered_bam.bam" "${SCSPLIT_OUTDIR}/filtered_bam_dedup.bam"

# Sort the BAM file
samtools sort -o "${SCSPLIT_OUTDIR}/filtered_bam_dedup_sorted.bam" "${SCSPLIT_OUTDIR}/filtered_bam_dedup.bam"

# Index the sorted BAM
samtools index "${SCSPLIT_OUTDIR}/filtered_bam_dedup_sorted.bam"

echo "BAM preparation complete."

###############################################
# 2. Call Sample SNVs (Freebayes)
###############################################
echo "Calling SNVs with Freebayes..."

# Run Freebayes
# -f: reference genome
# -i -X -u: ignore indels/MNPs/complex events (scSplit only needs SNPs)
# -C 2: min alternate count 2
# -q 1: min base quality 1

# Serial version
#freebayes -f "$FASTA" -i -X -u -C 2 -q 1 "${SCSPLIT_OUTDIR}/filtered_bam_dedup_sorted.bam" > "${SCSPLIT_OUTDIR}/freebayes_var.vcf"

# Parallel version: freebayes-parallel is not available on macOS. Below is a workaround.
python3 fasta_generate_regions.py "${FASTA}.fai" 1000000 | \
parallel -j 10 --bar \
"freebayes -f $FASTA -r {} -i -X -u -C 2 -q 1 ${SCSPLIT_OUTDIR}/filtered_bam_dedup_sorted.bam > ${SCSPLIT_OUTDIR}/temp_vcfs_chunk_{#}.vcf"

# Merge temp files
bcftools concat -o "${SCSPLIT_OUTDIR}/freebayes_var.vcf" ${SCSPLIT_OUTDIR}/temp_vcfs_chunk_*.vcf

# Clean up temporary files
rm -rf "${SCSPLIT_OUTDIR}/temp_vcfs_chunk_*.vcf"

# Filter VCF (keep only quality > 30)
vcftools --vcf "${SCSPLIT_OUTDIR}/freebayes_var.vcf" --minQ 30 --recode --recode-INFO-all --out "${SCSPLIT_OUTDIR}/freebayes_var_qual30"

###############################################
# 3. Demultiplexing with scSplit
###############################################
echo "Running scSplit count..."


# 1. Count reads
# NOTE: This is a correction to the command from the website:
#  -o <OUT_DIRECTORY>: specifies the output directory.
#  -r <REF_FILE> and -a <ALT_FILE> specify the file names only without the directory.
# The final file names are `<OUT_DIRECTORY>/<REF_FILE>` and `<OUT_DIRECTORY/ALT_FILE>`, respectively.
python scSplit count \
    -c $VCF \
    -v "${SCSPLIT_OUTDIR}/freebayes_var_qual30.recode.vcf" \
    -i "${SCSPLIT_OUTDIR}/filtered_bam_dedup_sorted.bam" \
    -b "${BARCODES}" \
    ${CELL_TAG:+-t $CELL_TAG} \
    -o "${SCSPLIT_OUTDIR}" \
    -r ref_filtered.csv \
    -a alt_filtered.csv

echo "Running scSplit run..."

# 2. Run the EM algorithm (Demultiplexing)
# Uses the CSV matrices generated in the step above
python scSplit run \
    -r "${SCSPLIT_OUTDIR}/ref_filtered.csv" \
    -a "${SCSPLIT_OUTDIR}/alt_filtered.csv" \
    -n ${N} \
    -o "${SCSPLIT_OUTDIR}"

echo "Running scSplit genotype..."

# 3. Genotype the clusters
# Uses the probability file "scSplit_P_s_c.csv" generated in the 'run' step above
python scSplit genotype \
    -r "${SCSPLIT_OUTDIR}/ref_filtered.csv" \
    -a "${SCSPLIT_OUTDIR}/alt_filtered.csv" \
    -p "${SCSPLIT_OUTDIR}/scSplit_P_s_c.csv" \
    -o "${SCSPLIT_OUTDIR}"

echo "Demultiplexing complete."
