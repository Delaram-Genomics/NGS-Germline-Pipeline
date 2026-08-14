# Software and Computational Environment

## Overview

This pipeline uses established open-source bioinformatics tools for processing short-read germline sequencing data.

The software stack is designed around reproducibility, command-line execution, explicit version tracking and modular analysis.

The workflow is implemented primarily in Linux using Bash, with Python/Jupyter notebooks used for exploratory analysis, quality assessment, visualisation and downstream interpretation.

---

## Core Software

| Tool | Primary purpose | Pipeline stage |
|---|---|---|
| FastQC | Raw sequencing quality control | Quality Control |
| BWA-MEM2 | Short-read alignment | Alignment |
| SAMtools | SAM/BAM processing and quality control | BAM Processing |
| BCFtools | Variant calling and VCF manipulation | Variant Calling / Filtering |
| Ensembl VEP | Functional variant annotation | Annotation |
| Python | Data analysis and visualisation | QC / Analysis |
| Jupyter | Reproducible exploratory analysis | Analysis / Reporting |
| Git | Version control | Reproducibility |

---

## FastQC

FastQC is used to perform an initial quality assessment of raw sequencing reads.

The analysis evaluates characteristics including:

- Per-base sequence quality
- Per-sequence quality scores
- Per-base sequence content
- GC content
- Sequence duplication levels
- Adapter contamination
- Overrepresented sequences

FastQC is used as an early quality-control step before downstream processing.

---

## BWA-MEM2

BWA-MEM2 is used to align short sequencing reads against the human reference genome.

The alignment stage converts sequencing reads into genomic coordinates and produces SAM/BAM alignment data for downstream processing.

The alignment process must use a reference genome assembly that is explicitly recorded and consistent throughout the downstream workflow.

For this project, the primary reference assembly is:

**GRCh38**

---

## SAMtools

SAMtools is used for manipulation and quality control of SAM, BAM and related alignment files.

Typical operations include:

- SAM to BAM conversion
- Sorting BAM files
- Indexing BAM files
- Alignment statistics
- Read-depth and mapping-related inspection
- Extraction and filtering of alignment records

BAM files are indexed to enable efficient access to genomic regions.

---

## BCFtools

BCFtools is used for manipulation, filtering and analysis of VCF/BCF variant data.

Within this project, BCFtools is used for tasks including:

- Variant calling
- VCF inspection
- Variant filtering
- VCF compression
- VCF indexing
- Variant statistics
- Extraction of subsets of variants

The use of standard VCF/BCF-compatible tools ensures interoperability between different stages of the workflow.

---

## Ensembl Variant Effect Predictor (VEP)

Ensembl Variant Effect Predictor (VEP) is used to annotate genomic variants with predicted functional consequences.

VEP can provide information including:

- Variant consequence
- Gene
- Transcript
- HGVS nomenclature
- Protein consequence
- Transcript-level annotations
- Population allele frequencies
- Existing variant identifiers
- Phenotype and literature-associated information when appropriate resources are available

The VEP analysis in this project is performed against **GRCh38**.

The genome assembly used for annotation must match the assembly used by the upstream variant-calling workflow.

---

## Python

Python is used for downstream analysis and visualisation.

Applications include:

- Parsing tabular variant data
- Calculating summary statistics
- Exploring variant distributions
- Generating figures
- Quality-control summaries
- Creating reproducible analytical reports

Python analysis is performed using Jupyter notebooks where interactive exploration and visualisation are useful.

---

## Jupyter

Jupyter notebooks are used to document exploratory and analytical stages of the project.

Notebooks are intended to provide:

- Reproducible analysis
- Transparent data exploration
- Visualisation
- Summary statistics
- Intermediate analytical reasoning

Final production pipeline steps are implemented as command-line scripts where appropriate rather than relying exclusively on interactive notebooks.

---

## Bash

Bash is used to implement reproducible command-line pipeline steps.

Shell scripts provide:

- Explicit input and output paths
- Reproducible execution
- Parameterisation
- Error handling
- Pipeline modularity
- Integration of individual bioinformatics tools

Scripts are organised according to the major stages of the workflow.

---

## Git

Git is used for version control throughout the project.

Version control provides:

- Tracking of changes
- Reproducible project history
- Versioned analysis scripts
- Documentation history
- Recovery of previous versions
- Transparent development of the pipeline

Large sequencing datasets and generated analysis outputs are excluded from version control using `.gitignore`.

---

## Reproducibility Principles

The computational workflow follows several reproducibility principles.

### 1. Explicit software versions

Software versions should be recorded whenever possible.

### 2. Explicit reference genome

The reference assembly must be clearly defined.

### 3. Structured inputs and outputs

Each pipeline stage has defined inputs and outputs.

### 4. Version-controlled scripts

Pipeline scripts are maintained under Git version control.

### 5. Separation of raw and derived data

Raw sequencing data are kept separate from processed data and analysis outputs.

### 6. Documented parameters

Important command-line parameters should be recorded alongside the corresponding analysis.

### 7. Reproducible computational environments

Software dependencies should be managed using an isolated computational environment where possible.

---

## Reference Assembly

The primary genome assembly used by this project is:

**GRCh38**

The reference genome is stored separately from raw sequencing data and generated analysis outputs.

All downstream analyses that depend on genomic coordinates must use a compatible genome assembly.

---

## Software Version Tracking

The exact software versions used during analysis should be recorded in the project documentation and computational environment.

Example:

| Software | Version |
|---|---|
| FastQC | To be recorded |
| BWA-MEM2 | To be recorded |
| SAMtools | To be recorded |
| BCFtools | To be recorded |
| VEP | 116 |
| Python | 3.12 |
| Git | To be recorded |

Version information should be updated when the corresponding tool is installed or executed in the final environment.

---

## Production Considerations

A production genomic pipeline requires more than successful execution of individual commands.

Important considerations include:

- Reproducibility
- Traceability
- Data integrity
- Reference genome consistency
- Software version control
- Computational resource management
- Logging
- Quality control
- Error handling
- Validation
- Auditability

These principles are particularly important when genomic workflows are used in clinical or regulated environments.

---

## Future Development

Future versions of this project may incorporate:

- Workflow management using Nextflow
- Containerisation using Docker or Apptainer/Singularity
- Automated quality-control reporting
- Continuous integration testing
- Automated pipeline validation
- Configuration files
- Parameterised execution
- HPC-compatible execution
- Cloud-compatible execution
- Multi-sample joint variant calling
- Automated variant prioritisation

The objective is to progressively evolve the repository from a reproducible educational pipeline into a production-style genomic analysis workflow.