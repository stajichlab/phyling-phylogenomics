process PHYLING_FILTER {
    tag "${markerset}"
    label 'process_medium'

    publishDir "${params.outdir}/${mode}/filter/${markerset}", mode: params.publish_mode

    input:
    tuple val(markerset), val(mode), path(align_dir)

    output:
    tuple val(markerset), val(mode), path("filter_out"), emit: filter_dir

    script:
    """
    phyling filter \\
        -I ${align_dir} \\
        -t ${task.cpus} \\
        -o filter_out \\
        --verbose \\
        -n ${params.min_taxa_pct}
    """
}
