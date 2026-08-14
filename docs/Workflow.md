# Germline Variant Calling Workflow

## Overview

This repository demonstrates a complete germline short-read variant calling workflow following modern bioinformatics practices commonly used in UK genomics laboratories.

The pipeline begins with paired-end Illumina FASTQ files and progresses through quality assessment, preprocessing, alignment, variant calling, annotation and downstream interpretation.

The primary objective is to understand every analytical step rather than simply executing software commands.

---

## Pipeline Overview

```
Patient DNA
      │
      ▼
Library Preparation
      │
      ▼
Illumina Sequencing
      │
      ▼
FASTQ Files
      │
      ▼
Quality Control
      │
      ▼
Read Trimming
      │
      ▼
Alignment
      │
      ▼
SAM
      │
      ▼
Sorted BAM
      │
      ▼
Duplicate Marking
      │
      ▼
BAM Indexing
      │
      ▼
Variant Calling
      │
      ▼
VCF
      │
      ▼
Variant Filtering
      │
      ▼
Variant Annotation
      │
      ▼
Variant Prioritization
      │
      ▼
Clinical Interpretation
```

---

## Pipeline Stages

| Stage                   | Objective                                                 |
| ----------------------- | --------------------------------------------------------- |
| Quality Control         | Evaluate sequencing quality before analysis               |
| Read Trimming           | Remove adapters and low-quality bases                     |
| Alignment               | Map sequencing reads to the human reference genome        |
| BAM Processing          | Sort, index and optimize alignment files                  |
| Variant Calling         | Detect SNVs and small insertions/deletions                |
| Variant Filtering       | Remove low-confidence variant calls                       |
| Variant Annotation      | Add biological and clinical information                   |
| Variant Prioritization  | Identify potentially clinically relevant variants         |
| Clinical Interpretation | Assess variant pathogenicity using established guidelines |
