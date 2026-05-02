process PHYLING_TREE {
    tag "${markerset}"
    label 'process_medium'

    publishDir "${params.outdir}/${params.seq_type}/tree/${markerset}", mode: params.publish_mode

    input:
    tuple val(markerset), val(seq_type), path(filter_dir)

    output:
    tuple val(markerset), val(seq_type), path("tree_out"), emit: tree_dir

    script:
    """
    phyling tree \\
        -I ${filter_dir} \\
        -M ft \\
        -t ${task.cpus} \\
        -o tree_out \\
        --verbose
    """
}
