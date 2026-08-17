---
name: report-findings
description: Write a short completion REPORT.md for a finished subproject — results, findings, and a clearly non-binding exploratory interpretation — link it from the subproject README, and roll its headline up into the root REPORT.md
argument-hint: "[<subproject-dir>] [run-tag]"
---

# report-findings

When a subproject (pipeline stage / analysis) reaches a reportable state, write a **short**
`REPORT.md` that a returning reader — or a collaborator who never saw the run — can read in two
minutes to know *what came out, what it shows, and what it might mean*.

The report is built around one hard distinction:

- **Findings** = statements the results **support**. Tied to a number or an output. Durable.
- **Exploratory interpretation** = **hypotheses** the findings *suggest*. Explicitly **non-binding** —
  "not consequences chiseled in stone", a quick way to build intuition, to be confirmed or dropped
  by later work. Hedged language only.

Keeping these two in separate, labeled sections is the point of the skill. Never let interpretation
masquerade as a finding.

---

## Where it goes — three files, in this order

1. **`REPORT.md` at the subproject root** — the canonical/latest run's report. This is the default.
   For a run-specific report, write `output/<run-tag>/REPORT.md` and have the subproject `REPORT.md`
   link to the per-run ones.
2. **The subproject README's `## Results` section** — a 2–4 line headline + a link to `REPORT.md`.
   The README stays the scannable index; the report carries the detail. (Use the `readme` skill's
   Template B if the README has no `## Results` section yet.)
3. **The root `REPORT.md`** — the project-level rollup. Every subproject that reaches a reportable
   state gets one block there. See "Rolling up to the root REPORT.md" below.

> Rationale for separate-file-plus-pointer: it matches the repo's existing pattern (a short Results
> section in the README, with the full narrative in `summary.md`/`validation_report.md` per run). The
> README stays short and durable; the longer, hedged interpretation lives where it won't bloat the
> index.

---

## Before writing — gather the evidence

Do not summarize from memory. Read the actual outputs.

- Read the subproject README (Purpose, Inputs, Outputs, How to run) for context.
- List and read the **output artifacts** (result tables, `summary.*`, validation reports, key figures).
  Pull the headline numbers directly from them.
- Recover **provenance**: which params/config produced this run, input dataset + version, container
  image/tag or env, the commit (`git rev-parse --short HEAD`), and the date (`git log -1` or run logs).
- Note any **positive/negative controls** the stage defined and whether they passed.

If a number isn't in an artifact you can read, don't put it in the report.

---

## REPORT.md template

````markdown
# <subproject> — Results report

**Run / dataset:** <run-tag> on <dataset + version>
**Status:** <final | interim>  ·  **Date:** <YYYY-MM-DD>  ·  **Commit:** <short-sha>
**Headline:** <one sentence: the single most important outcome.>

## Results

<The concrete outputs and numbers. A table is usually right. State the metric, the value, and where
it came from — not what it means yet.>

| Metric / output | Value | Source artifact |
|---|---|---|
| <e.g. clusters recovered> | <e.g. 15> | `output/<run>/…` |
| <e.g. positive control PP.H4 (HMGCR↔LDL)> | <e.g. 0.97 — PASS> | `output/<run>/…` |

<Controls: state explicitly which passed/failed.>

## Findings

<3–6 bullets. Each is a statement the results above SUPPORT, tied to a number/output. Factual,
mechanistic, present-tense. No speculation here.>

- <finding tied to a result>
- ...

## Exploratory interpretation  *(non-binding — hypotheses, not conclusions)*

> These readings are exploratory: a fast way to build intuition about what the findings *might*
> mean. They are **not** established results and should not be cited as conclusions. Treat each as a
> hypothesis to confirm, revise, or drop in later work.

- <hedged reading: "consistent with …", "may indicate …", "one explanation is …"> — *to confirm: <what would test it>.*
- ...

## Caveats / limitations

<What could undercut the findings: power, sample size, multiple testing, confounds, untested
assumptions, known data gotchas that apply to this run, scope the result does NOT cover.>

- ...

## Next steps  *(optional, non-committal)*

- <suggested follow-ups; clearly not promises>

## Provenance / reproducibility

- **Command:** `<exact invocation, e.g. nextflow run … -params-file … -profile …>`
- **Params/config:** `<path>`  ·  **Input:** `<dataset + version/path>`
- **Environment:** `<container image:tag or env lockfile>`  ·  **Commit:** `<short-sha>`
- **Outputs:** `<output dir / bucket path>`
````

