process PHYKIT_CONCAT {
    tag "${markerset}"
    label 'process_low'

    publishDir "${params.outdir}/${mode}/buildtree/${markerset}", mode: params.publish_mode

    input:
    tuple val(markerset), val(mode), path(filter_dir), val(stem)
    val data_type   // 'DNA' or 'PROT' — broadcast value, same for all markersets in a run

    output:
    tuple val(markerset), val(mode), path("${stem}.fa"), path("${stem}.partition"), emit: concat

    script:
    """
    ls ${filter_dir}/*.mfa > filenames
    phykit create_concat -a filenames -p ${stem}
    sed -i 's/AUTO/${data_type}/' ${stem}.partition
    """
}
