---
name: phyling-phylogenomics
description: >
  Multi-locus fungal and microbial phylogenomics pipeline: PHYling (BUSCO-based
  marker alignment and filtering) → PhyKIT (MSA concatenation) → ModelTest-NG
  (partitioned model selection, AIC + BIC) → IQ-TREE 3 (ML tree + UFBoot2 +
  SH-aLRT) → RAxML-NG (independent ML search + bootstraps). Wraps a Nextflow
  DSL2 pipeline with two named workflows: CDS_TREE (DNA) and PROTEIN_TREE (amino
  acid). Runs on SLURM HPC clusters via environment modules or a pixi-managed
  conda environment. Use this skill whenever the user wants to build a multi-locus
  phylogeny from BUSCO markers, run PHYling align/filter/tree, concatenate filtered
  MSAs with PhyKIT, select substitution models with ModelTest-NG, or run IQ-TREE
  or RAxML-NG on a partitioned alignment. Also trigger for questions about
  markerset selection (fungi_odb12, mucoromycota_odb12, etc.), the cds_tree or
  protein_tree workflows, filtering occupancy thresholds, AIC vs BIC model
  selection, or UFBoot vs standard bootstrap in the context of phylogenomics.
  Trigger proactively when the user mentions they have genome annotations or
  proteomes and want to place taxa in a phylogeny.
---

# PHYling Phylogenomics Skill

You help the user set up and run a complete multi-locus phylogenomics analysis
using the Nextflow pipeline at:

```
nextflow/main.nf
```

The pipeline covers everything from BUSCO-marker alignment through partitioned
ML trees with bootstrap support in both IQ-TREE and RAxML-NG.

---

## Step 1 — Gather information

Before generating any commands, ask (or infer from context) the following.
Don't ask for things the user has already told you.

| Item | Notes / defaults |
|---|---|
| **Mode** | `cds_tree` (DNA) or `protein_tree` (amino acid) |
| **Input directory** | Path to `.fa` (CDS) or `.fa.gz` (protein) files — one file per taxon |
| **Project prefix** | Base name for output files, e.g. `mucor_jena_v8` |
| **Markersets** | Comma-separated BUSCO lineage names — see Markerset Guide below |
| **Output directory** | Where results are published; suggest `results/cds` or `results/pep` |
| **Execution profile** | `slurm`, `pixi`, `pixi_slurm`, or `local` — see Profiles section |
| **Pipeline location** | Absolute path to `main.nf`; confirm with user if unsure |

---

## Pipeline overview

```
INPUT: one .fa or .fa.gz per taxon
         ↓ (per markerset, in parallel)
  phyling align       BUSCO-based marker search and MSA
  phyling filter      Drop loci where < --min-taxa-pct % of taxa present (default 80%)
  phyling tree        Per-gene FastTree (exploratory; runs in parallel with concat)
         ↓
  phykit create_concat   Concatenate filtered MSAs; write NEXUS partition file
  sed AUTO→DNA/PROT       Fix data-type in partition file
         ↓
  modeltest-ng        Partitioned model selection; produces AIC and BIC partition files
         ↓          (AIC and BIC paths run in parallel from here)
  iqtree3 MF+MERGE    Model-finder + partition merging + ML tree (-rcluster 10)
  iqtree3 UFBoot      Bootstrap on best partition scheme (-B 1000 --alrt 1000 --bnni)
  raxml-ng --parse    Convert alignment to binary; extract thread recommendation
  raxml-ng --all      ML search + bootstraps (pars{10} starts; 500 bs for CDS, 100 for pep)
```

Final outputs per markerset: two trees (AIC, BIC) from each of IQ-TREE and
RAxML-NG, each with bootstrap support.

---

## Markerset guide

BUSCO lineage names follow the pattern `{clade}_odb{version}`.

| Lineage | Scope | Use when |
|---|---|---|
| `fungi_odb10` | All Fungi, ODB10 | broad fungal phylogeny, legacy dataset |
| `fungi_odb12` | All Fungi, ODB12 | broad fungal phylogeny, current preferred |
| `mucoromycota_odb10` | Mucoromycota, ODB10 | Mucoromycota-focused, legacy |
| `mucoromycota_odb12` | Mucoromycota, ODB12 | Mucoromycota-focused, current preferred |
| `basidiomycota_odb10` | Basidiomycota | Basidiomycota studies |
| `ascomycota_odb10` | Ascomycota | Ascomycota studies |

