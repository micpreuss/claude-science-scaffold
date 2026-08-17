---
name: commit
description: Create a new commit for uncommitted changes with configurable detail level
---

# commit

Create a new commit for uncommitted changes. Choose commit detail level via the `mode` parameter.

## Parameters

`mode` — commit message detail level (default: `standard`)

- **`simple`** — Atomic, single-line message. Use for: typos, one-liner fixes, minor tweaks needing no context.
  - Format: `scope: atomic description`
  - Example: `fix(preprocessing): correct variant filter threshold`

- **`standard`** — Message + context. Use for: bug fixes with explanation, stage updates, or schema changes.
  - Format: scope + short description, then bulleted changes (what was wrong/missing, how it's fixed)
  - Example: `fix(qc): gate on positive N_eff for downstream stability`

- **`comprehensive`** — Full narrative for substantial work. Use for: new pipeline stages, major refactors, cross-stage integration.
  - Format: scope + headline, then sections (Problem, Solution, Changes, Validation, Notes)
  - Includes: context, design rationale, validation evidence, edge cases

## Workflow

1. Run `git status --porcelain && git diff HEAD --stat` to review changes. `git diff HEAD` alone
   does **not** show untracked files — `--porcelain` is what surfaces them.
2. **Screen untracked paths before staging** (see below), then stage what survives the screen.
3. Compose the commit message (length/detail depends on `mode`)
4. Create the commit with a conventional-commits tag

### Staging guard — do not blanket-stage a science repo

This is the one workflow step where a generic `git add -A` habit does real damage. Analysis repos
routinely hold, untracked and unignored, things that must never enter git history: run outputs under
`results/`, scratch `data/`, orchestrator `work/` and `.nextflow/` trees, `logs/`, figure dumps, and
— the costly one — service-account keys or tokens pasted into a `params/` or `configs/` file.

Before staging, list untracked paths and screen them:

```bash
git status --porcelain --untracked-files=all
git check-ignore -v <path>...   # which .gitignore rule, if any, already covers these
```

- **Never auto-stage** anything under `results/`, `data/`, `logs/`, `work/`, `.nextflow/`, `figures/`,
  or any file over ~1 MB. Name them to the user and let them decide.
- **A credential-shaped file is a stop, not a prompt.** If an untracked config or params file holds
  something that looks like a key, token, or connection string, say so and stage nothing until the
  user responds.
- **An untracked artifact that should have been ignored is a `.gitignore` bug.** Offer the rule
  rather than staging the file — the scaffold's `.gitignore` ships commented patterns for exactly
  these paths.
- Modified files already tracked in git are safe to stage without this screen.

## Next skill

Report the SHA and the one-line subject, then name what follows from what was just committed:

- Committed a **finished stage whose results are not yet written up** → `report-findings <dir>`.
  If the commit you just made *contained* the `REPORT.md`, this step is already done — skip it and
  fall through to the next rule rather than looping back.
- Committed **partial work** and the session is ending → `handover <topic>`
- Committed a **new stage** that changed the DAG → `readme top-level` to re-anchor the index
- Otherwise → back to `plan-analysis` for the next stage, or nothing.

## Tags

- `feat(scope)` — New analysis stage or capability
- `fix(scope)` — Bug fix or correctness repair (data bug, schema, parser)
- `refactor(scope)` — Restructuring, no behavior change
- `docs(scope)` — README / CLAUDE.md / REPORT.md / comments
- `data(scope)` — Reference data, schema, or data-dictionary changes
- `test(scope)` — Smoke configs, controls, test fixtures
- `perf(scope)` — Performance / runtime optimization
- `ci(scope)` — CI / build / container changes
- `chore(scope)` — Dependencies, config, tooling

Scope = the folder/stage changed (e.g. `fix(pipeline):`, `feat(genomic_sem):`). Keep it lowercase;
join nested multi-word scopes with underscores (e.g. `fix(coloc_qtl):`).

## Examples by mode

### Simple

```text
fix(preprocessing): remove stale ID column reference
```

### Standard

```text
fix(clustering): gate on min_cluster_size for stability

High-variance traits inflate density-clustering noise, producing spurious
single-object clusters. Applied a min_cluster_size threshold to gate out
micro-clusters that don't replicate across seeds.

Changes:
- Add min_cluster_size param to the clustering config
- Document the threshold rationale in the stage README
- Re-run sensitivity (pending)
```

### Comprehensive

```text
Add per-cluster latent GWAS export + downstream rg scaffolding

The clustering stage now emits per-cluster latent sumstats ready for the
downstream correlation analysis. Scaffolds the disease-rg consumer.

Problem:
- Upstream produced cluster manifests but no per-cluster sumstats for downstream rg
- Disease rg needs per-cluster weighting; full-manifest correlation conflates clusters

Solution:
- Per-cluster gPCA → latent GWAS sumstats (full variant resolution)
- LDSC rg on per-cluster sumstats × disease phenotypes

Changes:
- Add the per-cluster gPCA + export process to the pipeline
- Add the canonical params for the reference run
- Update the workflow-index README data-flow diagram

Validation:
- Smoke run (2 clusters, 2 diseases) passed
- Reference run recovered the expected positive control (cluster–disease rg > 0.6)

Notes:
- Downstream enrichment stage not yet built
```

## Notes

- Commits do not include a "Co-Authored-By" footer
- For changes touching multiple stages, lead with the primary stage; mention secondary in the body
- Match `commit` mode to the size of the change — don't write a narrative for a typo
