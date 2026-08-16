# Beginner installation guide for Ubuntu/WSL

This guide prepares a local Linux environment. Do not use confidential patient
data. Start with public GIAB benchmark data after the test profile is complete.

## 1. Open Ubuntu

On Windows, open the **Ubuntu** application installed through WSL. Commands in
this guide are typed into that terminal one line at a time.

## 2. Confirm basic tools

```bash
java -version
git --version
```

Nextflow requires Java. Use a currently supported LTS Java release; Java 17 or
21 is appropriate for the planned Nextflow version.

## 3. Install Miniforge

Use the official Miniforge installer appropriate for the computer architecture,
then close and reopen Ubuntu. Confirm installation:

```bash
conda --version
```

Do not paste installation commands from untrusted websites. Verify the official
source and checksum before running a downloaded installer.

## 4. Create the software environment

From the repository directory:

```bash
conda env create -f environment.yml
conda activate ngs_pipeline
```

Confirm the core tools:

```bash
fastqc --version
fastp --version
multiqc --version
bwa 2>&1 | head
samtools --version | head -1
gatk --version
bcftools --version | head -1
```

`hap.py` is intentionally not installed in this environment because its
current Bioconda package requires a legacy Python 2.7 runtime. Create the
separate benchmark environment only when running GIAB comparisons:

```bash
mamba env create -f environment-benchmark.yml
```

Do not add Python 2.7 to the main analysis environment.

VEP is also isolated because it has a large Perl dependency stack. Install the
versioned annotation environment separately:

```bash
mamba env create -f environment-annotation.yml
conda activate ngs_annotation
vep --help | head -1
```

The workflow uses this environment automatically for the annotation process
when the Nextflow `conda` profile is enabled.

## 5. Confirm Nextflow

The Conda environment declares Nextflow. Confirm it is available:

```bash
nextflow -version
```

The repository requires Nextflow `24.10.0` or newer.

## 6. Prepare configuration

```bash
cp config/samplesheet.example.csv samplesheet.csv
cp config/pipeline.env.example pipeline.env
```

`samplesheet.csv` and `pipeline.env` are ignored by Git. Replace example paths
with approved public data and matching GRCh38 resources. Never add patient
identifiers or patient-data paths.

## 7. Preview individual stages

Each script supports `--dry-run`. For example:

```bash
scripts/run_qc.sh --samplesheet samplesheet.csv --dry-run
```

Dry-run validates the declared files and prints commands. It does not prove the
external tools or reference resources are correct.

## 8. Run with Nextflow

```bash
nextflow run main.nf \
  -profile conda \
  --samplesheet samplesheet.csv \
  --reference /path/to/GRCh38.fa \
  --intervals /path/to/exome_targets.interval_list \
  --vep_cache_dir /path/to/vep_cache \
  --vep_cache_version 113 \
  --outdir results
```

Use the VEP cache version actually installed; `113` is an example.

## 9. Resume an interrupted run

If the inputs, parameters and code are unchanged:

```bash
nextflow run main.nf [the same parameters] -resume
```

Nextflow reuses completed cached tasks. Changing an input, command or relevant
parameter may correctly cause a task to run again.

## 10. Check outputs

Review:

```text
results/qc/
results/alignment/
results/variants/
results/annotation/
results/pipeline_info/
```

The execution report, trace, timeline and DAG in `pipeline_info` are part of
the reproducibility evidence.

## Common beginner errors

| Message | Meaning | First check |
| --- | --- | --- |
| `command not found` | Tool is unavailable in the active environment | `conda activate ngs_pipeline` |
| `No such file` | A supplied path is wrong | `ls -lh /exact/path` |
| reference index missing | FASTA sidecar files were not prepared | Confirm `.fai`, `.dict` and BWA indexes |
| process terminated with 137 | Operating system killed it, often for memory | Check execution report and available RAM |
| VEP cache missing | Cache path/version does not match installation | Inspect cache directory and release |

Never solve a permissions error by making sensitive genomic files world-
writable. Ask the data owner or system administrator for the correct access.
