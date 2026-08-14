#!/usr/bin/env bash

set -euo pipefail

#############################################
# Germline NGS Pipeline
# Step 1: Raw FASTQ Quality Control
# Tool: FastQC
#############################################

# -----------------------------
# Input / Output directories
# -----------------------------

RAW_DIR="raw_fastq"
QC_DIR="qc/fastqc"

# -----------------------------
# Create output directory
# -----------------------------

mkdir -p "${QC_DIR}"

# -----------------------------
# Check that input directory exists
# -----------------------------

if [[ ! -d "${RAW_DIR}" ]]; then
    echo "ERROR: Input directory '${RAW_DIR}' does not exist."
    exit 1
fi

# -----------------------------
# Check that FASTQ files exist
# -----------------------------

FASTQ_FILES=("${RAW_DIR}"/*.fastq.gz)

if [[ ! -e "${FASTQ_FILES[0]}" ]]; then
    echo "ERROR: No .fastq.gz files found in '${RAW_DIR}'."
    exit 1
fi

# -----------------------------
# Display analysis information
# -----------------------------

echo "=============================================="
echo "Germline NGS Pipeline"
echo "Step 1: FastQC"
echo "=============================================="
echo "Input directory : ${RAW_DIR}"
echo "Output directory: ${QC_DIR}"
echo "Number of FASTQ files: ${#FASTQ_FILES[@]}"
echo "=============================================="

# -----------------------------
# Run FastQC
# -----------------------------

fastqc \
    --threads 4 \
    --outdir "${QC_DIR}" \
    "${FASTQ_FILES[@]}"

# -----------------------------
# Completion message
# -----------------------------

echo "=============================================="
echo "FastQC completed successfully."
echo "Results written to: ${QC_DIR}"
echo "=============================================="
