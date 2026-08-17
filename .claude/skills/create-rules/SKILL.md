---
name: create-rules
description: Create global rules (CLAUDE.md) for a scientific data/pipeline project by analyzing the repo
---

# Create Global Rules (scientific data pipelines)

Generate a `CLAUDE.md` that orients Claude on a **scientific computing / data-analysis** repo:
what the science is, how data flows, where compute runs, which schemas are load-bearing, and
how to run and validate the analysis.

This is **not** a web-app/library generator. The unit of work here is a *pipeline stage* or an
*analysis*, not a "feature"; the artifacts are *datasets, sumstats, matrices, manifests, figures*,
not "API endpoints". Classify and describe accordingly.

**Runs on any repo, with or without an existing `CLAUDE.md`.** If one exists, Phase 0 restructures it
into the canonical skeleton while keeping every piece of information it holds. If not, Phase 0
no-ops and the skill generates from scratch.

---

## Objective

Produce project-specific rules that tell Claude:
- **What** the project studies and what question each stage answers.
- **What data** it operates on — formats, schemas, and what level of claim each representation permits.
- **Where** compute runs (laptop / HPC scheduler / cloud batch) and where data lives (in-repo / object store / scratch).
- **Which conventions** are load-bearing (column schemas, units, sign preservation, config-over-CLI).
- **How** the repo is laid out — the folder-structure standard every subproject follows.
- **How** to run a stage and **how** to validate it (there is rarely a unit-test suite — validation is positive controls, smoke runs, and schema checks).

### Non-goals

This skill **writes rules, it does not enforce them.** It never creates directories, never moves or
renames files, and never audits the repo against the folder-structure standard it documents. A messy
repo gets a correct `CLAUDE.md` and stays messy — cleaning up is a separate, deliberate act.

The one exception is `AGENTS.md`, which gets a short sync note appended (Phase 3) and nothing else.

---

## Phase 0: INGEST — an existing CLAUDE.md is input, not an obstacle

```bash
test -f CLAUDE.md && wc -l CLAUDE.md || echo "greenfield — skip to Phase 1"
```

**No `CLAUDE.md`?** Skip this phase entirely; Phase 4 reports `mode: created`.

**There is one?** Read it **in full** before running any detection command — you need to know what it
claims before you check whether the claims hold. Then sort every block of content into one of four
classes. The class decides what happens to the text, and this is the whole of the merge policy:

| Class | What it looks like | Action |
|---|---|---|
| **Derivable** | repo tree, directory listings, file inventories, the stack table, the key-files list — anything you could regenerate by reading the repo | **Regenerate** from the repo in Phases 1–2. Discard the old text silently; no conflict, no prompt. |
| **Asserted, agrees** | decisions, rationale, gotchas, schemas, naming conventions that the code confirms | **Carry forward verbatim** into the matching canonical section. Do not re-word to match the template's voice. |
| **Asserted, conflicts** | a claim the repo contradicts — a status, a count, a "canonical run" that no longer exists | **Preserve verbatim, flag inline, list in Phase 4.** Never resolve it yourself. |
| **Reproducibility-critical** | version pins and the reasoning behind them, container digests, known hazards, read-only-upstream constraints, positive-control thresholds, "do not move this" notes, failure post-mortems | **Never rewritten. Relocate only** — even when it looks stale, even when it is verbose. If unsure whether something is in this class, it is. |

Stale *derivable* content is the common case and needs no ceremony: a `## Repository structure`
block that is missing eight directories is simply regenerated.

### Two hard rules

**1. Nothing is dropped.** Content that fits no canonical section goes to the bottom under:

```markdown
## Unsorted (carried from previous CLAUDE.md)

<verbatim blocks that had no canonical home. Left for the author to file or delete.>
```

Never delete a block because it seems redundant or low-value. Parking it costs a few lines; deleting
someone's hard-won note costs them the knowledge.

**2. Conflicts are flagged, not resolved.** Write the marker directly above the preserved text:

```markdown
<!-- CONFLICT: CLAUDE.md says <X>; <source>:<line> says <Y>. Preserved existing text. Resolve manually. -->
```

