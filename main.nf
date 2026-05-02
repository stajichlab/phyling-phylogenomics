#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { CDS_TREE     } from './workflows/cds_tree'
include { PROTEIN_TREE } from './workflows/protein_tree'

def validate_params() {
    if (!params.input)     error "ERROR: --input is required (path to cds/ or pep/ directory)"
    if (!params.prefix)    error "ERROR: --prefix is required (e.g. mucor_jena_v8)"
    if (!params.markerset) error "ERROR: --markerset is required (e.g. fungi_odb12,mucoromycota_odb12)"
    if (params.mode !in ['cds_tree', 'protein_tree']) {
        error "ERROR: --mode must be 'cds_tree' or 'protein_tree'"
    }
}

workflow {
    validate_params()

    if (params.mode == 'cds_tree') {
        CDS_TREE()
    } else {
        PROTEIN_TREE()
    }
}
