# claude-science-scaffold

A ready-to-inject `.claude/` folder for **scientific data / pipeline** projects. Drop it into a new
project and you immediately get a skill set tuned for pipelines, data, and runs — not web apps and
API endpoints.

It ships nine skills and a clean `settings.json`. The headline skills:

- **`create-rules`** classifies a science repo along five axes (orchestration · compute backend ·
  domain · data locality · reproducibility) and writes a `CLAUDE.md` whose highest-value content is
  the load-bearing **data schemas** and the **folder-structure standard**. Re-runnable: on a repo
  that already has a `CLAUDE.md` it restructures into the canonical skeleton, carries every existing
  fact forward, and flags contradictions instead of resolving them.
- **`readme`** maintains one top-level index that lists each subproject as a linked list item,
  plus a canonical per-subproject README.
- **`report-findings`** writes a short `REPORT.md` when a subproject finishes — results, findings,
  and a clearly **non-binding** exploratory interpretation, kept in separate labeled sections.
- **`handover`** ends a session by writing `.claude/handover/YYYY-MM-DD_<topic>.md` — decisions and
  their reasons, corrections, jobs still running, the exact next command. `prime` reads the newest
  one to start the next session already resumed.

---

## What's inside

```text
claude-science-scaffold/
├── README.md            ← this file
├── LICENSE              ← MIT
├── install.sh           ← inject .claude/ into a target project
├── .gitignore           ← note: this repo intentionally TRACKS .claude/
└── .claude/
    ├── settings.json    ← skillOverrides + safe read-only git allows
    ├── handover/        ← not shipped; created on first `handover` run (dated session state)
    ├── plans/           ← not shipped; created on first `plan-analysis` run
    └── skills/
        ├── prime/             orient on a project (CLAUDE.md + README + memory + handover)
        ├── create-rules/      generate CLAUDE.md for a scientific pipeline  ★ rewritten
        ├── readme/            top-level index + subproject README templates  ★ new
        ├── report-findings/   REPORT.md on subproject completion             ★ new
        ├── handover/          session state → handover doc for a fresh session ★ new
        ├── plan-analysis/     plan a new analysis / pipeline stage          ★ reframed
        ├── analysis-design/   Analysis Design Document (ADD) for a project  ★ reframed
        ├── execute/           implement from a plan
        └── commit/            conventional-commits with 3 detail levels
```

★ = science-specific (created or reframed for this scaffold); the rest are carried over and lightly generalized.

---

## Quick start — inject into a project

From inside this scaffold:

```bash
# 1. copy .claude/ into your project
./install.sh /path/to/your-project          # aborts if a .claude/ already exists
./install.sh /path/to/your-project --merge   # add only missing files, never overwrite
./install.sh /path/to/your-project --force    # overwrite (backs up the old .claude/ first)
./install.sh /path/to/your-project --dry-run  # preview, change nothing
```

Or manually:

```bash
cp -R .claude /path/to/your-project/.claude
```

Then open the project in Claude and run the skills below.

> Most projects `.gitignore` their `.claude/` folder. **This** repo is the exception — distributing
> `.claude/` is the whole point, so it is tracked here. Whether you commit `.claude/` in your target
> project is your call.

---

## What order to run them in

The order follows from what each skill *reads*. `analysis-design` reads the conversation,
`create-rules` reads the repo, `plan-analysis` reads the repo **and the conventions its siblings
already follow**, and `execute` reads a plan. So the right order depends on whether there is any code
yet — and it differs between the two cases.

### Greenfield — new project, empty repo

```text
analysis-design → create-rules → readme top-level → plan-analysis → execute → create-rules (re-run)
```

`analysis-design` goes **first**, because it is the only one that does not need code to exist. Its §7
(stage DAG, engine, backend, container) and §4 (data schemas) are exactly what `create-rules` would
otherwise have to detect from files nobody has written yet, so it reads the ADD and marks those
answers *declared, not detected*.

