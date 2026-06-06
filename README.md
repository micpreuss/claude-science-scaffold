# claude-science-scaffold

A ready-to-inject `.claude/` folder for **scientific data / pipeline** projects. Drop it into a new
project and you immediately get a skill set tuned for pipelines, data, and runs — not web apps and
API endpoints.

It ships eight skills, a README-curator agent, and a clean `settings.json`. The headline skills:

- **`create-rules`** classifies a science repo along five axes (orchestration · compute backend ·
  domain · data locality · reproducibility) and writes a `CLAUDE.md` whose highest-value content is
  the load-bearing **data schemas**.
- **`create-readme`** maintains one top-level index that lists each subproject as a linked list item,
  plus a canonical per-subproject README.
- **`report-findings`** writes a short `REPORT.md` when a subproject finishes — results, findings,
  and a clearly **non-binding** exploratory interpretation, kept in separate labeled sections.

---

## What's inside

```
claude-science-scaffold/
├── README.md            ← this file
├── LICENSE              ← MIT
├── install.sh           ← inject .claude/ into a target project
├── .gitignore           ← note: this repo intentionally TRACKS .claude/
└── .claude/
    ├── settings.json    ← skillOverrides + safe read-only git allows
    ├── agents/
    │   └── readme-curator.md
    └── skills/
        ├── prime/             orient on a project (CLAUDE.md + index README + git state)
        ├── create-rules/      generate CLAUDE.md for a scientific pipeline  ★ rewritten
        ├── create-readme/     top-level index + subproject README templates ★ new
        ├── report-findings/   REPORT.md on subproject completion            ★ new
        ├── plan-analysis/     plan a new analysis / pipeline stage         ★ reframed
        ├── analysis-design/   Analysis Design Document (ADD) for a project ★ reframed
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

## Recommended first run

1. **`prime`** — orient: reads `CLAUDE.md`, the index README, and minimal git state.
2. **`create-rules`** — generate `CLAUDE.md`. It classifies the repo (five axes) and captures the
   data-schema contracts. Review the schemas it writes.
3. **`create-readme top-level`** — write the index README that lists your subprojects.
4. Per subproject: **`create-readme <dir>`** — write its stage README, and auto-anchor it as a list
   item in the index.
5. Work the analysis (**`plan-analysis`** → **`execute`** → **`commit`** as useful; for a larger
   project, **`analysis-design`** first to scope question/data/methods).
6. When a subproject finishes: **`report-findings <dir>`** — write `REPORT.md` and drop a short
   Results pointer into that subproject's README.

The README + report workflow is also written into the `CLAUDE.md` that `create-rules` generates
(under "Working with this repo via Claude"), so a future session rediscovers it automatically.

---

## The README + findings model

- **Top-level README** = the index. One numbered "Workflow order" list; each subproject is one
  linked list item. New subprojects anchor themselves here.
- **Subproject README** = fixed template (Orientation · Purpose · Inputs · Outputs · Workflow · How
  to run · Key decisions/gotchas · **Results** · Related). The `Results` section is a 2–4 line
  headline that links to `REPORT.md`.
- **`REPORT.md`** = the full results for a finished subproject. Crucially, it separates **Findings**
  (statements the results support, tied to a number) from **Exploratory interpretation**
  (hypotheses — explicitly non-binding, each paired with what would test it). The README stays short
  and durable; the longer hedged interpretation lives in the report.

This mirrors a pattern that already works in practice: a short Results section in the README plus a
fuller run-level summary alongside the outputs.

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

## Deploy this scaffold to GitHub

From the unzipped folder, initialize git and publish it under your account:

```bash
cd claude-science-scaffold
git init -b main
git add .
git commit -m "Initial commit: claude-science-scaffold"

# with the GitHub CLI:
gh repo create micpreuss/claude-science-scaffold --public --source=. --remote=origin --push

# or manually, after creating an empty repo on github.com:
git remote add origin https://github.com/micpreuss/claude-science-scaffold.git
git push -u origin main
```

After that, starting a new project is just:

```bash
git clone https://github.com/micpreuss/claude-science-scaffold.git
./claude-science-scaffold/install.sh /path/to/new-project
```
