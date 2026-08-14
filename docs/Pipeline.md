# Germline Variant Analysis Pipeline

## Overview

This repository presents a complete end-to-end germline short-read variant analysis pipeline designed to follow modern bioinformatics practices used in UK clinical genomics laboratories and research institutions.

The objective of this project is not only to perform variant calling but also to demonstrate reproducible, well-documented and production-style bioinformatics workflows.

The pipeline follows the complete journey of sequencing data beginning with raw Illumina FASTQ files and ending with biologically meaningful and clinically interpretable genomic variants.

Throughout the workflow, internationally recognised bioinformatics software is used together with reproducible Linux command-line analysis.

---

## Pipeline Architecture

The workflow follows the order below:

1. Raw sequencing data (FASTQ)

2. Quality assessment

3. Reference genome preparation

4. Read alignment

5. BAM processing

6. Variant calling

7. Variant filtering

8. Functional annotation

9. Variant prioritisation

10. Clinical interpretation

Each stage produces an output that becomes the input for the following step, creating a fully reproducible analysis pipeline.

---

## Input Data

The pipeline begins with paired-end Illumina sequencing data stored in compressed FASTQ format.

Each FASTQ file contains millions of sequencing reads together with their corresponding Phred quality scores.

Typical input consists of:

- Sample_R1.fastq.gz

- Sample_R2.fastq.gz

where

R1 contains Forward Reads

R2 contains Reverse Reads

These paired reads originate from opposite ends of the same DNA fragment, allowing accurate alignment against the human reference genome.