**Recommended combinations:**
- Mucoromycota project: `--markerset fungi_odb12,mucoromycota_odb12`
- Broad Fungi with legacy comparison: `--markerset fungi_odb10,fungi_odb12`
- Full Mucoromycota project (protein): `--markerset fungi_odb10,fungi_odb12,mucoromycota_odb10,mucoromycota_odb12`

Each markerset runs as an independent Nextflow branch — you get a separate tree
set per markerset, which is useful for comparing marker resolution.

---

## Execution profiles

Profiles can be combined with commas. Queue names are cluster-specific — supply a
site profile alongside `slurm` or `pixi_slurm`.

| Profile | Executor | Environment | Use when |
|---|---|---|---|
| `slurm` | SLURM | `module load` per tool | HPC with environment modules |
| `ucr_hpcc` | — | — | UCR HPCC queue names; combine with `slurm` or `pixi_slurm` |
| `pixi` | local | pixi-managed conda env | local workstation |
| `pixi_slurm` | SLURM | pixi env via `pixi shell-hook` | HPCC without modules |
| `local` | local | tools must be in PATH | quick tests |

For UCR HPCC use `-profile slurm,ucr_hpcc`. Module names expected:
`phyling`, `phykit`, `modeltest-ng`, `iqtree`, `raxml-ng`.

---

## Command templates

The pipeline is published at `stajichlab/phyling-phylogenomics` on GitHub.
Nextflow fetches it automatically — no clone required.

### CDS tree — SLURM + modules (UCR HPCC)

```bash
nextflow run stajichlab/phyling-phylogenomics \
  -profile slurm,ucr_hpcc \
  --seq_type cds \
  --input /path/to/cds \
  --prefix MYPROJECT_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/cds
```

### Protein tree — SLURM + modules (UCR HPCC)

```bash
nextflow run stajichlab/phyling-phylogenomics \
  -profile slurm,ucr_hpcc \
  --seq_type protein \
  --input /path/to/pep \
  --prefix MYPROJECT_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/pep
```

### Other SLURM cluster (custom queue names)

```bash
# my_cluster.config — minimal site config
# process {
#   withName: 'PHYLING_ALIGN'    { queue = 'bigmem' }
#   withName: 'MODELTEST_NG|IQTREE_MF|IQTREE_BOOTSTRAP|RAXMLNG_ALL' { queue = 'compute' }
#   withName: 'PHYLING_FILTER|PHYLING_TREE|PHYKIT_CONCAT|RAXMLNG_PARSE' { queue = 'short' }
# }

nextflow run stajichlab/nf_phyling \
  -profile slurm -c my_cluster.config \
  --seq_type protein \
  --input /path/to/pep \
  --prefix MYPROJECT_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/pep
```

### Pixi environment + SLURM (UCR HPCC)

```bash
# Clone once to use pixi tasks
git clone https://github.com/stajichlab/nf_phyling
cd phyling-phylogenomics
pixi install   # once

pixi run run-pep -- \
  --input /path/to/pep \
  --prefix MYPROJECT_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/pep \
  -profile pixi_slurm,ucr_hpcc
```

### Local test (single markerset, no SLURM)

```bash
nextflow run stajichlab/nf_phyling \
  -profile local \
  --seq_type cds \
  --input /path/to/cds \
  --prefix test \
  --markerset fungi_odb12 \
  --outdir results/test
```

### Resume an interrupted run

```bash
nextflow run stajichlab/phyling-phylogenomics -resume \
  -profile slurm,ucr_hpcc \
  --seq_type cds \
  --input /path/to/cds \
  --prefix MYPROJECT_v1 \
  --markerset fungi_odb12,mucoromycota_odb12 \
  --outdir results/cds
```

---

## Key parameters to tune

| Parameter | Default | When to change |
|---|---|---|
| `--top_n_to_keep` | `80` | Number of top markers to retain (`TOP_N_TOVERR` in phyling); lower (e.g. 60) for sparse datasets |
| `--bs_count` | `1000` | UFBoot replicates — 1000 is standard; don't go below 1000 |
| `--alrt_count` | `1000` | SH-aLRT replicates — report alongside UFBoot for support |
| `--bs_trees_cds` | `500` | RAxML-NG bootstrap for CDS; 100–500 is typical |
| `--bs_trees_pep` | `100` | RAxML-NG bootstrap for protein; protein runs are slower |
| `--rcluster` | `10` | IQ-TREE partition merging aggressiveness (% retained); raise if too slow |
| `--pars_trees` | `10` | RAxML-NG parsimony starting trees; 10–25 is typical |
| `--publish_mode` | `copy` | Use `link` (hard link) on same-filesystem HPC to save disk space |

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
    │   ├── *.part.aic / *.part.bic modeltest-ng AIC and BIC schemes
    │   ├── *.aic.bs.treefile       IQ-TREE AIC bootstrap consensus
    │   ├── *.bic.bs.treefile       IQ-TREE BIC bootstrap consensus
    │   ├── *.aic.raxml.support     RAxML-NG AIC support tree
    │   └── *.bic.raxml.support     RAxML-NG BIC support tree
    └── pipeline_info/
        ├── timeline.html
        ├── report.html
        └── dag.svg
