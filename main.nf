nextflow.enable.dsl = 2

/*
 * Portfolio-grade orchestration for paired-end germline WES.
 * Research and training use only; not a validated diagnostic workflow.
 */

process RAW_READ_QC {
    tag 'all samples'
    publishDir params.outdir, mode: 'copy', overwrite: true
    conda "${projectDir}/environment.yml"

    input:
    path samplesheet

    output:
    path 'qc', emit: qc_dir

    script:
    """
    ${projectDir}/scripts/run_qc.sh \\
      --samplesheet ${samplesheet} \\
      --outdir qc \\
      --threads ${task.cpus}
    """
}

process ALIGNMENT_AND_BAM_QC {
    tag 'all samples'
    publishDir params.outdir, mode: 'copy', overwrite: true
    conda "${projectDir}/environment.yml"

    input:
    path samplesheet
    path qc_dir
    path reference_files

    output:
    path 'alignment', emit: alignment_dir

    script:
    def reference_name = file(params.reference).name
    """
    ${projectDir}/scripts/run_alignment.sh \\
      --samplesheet ${samplesheet} \\
      --reference ${reference_name} \\
      --reads-dir ${qc_dir}/trimmed_fastq \\
      --outdir alignment \\
      --threads ${task.cpus}
    """
}

process GERMLINE_SHORT_VARIANTS {
    tag 'all samples'
    publishDir params.outdir, mode: 'copy', overwrite: true
    conda "${projectDir}/environment.yml"

    input:
    path samplesheet
    path alignment_dir
    path reference_files
    path intervals

    output:
    path 'variants', emit: variants_dir

    script:
    def reference_name = file(params.reference).name
    """
    ${projectDir}/scripts/run_variant_calling.sh \\
      --samplesheet ${samplesheet} \\
      --reference ${reference_name} \\
      --intervals ${intervals} \\
      --bam-dir ${alignment_dir}/bam \\
      --outdir variants \\
      --threads ${task.cpus} \\
      --memory-gb ${task.memory.toGiga() as int}
    """
}

process OFFLINE_VEP_ANNOTATION {
    tag 'all samples'
    publishDir params.outdir, mode: 'copy', overwrite: true
    conda "${projectDir}/environment.yml"

    input:
    path samplesheet
    path variants_dir
    path reference_files
    val vep_cache_dir

    output:
    path 'annotation', emit: annotation_dir

    script:
    def reference_name = file(params.reference).name
    """
    ${projectDir}/scripts/run_annotation.sh \\
      --samplesheet ${samplesheet} \\
      --reference ${reference_name} \\
      --vep-cache-dir ${vep_cache_dir} \\
      --vep-cache-version ${params.vep_cache_version} \\
      --vcf-dir ${variants_dir}/filtered \\
      --outdir annotation \\
      --forks ${task.cpus}
    """
}

workflow {
    if (!params.samplesheet) {
        error "Missing required parameter: --samplesheet"
    }
    if (!params.reference) {
        error "Missing required parameter: --reference"
    }
    if (!params.intervals) {
        error "Missing required parameter: --intervals"
    }
    if (!params.skip_annotation && !params.vep_cache_dir) {
        error "--vep_cache_dir is required unless --skip_annotation is true"
    }
    if (!params.skip_annotation && !params.vep_cache_version) {
        error "--vep_cache_version is required unless --skip_annotation is true"
    }

    reference_stem = params.reference.replaceFirst(/\.[^.]+$/, '')
    reference_paths = [
        params.reference,
        "${params.reference}.fai",
        "${params.reference}.amb",
        "${params.reference}.ann",
        "${params.reference}.bwt",
        "${params.reference}.pac",
        "${params.reference}.sa",
        "${reference_stem}.dict"
    ]

    samplesheet_ch = Channel.value(file(params.samplesheet, checkIfExists: true))
    intervals_ch = Channel.value(file(params.intervals, checkIfExists: true))
    reference_ch = Channel.value(
        reference_paths.collect { path -> file(path, checkIfExists: true) }
    )

    RAW_READ_QC(samplesheet_ch)
    ALIGNMENT_AND_BAM_QC(samplesheet_ch, RAW_READ_QC.out.qc_dir, reference_ch)
    GERMLINE_SHORT_VARIANTS(
        samplesheet_ch,
        ALIGNMENT_AND_BAM_QC.out.alignment_dir,
        reference_ch,
        intervals_ch
    )

    if (!params.skip_annotation) {
        OFFLINE_VEP_ANNOTATION(
            samplesheet_ch,
            GERMLINE_SHORT_VARIANTS.out.variants_dir,
            reference_ch,
            params.vep_cache_dir
        )
    }
}
