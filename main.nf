#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include { CDS_TREE     } from './workflows/cds_tree'
include { PROTEIN_TREE } from './workflows/protein_tree'

def validate_params() {
    if (!params.input)     error "ERROR: --input is required (path to cds/ or pep/ directory)"
    if (!params.prefix)    error "ERROR: --prefix is required (e.g. mucor_jena_v8)"
    if (!params.markerset) error "ERROR: --markerset is required (e.g. fungi_odb12,mucoromycota_odb12)"
    if (params.seq_type !in ['cds', 'protein']) {
        error "ERROR: --seq_type must be 'cds' or 'protein'"
    }
}

workflow {
    validate_params()

    if (params.seq_type == 'cds') {
        CDS_TREE()
    } else {
        PROTEIN_TREE()
    }
}
