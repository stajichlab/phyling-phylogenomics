# PHYling Phylogenomics — Nextflow Pipeline

[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A524.0-brightgreen)](https://nextflow.io/)

DSL2 Nextflow pipeline for multi-locus ML phylogenomics using BUSCO single-copy
orthologs. Wraps PHYling, PhyKIT, ModelTest-NG, IQ-TREE 3, and RAxML-NG into
two named workflows:

| Workflow | `--mode` | Input | Data type | RAxML-NG bootstraps |
|---|---|---|---|---|
| `CDS_TREE` | `cds_tree` | `.fa` per taxon | DNA / CDS | 500 |
| `PROTEIN_TREE` | `protein_tree` | `.fa.gz` per taxon | Amino acid | 100 |

Both workflows run AIC and BIC partition schemes through IQ-TREE and RAxML-NG
in parallel, producing four independently-supported trees per markerset.

---

## Pipeline steps

```
INPUT: one sequence file per taxon
         ↓ (per markerset, in parallel)
  phyling align       BUSCO marker search + MSA
  phyling filter      Remove loci below occupancy threshold (default 80% of taxa)
  phyling tree        Per-gene FastTree (exploratory gene trees)
         ↓
  phykit create_concat   Concatenate filtered MSAs; write partition file
  sed AUTO→DNA/PROT       Fix data-type for modeltest-ng
         ↓
  modeltest-ng        Partitioned model selection → AIC and BIC partition files
         ↓          (AIC and BIC run in parallel from here)
  iqtree3 MF+MERGE    Partition merging + ML tree
  iqtree3 UFBoot      Bootstrap (-B 1000 --alrt 1000 --bnni --wbtl)
  raxml-ng --parse    Produce binary alignment; extract thread recommendation
  raxml-ng --all      ML search + bootstraps
```

---

## Quick start

### Run directly from GitHub (no clone needed)

```bash
nextflow run stajichlab/phyling-phylogenomics \
  -profile slurm,ucr_hpcc \
  --mode protein_tree \
  --input /path/to/pep \
  --prefix my_project \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/pep
```

### Clone and run locally

```bash
git clone https://github.com/stajichlab/phyling-phylogenomics
cd phyling-phylogenomics

nextflow run main.nf \
  -profile local \
  --mode cds_tree \
  --input /path/to/cds \
  --prefix my_project \
  --markerset fungi_odb12 \
  --outdir results/test
```

---

## Requirements

### Option A — pixi (recommended)

```bash
# Install pixi if not already present
curl -fsSL https://pixi.sh/install.sh | bash

# Install all pipeline tools
pixi install
```

Tools installed: `nextflow`, `modeltest-ng`, `iqtree ≥2.3` (provides `iqtree3`),
`raxml-ng` from bioconda; `phykit` and `phyling` from PyPI.

### Option B — environment modules (HPC)

Module names expected by `-profile slurm`:
`phyling`, `phykit`, `modeltest-ng`, `iqtree`, `raxml-ng`

---

## Execution profiles

Profiles can be combined with commas: `-profile slurm,ucr_hpcc`

| Profile | Executor | Environment | Use when |
|---|---|---|---|
| `slurm` | SLURM | `module load` per tool | HPC with environment modules |
| `ucr_hpcc` | — | — | UCR HPCC queue names (combine with `slurm` or `pixi_slurm`) |
| `pixi` | local | pixi env | local workstation with pixi |
| `pixi_slurm` | SLURM | pixi env | HPC without modules; combine with a site profile |
| `local` | local | tools in PATH | testing |

### Using on a different cluster

Queue names are cluster-specific. Create a minimal site config and pass it with `-c`:

```groovy
// my_cluster.config
process {
    withName: 'PHYLING_ALIGN'    { queue = 'bigmem' }
    withName: 'MODELTEST_NG|IQTREE_MF|IQTREE_BOOTSTRAP|RAXMLNG_ALL' { queue = 'compute' }
    withName: 'PHYLING_FILTER|PHYLING_TREE|PHYKIT_CONCAT|RAXMLNG_PARSE' { queue = 'short' }
}
```

```bash
nextflow run stajichlab/phyling-phylogenomics \
  -profile slurm -c my_cluster.config \
  --mode protein_tree --input pep/ --prefix my_project \
  --markerset fungi_odb12
```

---

## All parameters

| Parameter | Default | Description |
|---|---|---|
| `--mode` | `protein_tree` | Workflow: `cds_tree` or `protein_tree` |
| `--input` | *(required)* | Directory of `.fa` (CDS) or `.fa.gz` (protein) files |
| `--prefix` | *(required)* | Base name for output files, e.g. `my_project_v1` |
| `--markerset` | `fungi_odb12,mucoromycota_odb12` | Comma-separated BUSCO lineage names |
| `--outdir` | `results` | Directory for published outputs |
| `--publish_mode` | `copy` | publishDir mode: `copy`, `link`, or `symlink` |
| `--min_taxa_pct` | `80` | Min % of taxa to retain a locus (`phyling filter -n`) |
| `--rcluster` | `10` | IQ-TREE partition merging aggressiveness |
| `--bs_count` | `1000` | IQ-TREE UFBoot replicates (`-B`) |
| `--alrt_count` | `1000` | IQ-TREE SH-aLRT replicates (`--alrt`) |
| `--pars_trees` | `10` | RAxML-NG parsimony starting trees |
| `--bs_trees_cds` | `500` | RAxML-NG bootstrap replicates for CDS mode |
| `--bs_trees_pep` | `100` | RAxML-NG bootstrap replicates for protein mode |

### Common BUSCO markersets

| Markerset | Scope |
|---|---|
| `fungi_odb10` / `fungi_odb12` | All Fungi (ODB10 / ODB12) |
| `mucoromycota_odb10` / `mucoromycota_odb12` | Mucoromycota-specific |
| `basidiomycota_odb10` | Basidiomycota |
| `ascomycota_odb10` | Ascomycota |

Multiple markersets run as independent parallel branches.

---

## Example commands

### Protein tree — SLURM + modules (UCR HPCC)
```bash
nextflow run stajichlab/phyling-phylogenomics \
  -profile slurm,ucr_hpcc \
  --mode protein_tree \
  --input pep/ \
  --prefix my_project_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/pep
```

### CDS tree — SLURM + modules (UCR HPCC)
```bash
nextflow run stajichlab/phyling-phylogenomics \
  -profile slurm,ucr_hpcc \
  --mode cds_tree \
  --input cds/ \
  --prefix my_project_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/cds
```

### Resume an interrupted run
```bash
nextflow run stajichlab/phyling-phylogenomics -resume \
  -profile slurm,ucr_hpcc \
  --mode protein_tree \
  --input pep/ \
  --prefix my_project_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/pep
```

---

## Output structure

```
results/
└── {cds|pep}/
    ├── align/{markerset}/          phyling align output
    ├── filter/{markerset}/         filtered .mfa files (one per locus)
    ├── tree/{markerset}/           per-gene FastTree trees
    ├── buildtree/{markerset}/
    │   ├── *.fa                    concatenated alignment
    │   ├── *.partition             partition file (data-type fixed)
    │   ├── *.part.aic / *.part.bic ModelTest-NG AIC and BIC schemes
    │   ├── *.aic.bs.treefile       IQ-TREE AIC bootstrap consensus
    │   ├── *.bic.bs.treefile       IQ-TREE BIC bootstrap consensus
    │   ├── *.aic.raxml.support     RAxML-NG AIC support tree
    │   └── *.bic.raxml.support     RAxML-NG BIC support tree
    └── pipeline_info/
        ├── timeline.html
        ├── report.html
        └── dag.svg
```

Tree files (`.treefile`, `.raxml.support`) are Newick format — open in FigTree, iTOL, or ggtree.

---

## Interpreting support values

| Measure | Flag | Strong support threshold |
|---|---|---|
| UFBoot2 (ultrafast bootstrap) | `-B 1000` | ≥ 95 |
| SH-aLRT | `--alrt 1000` | ≥ 80 |
| RAxML-NG bootstrap | `--bs-trees` | ≥ 70 |

UFBoot values are systematically higher than standard bootstrap — do not compare directly. A clade is robustly supported when all three exceed their thresholds.

---

## Repository structure

```
phyling-phylogenomics/
├── main.nf                  entry point
├── nextflow.config          params + profiles
├── pixi.toml                conda/PyPI environment
├── conf/
│   ├── base.config          per-process resource labels
│   └── ucr_hpcc.config      UCR HPCC queue assignments (site example)
├── workflows/
│   ├── cds_tree.nf
│   └── protein_tree.nf
└── modules/local/
    ├── phyling/{align,filter,tree}/
    ├── phykit/concat/
    ├── modeltestng/
    ├── iqtree/{mf,bootstrap}/
    └── raxmlng/{parse,all}/
```

---

## Citation

If you use this pipeline, please cite the underlying tools:

- **PHYling**: https://github.com/stajichlab/PHYling_unified
- **PhyKIT**: Steenwyk et al. (2021) *Bioinformatics* 37:2325–2328
- **ModelTest-NG**: Darriba et al. (2020) *Mol Biol Evol* 37:291–294
- **IQ-TREE 3**: Minh et al. (2020) *Mol Biol Evol* 37:1530–1534
- **RAxML-NG**: Kozlov et al. (2019) *Bioinformatics* 35:4453–4455
- **BUSCO**: Manni et al. (2021) *Mol Biol Evol* 38:4647–4654
