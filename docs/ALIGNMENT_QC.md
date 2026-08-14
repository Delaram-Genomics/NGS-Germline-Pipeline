# Read Alignment using BWA-MEM

## Objective

The purpose of alignment is to map sequencing reads to the human reference genome (GRCh38).

Alignment determines the genomic origin of each read and creates the foundation for downstream variant calling.

---

## Tool

BWA-MEM

Version: 0.7+

Reference genome:

GRCh38

---

## Input

Paired-end FASTQ files

Example:

50507404493_R1.fastq.gz

50507404493_R2.fastq.gz

---

## Alignment Command

```bash
bwa mem \
-t 8 \
reference.fa \
R1.fastq.gz \
R2.fastq.gz \
> sample.sam
```
# Alignment Quality Control

## Objective

Assess alignment quality after mapping paired-end sequencing reads to the GRCh38 human reference genome.

---

## Software

* BWA-MEM
* SAMtools v1.22.1

---

## Input

Paired-end FASTQ files:

* 50507404493_R1.fastq.gz
* 50507404493_R2.fastq.gz

Reference genome:

* GRCh38

---

## Workflow

### Alignment

Reads were aligned to the GRCh38 reference genome using BWA-MEM.

### BAM Processing

The SAM file was converted to BAM format.

The BAM file was then sorted and indexed using SAMtools.

### Alignment Statistics

Alignment statistics were generated using:

samtools flagstat

---

## Results

Total reads:

84,325,497

Mapped reads:

84,321,684

Mapping rate:

100.00%

Properly paired reads:

84,079,740

Properly paired percentage:

99.82%

Reads mapped to different chromosomes:

107,056

Reads mapped to different chromosomes (MAPQ ≥ 5):

95,660

---

## Interpretation

The alignment demonstrates excellent mapping performance.

Key observations:

* Nearly all reads mapped successfully to the reference genome.
* Proper pairing exceeded 99%.
* Low singleton rate.
* Alignment quality is suitable for downstream variant calling and annotation analyses.

---

## Conclusion

The alignment step passed quality assessment and the BAM file is suitable for germline variant analysis.
