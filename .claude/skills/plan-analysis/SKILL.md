---
name: plan-analysis
description: "Create a comprehensive, context-rich plan for a new analysis or pipeline stage through repo + data + methods research"
argument-hint: "[analysis or stage to plan]"
---

# Plan an analysis / pipeline stage

## Analysis: $ARGUMENTS

## Mission

Turn an analysis request into a **complete implementation plan** through systematic inspection of
the repo, the data and its schemas, and the relevant methods/literature.

**Core principle**: we do NOT run the analysis or write production code in this phase. The goal is a
context-rich plan that lets an execution agent build the stage in one pass.

**Key philosophy**: *Context is king.* The plan must carry everything the executor needs — upstream
schemas, the exact method, reference-data versions, the canonical params, validation controls, and
runnable validation commands — so it succeeds on the first attempt without re-deriving context.

The unit here is an **analysis** or **pipeline stage**, not a software "feature". Artifacts are
datasets, sumstats, matrices, manifests, figures — not API endpoints.

## Running inside plan mode

Compatible, and worth doing for expensive work — but **do not produce two plans**.

This skill and plan mode are the same shape: read-only research, then a plan, then hand off. Plan
mode contributes the enforcement and the gate; this skill contributes the content.

- **Phases 1–4 are the plan-mode research phase.** No change to how you run them.
- **Phase 5's template replaces the generic plan structure.** Write it into the plan file verbatim —
  schema contracts, controls, runnable validation commands and all. A generic Context/Approach/
  Verification plan here would discard exactly what makes this skill worth invoking.
- **On approval, the draft becomes the artifact:** write it to `.claude/plans/{kebab-case-name}.md`.
  The plan file is session scratch; the repo copy is what gets committed, reviewed, and cited by a
  later `handover`. One document, written once, with an approval gate in the middle.

**Why bother.** Line 15's "we do NOT run the analysis or write production code in this phase" is a
principle this skill states and nothing enforces. In plan mode the harness enforces it — which
matters most in Phase 2, where you inspect real data, and Phase 3, where you research methods.
Both are read-heavy phases operating next to upstream trees that must not be written to.

**When it earns its cost:** the stage launches something expensive or irreversible (a cloud batch
run, a write to shared storage), or the method is unfamiliar enough that you want a human gate before
anything runs. For a routine stage at smoke scale, skip it — the skill's own discipline is enough.

## Planning process

### Phase 1: Frame the analysis

- State the **scientific question** and the inference the output licenses.
- Name the **object**: what data it operates on, and what representation (matrix? long table? VCF?).
- Classify: New stage / **Variant of an existing stage** (sensitivity, alternative threshold or
  transform, new dataset through the same method) / Extension of a stage / Re-analysis / Method swap
  / Bug fix.
- If it is a variant, the deliverable is a **params file and a results namespace**, not a new stage
  folder — see the reuse check in Phase 2. Reaching for a new folder is the default worth resisting.
- Assess complexity: Low / Medium / High, and the main risk (data, method, or compute).

Write it as:

```
As an analyst
I want to <analysis/transformation>
So that <inference / decision it supports>
```

### Phase 2: Repo + data intelligence

**1. Pipeline position**
- Where does this stage sit in the DAG? Upstream producer(s), downstream consumer(s).
- Read the upstream stage README + the workflow-index README. Mirror the orchestration pattern
  (Nextflow `main.nf` / Snakefile / driver script) used by sibling stages.

**2. Schema contracts (the load-bearing part)**
- For every input, read the **actual file header / code** — never infer columns from a filename.
- Record the exact column contract and what each non-obvious column *is* (e.g. `N_obs` = fractional
  gPCA weight, not a sample size; `p` may be `-log10`). Note units, sign conventions, and genome build.
- Define the **output schema** the downstream consumer expects.

**3. Reference data & methods**
- Catalog reference panels / ontologies / external cohorts the stage needs, **with versions**.
- Name the statistical/algorithmic method precisely; find its canonical implementation in the repo
  or the library docs. Note assumptions (e.g. LDSC `rg` observed vs liability scale) and failure modes.

**4. Compute & reproducibility**
- Backend (local / SLURM / cloud batch), profile, container/env, where it submits from.
- Canonical params/config location and naming.

**5. Reuse check (do this before naming any new file)**
- Does a stage already implement this method? `ls scripts/*/*/bin/`, then read the closest match.
- If one does and only *parameters* differ — dataset, cohort, threshold, transform, seed — this is a
  **variant**: plan a `params/sens_<name>.<ext>` and a `results/sens_<name>/` namespace against the
  existing `bin/`. Do not plan a new stage folder, and do not plan to copy `bin/`.
- If the shared script cannot express the variant, plan to **add a parameter whose default
  reproduces `main` unchanged**. That edit to `bin/` is part of this plan, and `main` must still run
  to the same result afterwards.
- Only a genuinely different method earns a new stage. When it does, say in the plan why it is not a
  variant.
- The convention is `CLAUDE.md` § Folder structure → *Variants and reuse*.

**Clarify ambiguities now.** If the method, the input run, or the success criterion is unclear, ask
before proceeding.

### Phase 3: Methods / literature research

- Confirm the method's correct usage and current best practice; capture doc links with anchors.
- Note known pitfalls (batch effects, double-counting samples, multiple-testing, indefinite
  covariance, power) relevant to this analysis.
- Identify **positive/negative controls** the field uses to sanity-check this kind of result.

```markdown
## Relevant references
- [Method docs](https://…#section) — Why: exact call + assumptions for this stage
- [Paper / vignette](https://…) — Why: control expectation (e.g. HMGCR↔LDL should colocalize)
```

