#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/run_qc.sh --samplesheet FILE [--outdir DIR] [--threads N] [--dry-run]

Required:
  --samplesheet FILE  CSV with sample_id,fastq_r1,fastq_r2 columns.

Options:
  --outdir DIR       Output directory (default: qc)
  --threads N        Threads per tool (default: 4)
  --dry-run          Validate inputs and print commands without executing tools.
  -h, --help         Show this help message.

Outputs:
  raw_fastqc/        FastQC reports before trimming
  trimmed_fastq/     Paired reads produced by fastp
  fastp/             fastp HTML and JSON reports
  trimmed_fastqc/    FastQC reports after trimming
  multiqc/           Combined MultiQC report and data
  logs/              Tool versions and run metadata
EOF
}

SAMPLESHEET=""
OUTDIR="qc"
THREADS=4
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --samplesheet)
            [[ $# -ge 2 ]] || die "--samplesheet requires a value"
            SAMPLESHEET="$2"
            shift 2
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
[[ "${THREADS}" =~ ^[1-9][0-9]*$ ]] || die "--threads must be a positive integer"

require_command python3
python3 "${SCRIPT_DIR}/validate_inputs.py" --samplesheet "${SAMPLESHEET}"

if [[ "${DRY_RUN}" != "true" ]]; then
    require_command fastqc
    require_command fastp
    require_command multiqc
fi

RAW_FASTQC_DIR="${OUTDIR}/raw_fastqc"
TRIMMED_DIR="${OUTDIR}/trimmed_fastq"
FASTP_DIR="${OUTDIR}/fastp"
TRIMMED_FASTQC_DIR="${OUTDIR}/trimmed_fastqc"
MULTIQC_DIR="${OUTDIR}/multiqc"
LOG_DIR="${OUTDIR}/logs"

mkdir -p \
    "${RAW_FASTQC_DIR}" \
    "${TRIMMED_DIR}" \
    "${FASTP_DIR}" \
    "${TRIMMED_FASTQC_DIR}" \
    "${MULTIQC_DIR}" \
    "${LOG_DIR}"

SAMPLE_ROWS_FILE="$(mktemp "${OUTDIR}/.sample_rows.XXXXXX")"
trap 'rm -f -- "${SAMPLE_ROWS_FILE}"' EXIT
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    --emit-tsv > "${SAMPLE_ROWS_FILE}"
mapfile -t SAMPLE_ROWS < "${SAMPLE_ROWS_FILE}"

log "Starting raw-read QC for ${#SAMPLE_ROWS[@]} sample(s)."

for row in "${SAMPLE_ROWS[@]}"; do
    IFS=$'\t' read -r sample_id fastq_r1 fastq_r2 <<< "${row}"

    trimmed_r1="${TRIMMED_DIR}/${sample_id}_R1.trimmed.fastq.gz"
    trimmed_r2="${TRIMMED_DIR}/${sample_id}_R2.trimmed.fastq.gz"

    log "${sample_id}: FastQC on raw reads"
    run_command fastqc \
        --threads "${THREADS}" \
        --outdir "${RAW_FASTQC_DIR}" \
        "${fastq_r1}" "${fastq_r2}"

    log "${sample_id}: adapter and quality trimming with fastp"
    run_command fastp \
        --in1 "${fastq_r1}" \
        --in2 "${fastq_r2}" \
        --out1 "${trimmed_r1}" \
        --out2 "${trimmed_r2}" \
        --detect_adapter_for_pe \
        --thread "${THREADS}" \
        --json "${FASTP_DIR}/${sample_id}.fastp.json" \
        --html "${FASTP_DIR}/${sample_id}.fastp.html" \
        --report_title "${sample_id} fastp report"

    log "${sample_id}: FastQC on trimmed reads"
    run_command fastqc \
        --threads "${THREADS}" \
        --outdir "${TRIMMED_FASTQC_DIR}" \
        "${trimmed_r1}" "${trimmed_r2}"
done

log "Building combined MultiQC report"
run_command multiqc \
    --force \
    --outdir "${MULTIQC_DIR}" \
    --filename "multiqc_report.html" \
    "${RAW_FASTQC_DIR}" "${FASTP_DIR}" "${TRIMMED_FASTQC_DIR}"

if [[ "${DRY_RUN}" != "true" ]]; then
    {
        printf 'run_utc\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'fastqc\t%s\n' "$(fastqc --version 2>&1 | head -n 1)"
        printf 'fastp\t%s\n' "$(fastp --version 2>&1 | head -n 1)"
        printf 'multiqc\t%s\n' "$(multiqc --version 2>&1 | head -n 1)"
    } > "${LOG_DIR}/software_versions.tsv"
fi

log "QC workflow completed. Review ${MULTIQC_DIR}/multiqc_report.html before alignment."