```

**Primary result files** to report/visualise:
- `*.bs.treefile` — IQ-TREE bootstrap consensus (Newick; open in FigTree, iTOL, ggtree)
- `*.raxml.support` — RAxML-NG bootstrap support tree (same format)

---

## Environment setup (pixi)

If the user needs to install the environment for the first time:

```bash
cd pipeline/nextflow

# Install pixi (if not already available)
curl -fsSL https://pixi.sh/install.sh | bash

# Install all pipeline tools
pixi install
```

Tools installed by pixi: `nextflow`, `modeltest-ng`, `iqtree` (provides `iqtree3`),
`raxml-ng` from bioconda; `phykit` and `phyling` from PyPI.

---

## Monitoring a SLURM run

Nextflow manages SLURM job submission automatically. To watch progress:

```bash
# Live Nextflow log (run from the directory where nextflow was launched)
tail -f .nextflow.log

# Check submitted SLURM jobs
squeue -u $USER

# Watch the work directory for a specific process
ls work/??/*/  # Nextflow hashes work dirs
```

Each process writes its stdout/stderr to `work/<hash>/.command.log` — check
there first when a process fails.

---

## Troubleshooting

**`phyling align` fails / finds 0 markers**
- Confirm the input directory contains `.fa` (CDS) or `.fa.gz` (protein) files
- Confirm the markerset name is exactly correct (e.g. `fungi_odb12` not `fungi12`)
- The align step uses 384 GB RAM on highmem — check the job actually ran on highmem

**`phyling filter` produces empty output**
- Too few taxa have the marker — lower `--top_n_to_keep` (e.g. `--top_n_to_keep 60`)
- Check the align output directory has `.msa` files

**`phykit create_concat` fails**
- Filter output directory has no `.mfa` files — the filter step likely produced nothing
- Check `filter/{markerset}/filter_out/` for `.mfa` files

**`modeltest-ng` is very slow**
- Normal — it evaluates substitution models per partition
- Runs on epyc (48 CPUs, 128 GB); allow 12–48 hours for large datasets

**IQ-TREE exits with error on partition file**
- The `AUTO` → `DNA`/`PROT` sed replacement may have been skipped
- Check the `.partition` file: `grep AUTO results/.../buildtree/*/*.partition`

**RAxML-NG thread warning**
- The parse step recommends a thread count based on alignment size
- The pipeline reads this recommendation automatically from the `.raxml.log` file

**Resuming after failure**
- Always add `-resume` — Nextflow caches completed processes and will skip them
- Cached results live in `work/` — don't delete this directory mid-run

---

## Interpreting support values

Trees from this pipeline carry two support measures on the same run:
- **UFBoot (IQ-TREE `-B`)**: ultrafast bootstrap approximation; values ≥ 95 indicate strong support (note: UFBoot values are systematically higher than standard bootstrap — don't compare directly)
- **SH-aLRT (`--alrt`)**: likelihood ratio test; values ≥ 80 are generally considered supported
- **RAxML-NG bootstraps**: standard (slow) bootstraps; ≥ 70 is the conventional threshold

A clade is considered robustly supported when all three agree.

---

## Pipeline files

```
pipeline/nextflow/
├── main.nf                  entry point
├── nextflow.config          params + profiles
├── pixi.toml                conda/PyPI environment
├── conf/base.config         per-process CPU/mem/time
├── workflows/
│   ├── cds_tree.nf          CDS_TREE workflow
│   └── protein_tree.nf      PROTEIN_TREE workflow
└── modules/local/
    ├── phyling/{align,filter,tree}/
    ├── phykit/concat/
    ├── modeltestng/
    ├── iqtree/{mf,bootstrap}/
    └── raxmlng/{parse,all}/
```