Worked example — a real one. `CLAUDE.md` carries `Status: BUILT, NEVER RUN`; the README's header says
`Status: RUNNING` and `params/coarse_PPP.json` names a tag in flight. The repo is almost certainly
right. Preserve the CLAUDE.md wording anyway:

```markdown
<!-- CONFLICT: CLAUDE.md says BUILT, NEVER RUN; README.md:16 says RUNNING (phases 0-4b closed,
     phase 5 in flight). Preserved existing text. Resolve manually. -->
**Status: BUILT, NEVER RUN.** No stage has launched.
```

You are not better placed than the author to know which is true — a status can be aspirational, a
README can be the stale one, and a wrong auto-correction is invisible. Surface it and move on.

---

## Phase 1: DISCOVER — classify the project along five axes

Do **not** collapse a science repo into one "type". Classify it along five orthogonal axes; the
combination is the project type. Derive each axis by **reading signature files**, not by guessing
from a folder name.

### Axis A — Orchestration (how stages are wired together)

| Value | Signature indicators |
|---|---|
| Nextflow | `*.nf`, `main.nf`, `nextflow.config`, `-profile`, `params/*.json` |
| Snakemake | `Snakefile`, `workflow/rules/*.smk`, `config/config.yaml` |
| WDL / CWL | `*.wdl` + `inputs.json`; `*.cwl` |
| Make / shell DAG | `Makefile` targets that chain data steps; numbered `0x_*.sh` scripts |
| Notebook-driven | `*.ipynb` executed in order; `papermill`/`jupyter nbconvert` |
| Ad-hoc scripts | standalone `scripts/*.py` / `*.R` run by hand, no orchestrator |

### Axis B — Compute backend (where heavy steps execute)

| Value | Signature indicators |
|---|---|
| Local | runs on the laptop/workstation; no scheduler config |
| HPC scheduler | SLURM (`sbatch`, `#SBATCH`), SGE/UGE (`qsub`), PBS/LSF |
| Cloud batch | Google Batch (`google-batch` profile), AWS Batch, Azure Batch |
| Kubernetes | `k8s`/`eks`/`gke` executor, Helm/Argo |
| Mixed | heavy compute on a backend **+** local post-processing/plotting (very common) |

### Axis C — Analysis domain (what science / data)

| Value | Signature indicators |
|---|---|
| Statistical genetics / GWAS | GWAS sumstats (`*.tsv.gz`), PLINK/bgen, LDSC, GenomicSEM, MAGMA, FUMA, COJO, coloc/SuSiE, HapMap/1000G refs |
| Sequencing / bioinformatics | FASTQ/BAM/CRAM/VCF, nf-core, reference genome + GTF, samplesheets, aligners (STAR/bwa) |
| Single-cell / spatial | `*.h5ad`/`*.h5`/`*.rds`, scanpy/Seurat/scvi-tools, AnnData, cell × gene matrices |
| Imaging | TIFF/CZI/OME/DICOM, ImageJ/CellProfiler/napari, segmentation masks |
| Instrument / wet-lab data | instrument exports (CSV/XLSX/PDF), LIMS/ELN, plate maps, Allotrope/ASM |
| Tabular / epi / clinical | cohort tables, REDCap, survival/regression, `data dictionary` |
| Modeling / ML | training scripts, checkpoints, `configs/*.yaml`, metrics logs, sweeps |
| Simulation / numerics | parameter sweeps, solver configs, HDF5/NetCDF outputs |
| Method / tool package | a reusable library: `pyproject.toml` with `project.scripts`, or R `DESCRIPTION`/`NAMESPACE` |

> A repo can carry two domains (e.g. a GWAS pipeline that also vendors a clustering *tool*). Name both.

### Axis D — Data scale & locality (where the real data is)

| Value | Signature indicators |
|---|---|
| In-repo small | committed `data/`, test fixtures, `< ~100 MB` |
| External object store | `gs://`, `s3://`, `az://` paths in configs/scripts |
| HPC filesystem | absolute `/scratch`, `/projects`, `/work` paths; symlinked data dirs |
| Public/remote download | accessions (GEO `GSE…`, SRA `SRR…`, dbGaP, EGA), download scripts |

### Axis E — Reproducibility layer (envs & containers)