### Phase 4: Strategic thinking

- How does this stage fit the existing DAG and conventions?
- Critical dependencies and order of operations.
- What could go wrong scientifically (confounds, leakage, scale/locality) and computationally
  (preemption, memory, indefinite matrices)?
- How is correctness *demonstrated* — which controls, which schema checks?

### Phase 5: Write the plan

Fill this template for the execution agent:

````markdown
# Analysis: <name>

Validate the schema contracts and method usage against the actual code/data before implementing.
Pay special attention to column names, units, sign, and genome build.

## Question & object
<The scientific question; the data object and representation; the inference the output licenses.>

## Analyst story
As an analyst / I want to <analysis> / So that <inference>.

## Pipeline position
- **Upstream:** <stage(s) + the input run/manifest>
- **Downstream:** <consumer stage(s)>  ·  **Orchestration pattern to mirror:** <file:lines>

## Reuse & variant namespace
- **Kind:** <new stage | variant of `<stage>`>
- **Implementation:** <`<stage>/bin/<script>`, reused unchanged | reused with a new parameter
  `<key>` whose default is the current behaviour | new, because the method itself differs: <why>>
- **Params:** `params/<variant>.<ext>` — `derived_from: main.<ext>`; keys that differ: `<…>`
- **Results namespace:** `results/<variant>/<run-tag>/`, isolated from `main`
- **Comparison to `main`:** <the metric and the artifact that will hold both — or "n/a, this is main">

## CONTEXT REFERENCES — READ BEFORE IMPLEMENTING

### Input schemas (verified from code/headers)
- `<path>` — columns `(…)`; <what each non-obvious column is; units/sign/build>
- ...

### Output schema (contract for downstream)
- `<path>` — columns `(…)`; <semantics>

### Reference data & methods
- <panel/ontology/cohort> — version <…>, location <path/gs://…>
- Method: <name> — canonical impl `<file>` / [docs](…#anchor); assumptions: <…>; failure modes: <…>

### Files to read / create
- READ: `<file>` (lines) — Why: <pattern/schema to mirror>
- CREATE: `<file>` — <role>

## METHOD / IMPLEMENTATION PLAN

### Phase 1: Inputs & harmonization
<prepare/validate inputs; assert schema; align build/units>

### Phase 2: Core analysis
<the method step(s); params; per-unit processing>

### Phase 3: Outputs & integration
<write outputs in the contract schema; wire into the DAG / index README>

### Phase 4: Validation
<controls, smoke run, schema/sanity checks>

## STEP-BY-STEP TASKS (execute top to bottom; each atomic + checkable)

Keywords: CREATE / UPDATE / ADD / MIRROR / RUN.

### {ACTION} {target}
- **IMPLEMENT**: <detail>
- **PATTERN**: <file:line to mirror>
- **DATA/SCHEMA**: <input contract asserted; output contract produced>
- **GOTCHA**: <known pitfall to avoid>
- **VALIDATE**: `<runnable command>`

## VALIDATION STRATEGY
There is usually no unit-test suite. Validate by:
- **Smoke run** with a tiny `--test` params variant.
- **Positive/negative controls** (state the expected result, e.g. control rg > 0.6, FTO null expected).
- **Schema/sanity checks** (column contract holds; `N_eff` positive & physically plausible; no NaN explosion).
- **Sensitivity** (if a transform/threshold is involved, re-run under an alternative and compare).

## VALIDATION COMMANDS (run all; zero schema/control failures)
```bash
<orchestrator dry-run: nextflow … -preview / snakemake -n>
<smoke run command>
<schema/control check command>
```

## ACCEPTANCE CRITERIA
- [ ] Inputs assert their schema; outputs match the downstream contract
- [ ] Positive controls recovered; negative controls null
- [ ] Smoke run passes; full run command documented
- [ ] Stage wired into the DAG and anchored in the index README
- [ ] Nothing that varies between runs is a literal in `bin/`; the run writes only to its own
      `results/<variant>/` namespace
- [ ] If a shared script gained a parameter, `main` still runs to the same result
- [ ] Provenance captured (params, reference-data versions, container/env, commit)

## NOTES
<design decisions, trade-offs, scale/locality considerations>
````

## Output format

**Filename**: `.claude/plans/{kebab-case-name}.md` (create the dir if absent).
Examples: `add-coloc-bridge-stage.md`, `reharmonise-finngen-r12.md`, `sensitivity-rint-vs-log.md`.

Agent working files all live under `.claude/` — `plans/` here, `handover/` for session state. If the
repo carries plans under some other path from a previous convention, write new ones to
`.claude/plans/` and leave the old ones where they are; do not migrate them as a side effect of
planning.

## Quality criteria

- **Schema completeness** — every input/output column contract is explicit and verified from code.
- **Control-anchored** — at least one positive (and ideally one negative) control with an expected result.
- **Runnable validation** — every task has an executable check; the plan passes the "no prior
  knowledge" test (someone new to the repo could execute it).
- **Reuse-first** — a variant reuses the owning stage's `bin/` unchanged, or adds a parameter whose
  default leaves `main` bit-identical. A copied script is a plan defect, not a shortcut.
- **Convention-consistent** — mirrors the repo's orchestration, storage, and naming patterns.

## Report

After writing the plan, return: summary of the analysis + approach; full path to the plan; complexity
and main risk; and a confidence score (#/10) for one-pass execution.

### Next skill

**`execute <plan-path>`** — quote the full path so it can be run verbatim.

If the confidence score is below ~7/10, say what would raise it *before* executing (an unresolved
schema, an unconfirmed method call, a missing control expectation) — a plan executed at low
confidence usually costs more than the round trip to firm it up.
