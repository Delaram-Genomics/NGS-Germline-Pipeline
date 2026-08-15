#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/run_alignment.sh --samplesheet FILE --reference FASTA [options]

Required:
  --samplesheet FILE  CSV with sample_id,fastq_r1,fastq_r2 columns.
  --reference FASTA   Indexed GRCh38 reference FASTA.

Options:
  --reads-dir DIR     Use <sample>_R1/R2.trimmed.fastq.gz from this directory
                      (default: qc/trimmed_fastq).
  --use-raw           Align the raw FASTQ paths from the samplesheet instead.
  --outdir DIR        Output directory (default: results/alignment).
  --threads N         Threads for BWA and samtools (default: 4).
  --dry-run           Validate inputs and print commands without running tools.
  -h, --help          Show this help message.

The default path uses reads produced by scripts/run_qc.sh. Raw-read alignment
is available for justified comparisons, but trimming is never assumed to be
beneficial without reviewing QC evidence.
EOF
}

SAMPLESHEET=""
REFERENCE=""
READS_DIR="qc/trimmed_fastq"
OUTDIR="results/alignment"
THREADS=4
USE_RAW=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --samplesheet)
            [[ $# -ge 2 ]] || die "--samplesheet requires a value"
            SAMPLESHEET="$2"
            shift 2
            ;;
        --reference)
            [[ $# -ge 2 ]] || die "--reference requires a value"
            REFERENCE="$2"
            shift 2
            ;;
        --reads-dir)
            [[ $# -ge 2 ]] || die "--reads-dir requires a value"
            READS_DIR="$2"
            shift 2
            ;;
        --use-raw)
            USE_RAW=true
            shift
            ;;
        --outdir)
            [[ $# -ge 2 ]] || die "--outdir requires a value"
            OUTDIR="$2"
            shift 2
            ;;
        --threads)
            [[ $# -ge 2 ]] || die "--threads requires a value"
            THREADS="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown argument: $1"
            ;;
    esac
done

[[ -n "${SAMPLESHEET}" ]] || die "--samplesheet is required"
[[ -n "${REFERENCE}" ]] || die "--reference is required"
[[ "${THREADS}" =~ ^[1-9][0-9]*$ ]] || die "--threads must be a positive integer"
[[ -f "${REFERENCE}" ]] || die "Reference FASTA does not exist: ${REFERENCE}"

require_command python3
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    $([[ "${USE_RAW}" == "true" ]] && printf '%s' '' || printf '%s' '--skip-file-checks')

if [[ "${DRY_RUN}" != "true" ]]; then
    require_command bwa
    require_command samtools
    for index_file in \
        "${REFERENCE}.amb" \
        "${REFERENCE}.ann" \
        "${REFERENCE}.bwt" \
        "${REFERENCE}.pac" \
        "${REFERENCE}.sa" \
        "${REFERENCE}.fai"; do
        [[ -s "${index_file}" ]] || die "Reference index missing or empty: ${index_file}"
    done
fi

BAM_DIR="${OUTDIR}/bam"
METRICS_DIR="${OUTDIR}/metrics"
LOG_DIR="${OUTDIR}/logs"
mkdir -p "${BAM_DIR}" "${METRICS_DIR}" "${LOG_DIR}"

SAMPLE_ROWS_FILE="$(mktemp "${OUTDIR}/.sample_rows.XXXXXX")"
trap 'rm -f -- "${SAMPLE_ROWS_FILE}"' EXIT
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    --skip-file-checks \
    --emit-tsv > "${SAMPLE_ROWS_FILE}"
mapfile -t SAMPLE_ROWS < "${SAMPLE_ROWS_FILE}"

log "Starting alignment for ${#SAMPLE_ROWS[@]} sample(s)."

for row in "${SAMPLE_ROWS[@]}"; do
    IFS=$'\t' read -r sample_id raw_r1 raw_r2 <<< "${row}"
    if [[ "${USE_RAW}" == "true" ]]; then
        fastq_r1="${raw_r1}"
        fastq_r2="${raw_r2}"
    else
        fastq_r1="${READS_DIR}/${sample_id}_R1.trimmed.fastq.gz"
        fastq_r2="${READS_DIR}/${sample_id}_R2.trimmed.fastq.gz"
        [[ -s "${fastq_r1}" ]] || die "Trimmed R1 not found for ${sample_id}: ${fastq_r1}"
        [[ -s "${fastq_r2}" ]] || die "Trimmed R2 not found for ${sample_id}: ${fastq_r2}"
    fi

    name_sorted="${BAM_DIR}/${sample_id}.name_sorted.bam"
    fixmate_bam="${BAM_DIR}/${sample_id}.fixmate.bam"
    coordinate_bam="${BAM_DIR}/${sample_id}.coordinate_sorted.bam"
    final_bam="${BAM_DIR}/${sample_id}.markdup.bam"
    duplicate_metrics="${METRICS_DIR}/${sample_id}.markdup.metrics.txt"
    read_group="@RG\\tID:${sample_id}\\tSM:${sample_id}\\tLB:${sample_id}.lib1\\tPL:ILLUMINA"

    log "${sample_id}: BWA-MEM alignment and name sorting"
    if [[ "${DRY_RUN}" == "true" ]]; then
        printf 'DRY-RUN: bwa mem -t %q -R %q %q %q %q | samtools sort -n -@ %q -o %q -\n' \
            "${THREADS}" "${read_group}" "${REFERENCE}" "${fastq_r1}" "${fastq_r2}" \
            "${THREADS}" "${name_sorted}"
    else
        bwa mem \
            -t "${THREADS}" \
            -R "${read_group}" \
            "${REFERENCE}" "${fastq_r1}" "${fastq_r2}" \
        | samtools sort -n -@ "${THREADS}" -o "${name_sorted}" -
    fi

    log "${sample_id}: mate-tag calculation"
    run_command samtools fixmate -m "${name_sorted}" "${fixmate_bam}"

    log "${sample_id}: coordinate sorting"
    run_command samtools sort -@ "${THREADS}" -o "${coordinate_bam}" "${fixmate_bam}"

    log "${sample_id}: duplicate marking"
    run_command samtools markdup \
        -@ "${THREADS}" \
        -s \
        -f "${duplicate_metrics}" \
        "${coordinate_bam}" "${final_bam}"

    log "${sample_id}: BAM validation, indexing and metrics"
    run_command samtools quickcheck -v "${final_bam}"
    run_command samtools index -@ "${THREADS}" "${final_bam}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        printf 'DRY-RUN: samtools flagstat -@ %q %q > %q\n' \
            "${THREADS}" "${final_bam}" "${METRICS_DIR}/${sample_id}.flagstat.txt"
        printf 'DRY-RUN: samtools stats -@ %q %q > %q\n' \
            "${THREADS}" "${final_bam}" "${METRICS_DIR}/${sample_id}.stats.txt"
    else
        samtools flagstat -@ "${THREADS}" "${final_bam}" \
            > "${METRICS_DIR}/${sample_id}.flagstat.txt"
        samtools stats -@ "${THREADS}" "${final_bam}" \
            > "${METRICS_DIR}/${sample_id}.stats.txt"
    fi

    if [[ "${DRY_RUN}" != "true" ]]; then
        rm -f -- "${name_sorted}" "${fixmate_bam}" "${coordinate_bam}"
    fi
done

if [[ "${DRY_RUN}" != "true" ]]; then
    {
        printf 'run_utc\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'bwa\t%s\n' "$(bwa 2>&1 | head -n 3 | tail -n 1)"
        printf 'samtools\t%s\n' "$(samtools --version | head -n 1)"
        printf 'reference\t%s\n' "$(realpath "${REFERENCE}")"
        printf 'reference_sha256\t%s\n' "$(sha256sum "${REFERENCE}" | cut -d ' ' -f 1)"
    } > "${LOG_DIR}/alignment_provenance.tsv"
fi

log "Alignment completed. Review metrics in ${METRICS_DIR} before variant calling."