| Value | Signature indicators |
|---|---|
| Containers | `Dockerfile`, `*.def`/`Singularity`, image refs in configs (Artifact Registry / Docker Hub / quay) |
| Conda / mamba | `environment.yml`, `meta.yaml`, `micromamba` |
| Python venv | `requirements.txt`, `pyproject.toml`, `uv.lock`/`poetry.lock` |
| R | `renv.lock`, `DESCRIPTION`, `.Rprofile` |
| None pinned | bare interpreters; flag this as a reproducibility gap in the output |

### Detection sweep (run these, then read what they surface)

```bash
ls -la
# orchestration + repro signatures
find . -maxdepth 3 \( -name '*.nf' -o -name 'nextflow.config' -o -name 'Snakefile' \
  -o -name '*.smk' -o -name '*.wdl' -o -name '*.cwl' -o -name 'Makefile' \
  -o -name 'Dockerfile' -o -name '*.def' -o -name 'environment.yml' \
  -o -name 'requirements.txt' -o -name 'pyproject.toml' -o -name 'renv.lock' \
  -o -name 'DESCRIPTION' \) -not -path '*/.git/*' 2>/dev/null
# scheduler / backend hints
grep -rIl -E '#SBATCH|sbatch|qsub|google-batch|aws-batch|s3://|gs://|az://' . \
  --include='*.sh' --include='*.config' --include='*.nf' --include='*.smk' \
  --include='*.json' --include='*.yaml' 2>/dev/null | head
# data domain hints (extensions actually present)
find . -type f -not -path '*/.git/*' | sed -E 's/.*(\.[a-z0-9]+(\.gz)?)$/\1/' \
  | sort | uniq -c | sort -rn | head -30
# the existing entry points and any workflow index
find . -iname 'README*' -not -path '*/.git/*' | head
git log -1 --format='%ai  %s' 2>/dev/null
# layout: how far the repo already follows the folder-structure standard
ls -d scripts/*/ scripts/*/*/ 2>/dev/null
ls -1 CLAUDE.md AGENTS.md README.md REPORT.md NOTICE.md 2>/dev/null
# relative-path escapes — these make a stage's depth load-bearing
grep -rn '\.\./\.\./\.\.' --include='*.nf' --include='*.config' --include='*.py' \
  --include='*.sh' . 2>/dev/null | head
```

### Worked classification (example, end-to-end)

A repo that clusters UK Biobank phenotypes by GWAS signature then runs gene/disease follow-ups
classifies as:

- **A:** Nextflow (`scripts/*/main.nf`, `nextflow.config`, `-profile gcp`) **+** ad-hoc local Python/R for post-processing → *orchestrated pipeline with a local post-processing tail*.
- **B:** Cloud batch (Google Batch, head VM submits) **+** local — **Mixed**.
- **C:** Statistical genetics / GWAS (LDSC, GenomicSEM gPCA, MAGMA, coloc) **and** a vendored clustering *method package* (DIMPLE-GWAS). Two domains.
- **D:** External object store (`gs://…-usc1/`); `data/` holds only small refs.
- **E:** Containers (Artifact Registry images, pinned `postgwas:1.3`) + per-stage configs.

That five-tuple — not a single label — is the "project type". Lead the generated `CLAUDE.md`
with it.

---

## Phase 2: ANALYZE — extract the stack, the schemas, and the key files

### Scientific stack (fill what the repo actually uses)

- **Orchestration & profiles** — engine + profile names (e.g. `test` local vs `gcp`/`slurm`).
- **Compute** — backend, region/partition, how a run is submitted (head node? login node? laptop?).
- **Containers / envs** — image registry + tags (note any **pinned** image and why), conda/renv locks.
- **Storage** — bucket/scratch root and its subtree layout; how `workDir`/`outdir` are derived.
- **Languages & libraries** — Python (pandas/numpy/scipy/…), R (which Bioconductor/CRAN), Bash; versions if pinned.
- **Methods** — the statistical/algorithmic methods by name (clustering, gPCA, LDSC `rg`, MAGMA, SuSiE-coloc, MAD filtering, …). This is what a returning reader needs most.
- **External reference data** — reference panels, ontologies, public cohorts (HapMap3, 1000G, GTEx, FinnGen, …).

