process PHYLING_ALIGN {
    tag "${markerset}"
    label 'process_high_memory'

    publishDir "${params.outdir}/${params.seq_type}/align/${params.markerset}", mode: params.publish_mode
    //publishDir "${params.outdir}//align/${markerset}", mode: params.publish_mode

    input:
    tuple val(markerset), val(seq_type), path(input_dir)

    output:
    tuple val(markerset), val(seq_type), path("align_out"), emit: align_dir

    script:
    """
    phyling align \\
        -I ${input_dir} \\
        -m ${markerset} \\
        -o align_out \\
        -t ${task.cpus} \\
        --verbose
    """
}