The re-run at the end matters: once the first stage exists, detection finally has something to find,
and `create-rules` restructures rather than overwrites.

### Brownfield — existing repo with code

```text
create-rules → [analysis-design] → readme top-level → plan-analysis → execute
```

`create-rules` goes first, because here the repo *is* the source of truth and its output — schemas,
conventions, folder standard — is what `plan-analysis` mirrors. `analysis-design` becomes optional:
run it when scoping a substantial new arm, skip it for a single stage.

### They don't share a cadence

The arrows above hide the real shape, which is an outer setup loop and an inner per-stage loop:

| Skill | Runs | Scope |
| --- | --- | --- |
| `analysis-design` | once per project or arm, at scoping | the question |
| `create-rules` | once early, re-run as the repo grows | the repo |
| `readme` | once per README, refreshed on drift | one folder |
| `plan-analysis` | once per stage — **many times** | one stage |
| `execute` | once per plan — **many times** | one stage |
| `report-findings` | when a subproject closes | one stage |
| `commit` / `handover` | as needed / at session end | the session |

`plan-analysis` reads the workflow-index README to place a new stage in the DAG, so
`readme top-level` should exist before the first planning run.

Each skill ends its summary by naming the recommended next one, so you can also just follow the chain
rather than memorising this.

### The rest of the loop

- Per subproject: **`readme <dir>`** — write its stage README, auto-anchored into the index.
- When a subproject finishes: **`report-findings <dir>`** — write `REPORT.md`, drop a Results pointer
  into that subproject's README, and roll the headline up into the root `REPORT.md`.
- Ending a session with work unfinished: **`handover <topic>`** — writes
  `.claude/handover/YYYY-MM-DD_<topic>.md`. Trigger it manually and early, while there is still
  context left to think with; the next session's `prime` picks it up automatically.
- Any time you need orientation: **`prime`** — reads `CLAUDE.md`, the index README, `MEMORY.md`, the
  newest handover, and minimal git state.

**Handover state vs. durable memory.** A handover expires: `prime` reads only the newest one and
treats the rest as a dated trail. So `handover` §5 splits out the facts that outlive the task — an
environment quirk, a schema gotcha, an analyst preference — into memory files indexed one line each
in `MEMORY.md`, which `prime` reads every session. Repo-wide conventions are neither; those belong in
`CLAUDE.md`.

### Pairing with plan mode

`analysis-design` and `plan-analysis` both run well inside Claude Code's plan mode; `execute` cannot
run in it at all. They are complementary rather than redundant — plan mode supplies **harness-enforced
read-only research and an approval gate**, the skills supply **the domain template and a durable repo
artifact**.

One rule keeps them from colliding: **the plan file is the draft, and on approval it becomes the
artifact.** Draft the ADD or the analysis plan straight into the plan file using the skill's own
template — not a generic Context/Approach/Verification layout — then write it to
`ANALYSIS_DESIGN.md` or `.claude/plans/{name}.md` once approved. Never produce both.

Roughly: **skip** plan mode for a routine stage at smoke scale, **use** it when execution is expensive
or irreversible, or when scoping a new project or arm. Each skill states its own threshold — see
*Running inside plan mode* in [`plan-analysis`](.claude/skills/plan-analysis/SKILL.md) and
[`analysis-design`](.claude/skills/analysis-design/SKILL.md), and *Plan mode: exit first* in
[`execute`](.claude/skills/execute/SKILL.md).

### The ADD and `project_<ARM>.yaml`

They are the same content in two forms. The ADD is prose, written once at scoping; the arm's
`project_<ARM>.yaml` is its structured, living counterpart — question, provenance,
frozen/open decisions, blockers, input contract, phases, closure gates, known hazards — which tracks
those decisions as they freeze. Write the ADD first, then keep the YAML current.

---

## The folder-structure standard

> **Canonical definition:** [`.claude/skills/create-rules/SKILL.md`](.claude/skills/create-rules/SKILL.md)
> § *Folder structure*. That tree is the one `create-rules` writes into every generated `CLAUDE.md`;
> the summary here is orientation, not a second specification.