### Conventions — the load-bearing part for science

Read code and headers; do **not** infer schemas from filenames.

- **Data schemas** — for each interchange file, the exact column contract. Example precision to aim for:
  `cluster manifest = (phenotype_id, cluster_label, vcf_path)`;
  `gPCA sumstats = (SNP, EA, OA, EAF, BETA, SE, P, N_eff, N_obs)` where `N_obs` is a *fractional weight, not a sample size*.
  Capturing "what each column **is**, and what claim it licenses" is the whole point.
- **Units & sign** — log vs linear, `-log10(p)` vs `p`, OR vs beta, build GRCh37 vs 38, and any
  **sign-preservation** requirement (`b_SMR`, `rg`, `beta` signs that must survive aggregation).
- **Parameterization** — config/params files vs CLI flags; where the *canonical* run params live.
- **Naming** — dataset tags, run tags, `_with_features`/`_test` suffixes and what they mean. Watch
  for an **arm suffix** (`_PPP`, `_RAWZ`, `_CM`) applied to directories, scripts, configs, params,
  tests *and* output artifacts — where that convention holds it is near-total, and a file without
  the suffix is usually a mistake. Note also whether ordering is carried by numbered prefixes
  (`01_`, `02_`) or, more commonly, by prose in the README plus phase tags embedded mid-name
  (`phase8_`, `phase9_`).
