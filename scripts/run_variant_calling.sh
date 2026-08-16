#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/run_variant_calling.sh --samplesheet FILE --reference FASTA \
    --intervals FILE [options]

Required:
  --samplesheet FILE  CSV containing sample_id,fastq_r1,fastq_r2.
  --reference FASTA   GRCh38 reference used for alignment.
  --intervals FILE    WES target intervals in GATK-compatible format.

Options:
  --bam-dir DIR       Mark-duplicate BAM directory
                      (default: results/alignment/bam).
  --outdir DIR        Output directory (default: results/variants).
  --threads N         Native PairHMM threads (default: 4).
  --memory-gb N       Java heap size in GB (default: 8).
  --dry-run           Validate paths and print commands without running tools.
  -h, --help          Show this help message.

This stage demonstrates single-sample WES germline SNV/indel calling. Hard
filters are transparent defaults for portfolio benchmarking, not universal
clinical acceptance thresholds.
EOF
}

SAMPLESHEET=""
REFERENCE=""
INTERVALS=""
BAM_DIR="results/alignment/bam"
OUTDIR="results/variants"
THREADS=4
MEMORY_GB=8
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
        --intervals)
            [[ $# -ge 2 ]] || die "--intervals requires a value"
            INTERVALS="$2"
            shift 2
            ;;
        --bam-dir)
            [[ $# -ge 2 ]] || die "--bam-dir requires a value"
            BAM_DIR="$2"
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
        --memory-gb)
            [[ $# -ge 2 ]] || die "--memory-gb requires a value"
            MEMORY_GB="$2"
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
[[ -n "${INTERVALS}" ]] || die "--intervals is required"
[[ "${THREADS}" =~ ^[1-9][0-9]*$ ]] || die "--threads must be a positive integer"
[[ "${MEMORY_GB}" =~ ^[1-9][0-9]*$ ]] || die "--memory-gb must be a positive integer"
[[ -s "${REFERENCE}" ]] || die "Reference FASTA missing or empty: ${REFERENCE}"
[[ -s "${INTERVALS}" ]] || die "Intervals file missing or empty: ${INTERVALS}"

require_command python3
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    --skip-file-checks

if [[ "${DRY_RUN}" != "true" ]]; then
    require_command gatk
    require_command bcftools
    [[ -s "${REFERENCE}.fai" ]] || die "Reference FASTA index missing: ${REFERENCE}.fai"
    reference_stem="${REFERENCE%.*}"
    [[ -s "${reference_stem}.dict" ]] || die "Reference dictionary missing: ${reference_stem}.dict"
fi

GVCF_DIR="${OUTDIR}/gvcf"
RAW_DIR="${OUTDIR}/raw"
FILTERED_DIR="${OUTDIR}/filtered"
METRICS_DIR="${OUTDIR}/metrics"
LOG_DIR="${OUTDIR}/logs"
mkdir -p "${GVCF_DIR}" "${RAW_DIR}" "${FILTERED_DIR}" "${METRICS_DIR}" "${LOG_DIR}"

SAMPLE_ROWS_FILE="$(mktemp "${OUTDIR}/.sample_rows.XXXXXX")"
trap 'rm -f -- "${SAMPLE_ROWS_FILE}"' EXIT
python3 "${SCRIPT_DIR}/validate_inputs.py" \
    --samplesheet "${SAMPLESHEET}" \
    --skip-file-checks \
    --emit-tsv > "${SAMPLE_ROWS_FILE}"
mapfile -t SAMPLE_ROWS < "${SAMPLE_ROWS_FILE}"

JAVA_OPTIONS="-Xmx${MEMORY_GB}g"
log "Starting germline short-variant calling for ${#SAMPLE_ROWS[@]} sample(s)."

for row in "${SAMPLE_ROWS[@]}"; do
    IFS=$'\t' read -r sample_id _ _ <<< "${row}"
    bam="${BAM_DIR}/${sample_id}.markdup.bam"
    bai="${bam}.bai"
    [[ -s "${bam}" ]] || die "Input BAM missing or empty for ${sample_id}: ${bam}"
    if [[ "${DRY_RUN}" != "true" ]]; then
        [[ -s "${bai}" ]] || die "BAM index missing or empty for ${sample_id}: ${bai}"
    fi

    gvcf="${GVCF_DIR}/${sample_id}.g.vcf.gz"
    raw_vcf="${RAW_DIR}/${sample_id}.raw.vcf.gz"
    snps_vcf="${FILTERED_DIR}/${sample_id}.snps.vcf.gz"
    indels_vcf="${FILTERED_DIR}/${sample_id}.indels.vcf.gz"
    snps_filtered="${FILTERED_DIR}/${sample_id}.snps.filtered.vcf.gz"
    indels_filtered="${FILTERED_DIR}/${sample_id}.indels.filtered.vcf.gz"
    merged_filtered="${FILTERED_DIR}/${sample_id}.filtered.vcf.gz"
    normalised_vcf="${FILTERED_DIR}/${sample_id}.filtered.normalised.vcf.gz"

    log "${sample_id}: HaplotypeCaller in reference-confidence mode"
    run_command gatk --java-options "${JAVA_OPTIONS}" HaplotypeCaller \
        -R "${REFERENCE}" \
        -I "${bam}" \
        -L "${INTERVALS}" \
        -O "${gvcf}" \
        -ERC GVCF \
        --native-pair-hmm-threads "${THREADS}"

    log "${sample_id}: single-sample genotyping"
    run_command gatk --java-options "${JAVA_OPTIONS}" GenotypeGVCFs \
        -R "${REFERENCE}" \
        -V "${gvcf}" \
        -L "${INTERVALS}" \
        -O "${raw_vcf}"

    log "${sample_id}: splitting SNPs and indels"
    run_command gatk SelectVariants \
        -R "${REFERENCE}" -V "${raw_vcf}" --select-type-to-include SNP -O "${snps_vcf}"
    run_command gatk SelectVariants \
        -R "${REFERENCE}" -V "${raw_vcf}" --select-type-to-include INDEL -O "${indels_vcf}"

    log "${sample_id}: applying documented hard filters"
    run_command gatk VariantFiltration \
        -R "${REFERENCE}" -V "${snps_vcf}" -O "${snps_filtered}" \
        --filter-name "SNP_QD2" --filter-expression "QD < 2.0" \
        --filter-name "SNP_QUAL30" --filter-expression "QUAL < 30.0" \
        --filter-name "SNP_SOR3" --filter-expression "SOR > 3.0" \
        --filter-name "SNP_FS60" --filter-expression "FS > 60.0" \
        --filter-name "SNP_MQ40" --filter-expression "MQ < 40.0" \
        --filter-name "SNP_MQRS-12.5" --filter-expression "MQRankSum < -12.5" \
        --filter-name "SNP_RPRS-8" --filter-expression "ReadPosRankSum < -8.0"

    run_command gatk VariantFiltration \
        -R "${REFERENCE}" -V "${indels_vcf}" -O "${indels_filtered}" \
        --filter-name "INDEL_QD2" --filter-expression "QD < 2.0" \
        --filter-name "INDEL_QUAL30" --filter-expression "QUAL < 30.0" \
        --filter-name "INDEL_FS200" --filter-expression "FS > 200.0" \
        --filter-name "INDEL_RPRS-20" --filter-expression "ReadPosRankSum < -20.0"

    log "${sample_id}: merging and normalising filtered calls"
    run_command gatk MergeVcfs \
        -I "${snps_filtered}" \
        -I "${indels_filtered}" \
        -O "${merged_filtered}"
    run_command bcftools norm \
        -f "${REFERENCE}" \
        -m -any \
        -Oz \
        -o "${normalised_vcf}" \
        "${merged_filtered}"
    run_command bcftools index --tbi "${normalised_vcf}"

    if [[ "${DRY_RUN}" == "true" ]]; then
        printf 'DRY-RUN: bcftools stats %q > %q\n' \
            "${normalised_vcf}" "${METRICS_DIR}/${sample_id}.bcftools.stats.txt"
    else
        bcftools stats "${normalised_vcf}" \
            > "${METRICS_DIR}/${sample_id}.bcftools.stats.txt"
    fi
done

if [[ "${DRY_RUN}" != "true" ]]; then
    {
        printf 'run_utc\t%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'gatk\t%s\n' "$(gatk --version 2>&1 | head -n 1)"
        printf 'bcftools\t%s\n' "$(bcftools --version | head -n 1)"
        printf 'reference\t%s\n' "$(realpath "${REFERENCE}")"
        printf 'reference_sha256\t%s\n' "$(sha256sum "${REFERENCE}" | cut -d ' ' -f 1)"
        printf 'intervals\t%s\n' "$(realpath "${INTERVALS}")"
        printf 'intervals_sha256\t%s\n' "$(sha256sum "${INTERVALS}" | cut -d ' ' -f 1)"
    } > "${LOG_DIR}/variant_calling_provenance.tsv"
fi

log "Variant calling completed. Review FILTER labels and metrics before annotation."