### Subproject README `## Results` pointer (insert/refresh)

````markdown
## Results

<2–4 line headline of the canonical run's outcome, including whether controls passed.>
See [`REPORT.md`](REPORT.md) for full results, findings, and exploratory interpretation.
````

---

## Rolling up to the root REPORT.md

Every subproject report also lands as one block in the root `REPORT.md` — the project-level answer to
"what has this project actually produced?". Create the file if it does not exist; otherwise refresh
only this subproject's block.

````markdown
# <project> — Results

Rollup of every subproject that has reached a reportable state. Each entry is a headline; follow the
link for full results, findings, and exploratory interpretation.

## Synthesis across subprojects

<Author-maintained. What the subprojects say when read together — the cross-cutting result that no
single report states on its own.>

## Findings by subproject

### <stage> — [REPORT.md](scripts/<arm>/<stage>_<ARM>/REPORT.md)

**Run:** <run-tag> · **Status:** <final | interim> · **Date:** <YYYY-MM-DD> · **Commit:** <short-sha>

<2–4 lines: the headline plus the one or two findings that matter at project level, each tied to its
number. Lifted from the subproject report's Findings — never from its interpretation.>

## Not yet reported

- <subproject> — <status, from the root README's workflow list>
````

### Rules for touching this file

- **`## Synthesis across subprojects` is the author's.** Seed it once, on creation, with a one-line
  stub saying it is theirs to write. After that, **never** write, extend, or re-word it — not even
  when a new subproject seems to change the picture. Reading two reports and declaring what they
  jointly mean is exactly the judgment this skill is not entitled to make.
- **Update in place, narrowly.** Replace only this subproject's `###` block; add it if absent; leave
  every other block byte-for-byte alone. Move the subproject out of `## Not yet reported` when it
  gains a block.
- **Only findings propagate upward.** Exploratory interpretation stays in the subproject report.
  A hedged reading that travels to the project level loses its hedge on the way and starts getting
  cited as a result — so it does not travel.
- **Keep each block to 2–4 lines.** The root file is an index with headlines, not a compilation. If
  a reader needs more, the link is right there.
- **Order blocks to match the root README's workflow order**, not by date — a reader arriving from
  the README should find the same sequence.

---

## Workflow when invoked

1. **Locate** the subproject (argument or cwd) and the run (argument or the canonical/latest run).
2. **Read** the README + output artifacts; extract headline numbers and control outcomes; recover provenance.
3. **Draft** `REPORT.md` from the template. Enforce the split:
   - Anything causal/speculative goes under **Exploratory interpretation** with hedged wording and a
     "to confirm" note — never under Findings.
   - Every Results-table number must trace to a named artifact.
4. **Write** `REPORT.md` (subproject root by default; `output/<run>/REPORT.md` for run-specific).
5. **Update the subproject README:** insert/refresh the `## Results` headline + link. If the README
   lacks a `## Results` section, add it (per `readme` Template B) directly before `## Related`.
6. **Roll up to the root `REPORT.md`:** create it from the template if absent (with the synthesis
   stub); otherwise replace only this subproject's `###` block and move it out of
   `## Not yet reported`. Verify the relative link resolves at the real depth.
7. **Report back:** path(s) written — all three; the one-sentence headline; an explicit list of which
   statements you placed under *interpretation* vs *findings*, so the author can sanity-check the
   split; and, if the root file was created, a note that `## Synthesis` is waiting on them.

## Anti-patterns to avoid

- **Interpretation creep** — writing "X causes Y" in Findings when the data only shows association.
  If you can't point at the number that proves it, it's interpretation.
- **Numbers without a source** — every value cites the artifact it came from.
- **Over-long reports** — this is a 1–2 minute read, not a manuscript. Push depth into the artifacts.
- **Silent overwrite** — if `REPORT.md` exists for a different run, don't clobber it; write the new
  run's report under `output/<run>/` and link both from the root.
- **Confident hedging** — interpretation bullets must actually read as tentative; pair each with what
  would test it.
- **Writing the root synthesis** — the tempting one. You have just read a report in detail and the
  cross-subproject story looks obvious. It is still the author's section; leave it.
- **Promoting interpretation to the root** — a hypothesis that reaches the project-level rollup
  reads as a project-level result. Only findings go up.
- **Rewriting sibling blocks** in the root file "while you're there". Touch one block per run.