- **Gotchas** — known data bugs, misdetections, crash modes (e.g. "`n_eff_mode=sum` → indefinite
  `cov_z` → MAGMA crash; use `max`"). One line each; these save hours.

### Key files to name in the output

- Pipeline **entry points** (`main.nf`, `Snakefile`, top driver scripts).
- **Canonical params/configs** (the one run that is "the answer").
- **Data dictionary** (IDP key, sample sheet, ontology maps).
- **Workflow-index README** (the top-level README that lists stages — see the `readme` skill).
- **Env/container** definitions and any handover/known-issue notes.

---

## Phase 3: GENERATE — write CLAUDE.md

**Output path:** `CLAUDE.md` (repo root).

Use the template below verbatim as the skeleton, then fill from Phases 1–2. Drop any section the
repo genuinely lacks (say so rather than leaving a stub). Keep it terse and mechanistic — match the
voice of the repo's own READMEs.

**On a restructure**, the skeleton is a *destination*, not a rewrite mandate. Content classified in
Phase 0 as *asserted-and-agreeing* or *reproducibility-critical* moves into its canonical section
**verbatim** — the template tells you where a thing goes, never how to re-word it. Only derivable
content is authored fresh.

````markdown
# <project-name>

<1–3 sentences: the scientific goal and the shape of the work. State whether it's greenfield or
brownfield (most analytical work done vs. actively building), and who the reader is.>

---

## Project type

<The five-axis classification as prose or a short list:>
- **Orchestration:** <Nextflow | Snakemake | … (+ local tail?)>
- **Compute backend:** <local | SLURM | Google Batch | mixed …>
- **Domain:** <stat-genetics | single-cell | imaging | … (+ any vendored method package)>
- **Data locality:** <in-repo | gs:// | /scratch | accessions>
- **Reproducibility:** <containers + conda/renv; note pinned images>

<One line on build/test posture, e.g. "No build system or unit-test suite at root; each stage is a
self-contained subdir with its own config, params, and scripts.">

---

## Tech stack

| Layer | Tools |
|---|---|
| Orchestration | <engine + profiles> |
| Compute | <backend, region/partition, submission host> |
| Containers / envs | <registry:tags, conda/renv locks; note any pinned image + why> |
| Storage | <bucket/scratch root + subtree layout> |
| Languages | <Python libs, R libs, Bash> |
| Methods | <named statistical/algorithmic methods> |
| External reference data | <panels, ontologies, public cohorts> |

---

## Folder structure

The root holds **housekeeping only**. Every analysis — including the first one — is a subproject
under `scripts/<arm>/`. Create this layout before writing any code in a new subproject.

```
<root>/                            housekeeping only
├── README.md                      index of arms + stages
├── REPORT.md                      rollup of subproject reports
├── CLAUDE.md
├── NOTICE.md                      third-party provenance, when vendoring
├── .gitignore, .gcloudignore
├── .claude/                       skills, agents, settings, handover/
├── docker/                        image builds              (root exception)
├── <ENGINE_FORK>/                 vendored library          (root exception)
└── scripts/
    └── <arm>/
        ├── README.md              stage index for this arm
        ├── project_<ARM>.yaml     control plane — question, provenance,
        │                          frozen_decisions, open_decisions, blockers,
        │                          input_contract, phases, closure_gates,
        │                          known_hazards. Not read by any pipeline.
        └── <stage>_<ARM>/
            ├── README.md          required
            ├── bin/               required — scripts the pipeline calls
            ├── configs/           required — grid/config YAML, keep-lists
            ├── params/            required — one file per run stage
            ├── tests/             required
            ├── docs/              required
            ├── results/           required
            ├── REPORT.md          when the stage closes
            └── figures/ data/ logs/ …    optional, created on demand
```

- **The two root exceptions are libraries, not subprojects.** A vendored engine fork and `docker/`
  stay at root; anything that *is* an analysis goes under `scripts/<arm>/`.
- **Relative-path depth is load-bearing.** A stage that reaches a root-level library by relative
  path — e.g. `${projectDir}/../../../<ENGINE_FORK>/<pkg>/<module>.py` — breaks silently if the
  stage moves up or down a level. Treat the depth of `scripts/<arm>/<stage>/` as fixed.
- **Required dirs are created up front, even empty.** Optional ones are created when first needed.
- <Note any deviation this repo actually has, and why — do not pretend the standard is met.>

### This repo's tree

```
<actual tree of the meaningful dirs with a one-line role each; mark the entry point "start here">
```

<Point at the workflow-index README: "Read the relevant stage README before editing that stage.">

---

## Data flow (high-level)

```
<ascii diagram: stageA ──► stageB ──► stageC ; show forks/joins and terminal stages>
```

<2–4 bullets on what flows between stages and what must NOT be crossed (e.g. reporting-only
variants that must never feed a pipeline).>

---

## Canonical datasets / runs

| Dataset | Canonical run / solution | Notes |
|---|---|---|
| <name> | <the params/config that is "the answer"> | <why this one; gotchas> |

---

## Conventions

### Compute / infrastructure
- <where to submit from; profile names; spot/preemption; output convention>

### Data schemas
- **<file>:** `(col, col, …)` — <what each non-obvious column IS and what claim it licenses>
- <units / sign / build conventions; sign-preservation requirements>

### Code style
- <config-over-CLI threshold; read real headers before parsing; long vs wide format rules; language idioms>

---

## Running stages

```bash
# Canonical, copy-pasteable invocation per major stage
<command>
```

---

## Validation / testing

<There is usually no unit-test suite. Document the real validation:>
- Smoke runs with small `--test` params.
- Pre-registered **positive controls** (e.g. "coloc gates on HMGCR↔LDL PP.H4 > 0.95").
- Schema / sanity checks (`N_eff` positive and physically plausible; column contracts hold).

---

## Key files to know

- <entry points, canonical params, data dictionary, workflow-index README, env/container defs, handover notes>

---

## Working with this repo via Claude

- **READMEs:** use the `readme` skill — one top-level index that lists each subproject as a
  linked list item, plus a canonical per-subproject README (Orientation / Inputs / Outputs /
  Workflow / How to run / Gotchas / Results / Related).
- **Finishing a subproject:** use the `report-findings` skill to write a `REPORT.md` (results,
  findings, and a clearly non-binding exploratory interpretation), link it from the subproject
  README's Results section, and roll its headline up into the root `REPORT.md`.
- **Starting a subproject:** create the layout in `## Folder structure` above before writing code.
  Nothing creates it for you.
- **Ending a session mid-work:** use the `handover` skill — it writes
  `.claude/handover/YYYY-MM-DD_<topic>.md` (state, next action, decisions, corrections). `prime`
  reads the newest one, so the next session resumes instead of re-deriving.
- **Orientation:** `prime`. **Committing:** `commit`.

---

## Out-of-scope / external links

- <external web tools with no API (FUMA, SMR portal, COJO), sibling repos, accession sources>

---

## Unsorted (carried from previous CLAUDE.md)

<Restructure only. Verbatim blocks that had no canonical home. Drop this section entirely if there
are none — never leave it as an empty stub.>
````

> **Encode the README + report workflow in the generated file.** The "Working with this repo via
> Claude" section above is mandatory — it is how a future session discovers the `readme`,
> `report-findings`, and `handover` skills.

### If an `AGENTS.md` exists

Some repos carry an `AGENTS.md` twin of `CLAUDE.md` for a different agent (Codex). It drifts, and a
future session may read the stale one.

**Do not mirror content into it** — it may hold agent-specific content that legitimately differs
(its own memory path, its own tool conventions), and overwriting that is not this skill's call.
Insert a short note directly after its H1, change nothing else in the file:

```markdown
> **Sync note — <YYYY-MM-DD>.** `CLAUDE.md` at the repo root was restructured by the `create-rules`
> skill and is the authoritative version. This file has diverged. Please re-sync it against
> `CLAUDE.md`, keeping the Codex-specific parts (memory path, tool conventions) as they are.
```

If a note from a previous run is already there, refresh its date rather than adding a second one.

---

## Phase 4: OUTPUT

```markdown
## Global Rules <Created | Restructured>

**File:** `CLAUDE.md`  ·  **Mode:** <created — no previous file | restructured from <N> lines>

### Project type (five-axis)
- Orchestration / Compute / Domain / Data locality / Reproducibility: <one line each>

### Stack summary
<key tools + methods detected>

### Load-bearing schemas captured
<the interchange-file column contracts written into CLAUDE.md>

### Conflicts preserved — UNRESOLVED   <restructure only; omit if none>
<Each one: what CLAUDE.md claims, what the repo says and where, and that the existing text was kept.>
1. <claim> — CLAUDE.md vs `<source>:<line>`. Existing text preserved, marked inline.

### Carried forward   <restructure only; omit if none>
- Reproducibility-critical blocks relocated verbatim: <N> (<one-line list: pins, hazards, constraints>)
- Blocks parked in `## Unsorted`: <N> — <what they are, so the author can file or delete them>

### AGENTS.md   <omit if absent>
- <sync note added | existing note refreshed to <date>>. No other line changed.

### Gaps / open questions
<anything you could not derive from the repo — unpinned envs, unclear canonical run, missing data dictionary>

### Next steps
1. Resolve the conflicts listed above; delete each `<!-- CONFLICT: … -->` marker as you go.
2. File or delete anything left in `## Unsorted`.
3. Review `CLAUDE.md`; correct any schema column you had to infer.
4. Run `readme` for the top-level index + each subproject.
5. Confirm the canonical run/params table.
```

Report what you did, not what the repo should look like. **No directories were created, nothing was
moved, and the repo was not audited against the folder-structure standard** — if the layout does not
match, that shows up as a note inside `## Folder structure`, not as an action here.

---

## Tips

- **Object before method.** Lead each section with the data object, then the method over it. A
  reader needs "what is `N_obs`" before "how gPCA computes it".
- **Schemas are the highest-value content.** A wrong column contract causes silent, costly errors;
  capture them exactly, from code, not filenames.
- **Don't claim status without evidence.** "complete / active / scaffolded" must come from prose or
  `git log`, not vibes.
- **Keep it scannable.** Link to stage READMEs and memory notes for depth; don't duplicate them.
- **Flag reproducibility gaps** (unpinned envs, uncontainerized steps) explicitly — that is useful
  signal, not a failure of the skill.
- **On a re-run, restructuring is the job; rewriting is not.** The value is a file whose *shape* is
  predictable, not whose *prose* is yours. If you find yourself improving a sentence that was
  already accurate, stop — that is churn, and it buries the real diff.
- **When in doubt about a block's class, treat it as reproducibility-critical.** The cost of
  relocating something verbatim that didn't need it is a few lines. The cost of rewriting a pin's
  justification, and losing the reason behind it, is a silent regression months later.
- **Deviations from the folder standard are documented, not fixed.** Write what the repo actually
  looks like and why it diverges. Moving a stage can break relative-path resolution — that is the
  author's call to make, with the pipeline in front of them.