Three rules carry the weight:

- **The root holds housekeeping only.** Every analysis — including the first one — is a subproject at
  `scripts/<arm>/<stage>_<ARM>/`, with a required `bin/ configs/ params/ tests/ docs/ results/` and a
  README. Run outputs go in `results/<run-tag>/`; a stage that grows an `output/` has drifted.
- **The two root exceptions are libraries, not subprojects.** A vendored engine fork and `docker/`
  stay at root. Anything that *is* an analysis moves under `scripts/<arm>/`.
- **Stage depth is load-bearing.** A stage reaching a root-level library via
  `${projectDir}/../../../…` breaks silently if it moves up or down a level.

`create-rules` **documents** this standard; it never creates directories, moves files, or audits a
repo against it. Cleaning up an existing layout stays a deliberate, human-initiated act.

---

## The README + findings model

> **Canonical templates:** [`readme/SKILL.md`](.claude/skills/readme/SKILL.md) (Template A = index,
> Template B = subproject) and [`report-findings/SKILL.md`](.claude/skills/report-findings/SKILL.md)
> (`REPORT.md` + the root rollup). The section lists live there; this is the shape they make together.

Four files, each with one job:

| File | Role |
| --- | --- |
| Top-level `README.md` | The index. A numbered *Workflow order* list; every subproject anchors itself here as one linked item at its real path. |
| Arm `README.md` | The index scoped to one arm, linking back up. |
| Subproject `README.md` | Fixed template. Its `Results` section is a 2–4 line headline that links onward. |
| Subproject `REPORT.md` | The full results. Links up into the root `REPORT.md` rollup. |

Two rules make it work, and both are about **not letting a hypothesis harden into a result**:

- **`REPORT.md` separates Findings from Exploratory interpretation.** Findings are statements the
  results support, each tied to a number. Interpretation is explicitly non-binding — hypotheses,
  hedged, each paired with what would test it. The README stays short and durable; the hedged reading
  lives in the report where it can't bloat the index.
- **Only findings travel upward.** A hedged reading that reaches the root rollup loses its hedge on
  the way and starts getting cited as a project-level result. The root's
  `## Synthesis across subprojects` is author-maintained for the same reason — `report-findings`
  seeds it once and never writes it again.

This mirrors a pattern that already works in practice: a short Results section in the README plus a
fuller run-level summary alongside the outputs.

The workflow is also written into the `CLAUDE.md` that `create-rules` generates (under "Working with
this repo via Claude"), so a future session rediscovers it without reading this file.

---

## Extending `settings.json` (optional)

`settings.json` ships minimal (safe read-only git allows + `prime`/`commit` on). Common additions
for science projects, when they apply to your stack:

Read-only cloud/orchestrator allows (cut the prompt noise on inspection commands):

```json
"permissions": {
  "allow": [
    "Bash(gcloud storage ls:*)",
    "Bash(gcloud storage cat:*)",
    "Bash(nextflow log:*)"
  ]
}
```

A convention guard as a `PreToolUse` hook — e.g. steer `gsutil` → `gcloud storage` (gsutil crashes
on large ops):

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "command": "cmd=$(jq -r '.tool_input.command // \"\"'); echo \"$cmd\" | grep -qF 'gsutil ' && jq -n '{hookSpecificOutput:{hookEventName:\"PreToolUse\",permissionDecision:\"deny\",permissionDecisionReason:\"Use `gcloud storage` instead of `gsutil`.\"}}' || exit 0"
        }
      ]
    }
  ]
}
```

Keep machine-specific allow-lists in a personal `settings.local.json` (gitignored), not in the
shipped `settings.json`.

---

## Starting a new project from the scaffold

```bash
git clone https://github.com/micpreuss/claude-science-scaffold.git
./claude-science-scaffold/install.sh /path/to/new-project
```

`install.sh` prints the right first skill for the project you just set up — `analysis-design` on an
empty repo, `create-rules` on one that already has code.
