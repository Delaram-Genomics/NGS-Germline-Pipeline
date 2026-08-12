# NGS Germline Variant Analysis Pipeline

## Overview

This repository documents the development of a reproducible germline variant analysis workflow using industry-standard next-generation sequencing (NGS) tools.

The project follows a typical human whole-genome / exome analysis workflow used in genomics research, clinical genomics laboratories and biotechnology companies.

The workflow includes:

* Raw FASTQ quality assessment
* Read alignment to GRCh38
* BAM processing and QC
* Variant calling
* Variant annotation using Ensembl VEP
* Variant prioritisation
* Reproducible workflow documentation

---

## Technologies

### Bioinformatics

* FastQC
* MultiQC
* BWA-MEM
* SAMtools
* BCFtools
* Ensembl VEP

### Computing

* Linux (Ubuntu WSL)
* Bash
* Git
* GitHub
* VS Code
* Jupyter Lab

---

## Pipeline Structure

FASTQ

↓

FastQC

↓

MultiQC

↓

BWA-MEM Alignment

↓

SAM → BAM Conversion

↓

BAM Sorting

↓

BAM Indexing

↓

Alignment QC

↓

Variant Calling

↓

VCF Processing

↓

Variant Annotation (VEP)

↓

Variant Prioritisation

---

## Reference Genome

Human Genome Reference Consortium Build 38 (GRCh38)

---

## Repository Structure

docs/

scripts/

config/

workflows/

results/

environment/

---

## Current Progress

* [x] Linux environment setup
* [x] Reference genome preparation
* [x] BWA indexing
* [x] FASTQ processing
* [x] Read alignment
* [x] BAM generation
* [x] BAM sorting
* [x] BAM indexing
* [x] Alignment statistics
* [x] VEP installation
* [ ] FastQC report integration
* [ ] MultiQC report generation
* [ ] Variant calling workflow
* [ ] Variant annotation workflow
* [ ] Clinical variant prioritisation

---
## Learning Portfolio

This repository is being developed as part of my transition into Bioinformatics and Genomics Analysis.

The project documents the practical implementation of a complete germline variant analysis workflow using real sequencing data and industry-standard tools commonly used across genomics laboratories, research institutes and biotechnology companies.

Each pipeline step is documented individually within the docs directory, including:

- Scientific rationale
- Linux commands
- Quality control interpretation
- Expected outputs
- Industry best practices

## Author

Delaram Sherkatghannad

MSc Human and Molecular Genetics

University of Sheffield
