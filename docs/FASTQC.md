# FASTQ Quality Control — FastQC

## Purpose

FastQC was used as the initial quality-control step for paired-end
Illumina sequencing data.

The analysis assessed the raw FASTQ files before downstream alignment
and variant calling.

## Input Data

- Sample: 50507404493
- Read 1: `50507404493_R1.fastq.gz`
- Read 2: `50507404493_R2.fastq.gz`
- Sequencing type: Paired-end
- Reference genome for downstream analysis: GRCh38

## FastQC

FastQC was used to assess:

- Per-base sequence quality
- Per-sequence quality scores
- Per-base sequence content
- Per-sequence GC content
- Sequence duplication levels
- Adapter contamination
- Overrepresented sequences
- Sequence length distribution

## Command

```bash
fastqc \
50507404493_R1.fastq.gz \
50507404493_R2.fastq.gz \
-o results/fastqc/