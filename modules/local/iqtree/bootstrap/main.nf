// UFBoot2 + SH-aLRT bootstraps using the best partitioning scheme from IQTREE_MF.
process IQTREE_BOOTSTRAP {
    tag "${markerset}:${score}"
    label 'process_tree'

    publishDir "${params.outdir}/${mode}/buildtree/${markerset}", mode: params.publish_mode

    input:
    tuple val(markerset), val(mode), val(score), path(concat_fa), path(best_scheme)

    output:
    tuple val(markerset), val(mode), val(score), path("*.treefile"), emit: treefile
    tuple val(markerset), val(mode), val(score), path("*.contree"),  emit: contree,  optional: true
    path "*.log",                                                     emit: logs,    optional: true

    script:
    def prefix = "${concat_fa.baseName}.${score}.bs"
    """
    iqtree3 \\
        -s ${concat_fa} \\
        -p ${best_scheme} \\
        -B ${params.bs_count} \\
        --alrt ${params.alrt_count} \\
        --bnni \\
        --wbtl \\
        --prefix ${prefix} \\
        -T AUTO \\
        --ntmax ${task.cpus}
    """
}
