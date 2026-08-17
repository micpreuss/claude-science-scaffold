---
name: handover
description: Capture the current session's state into a handover document in .claude/handover/ so a fresh session can be primed with it
argument-hint: "[topic-slug]"
---

# handover

Write the delta between **what the repo says** and **what this session knows**, so the next session
starts primed instead of re-deriving it.

## Objective

A fresh session reads `CLAUDE.md`, the index README, the subproject README, and `MEMORY.md`. It gets
**none** of this session's reasoning: the decisions, the corrections, the rejected alternatives, the
numbers computed in scratch, the jobs left running, the one command to type next.

Capture exactly that. **Anything a reader could get from `CLAUDE.md` or a README does not go in** —
link instead. Purpose, inputs, outputs, workflow, how-to-run, and key locations are all README
content; if you are writing them here, delete them.

## When to use

Invoked **manually by the user**, once, to end a session — not on a schedule and not updated
mid-session. Each invocation writes a new dated file; `prime` reads the newest one.

Write it while there is still context left to think with. A handover composed at 95% context is
written by an agent that already lost the detail it was supposed to capture.

If the work is *finished*, you want `report-findings` and a `REPORT.md`, not this.

---

## Process

### 1. Read the README first — it defines what you must not write

Read the subproject README(s) this work touches, plus the top-level index and `CLAUDE.md`. This is
the subtraction pass: every fact already there is disqualified from the handover.

If the session made a README **wrong** — a renamed output, a changed input, a workflow step that no
longer matches — fix the README, and note in §5 that you did. Do not leave the correction living
only in the handover.

### 2. Gather live state — run the commands, do not recall

Recalled state goes stale within a session. **Execute and paste real output.**

```bash
git log --oneline -8
git status --porcelain
git diff --stat HEAD
```

If compute is or might be running, check it with whatever this repo uses (`CLAUDE.md` names the
orchestration and compute backend) — `squeue -u "$USER"`, `nextflow log | tail -5`,
`snakemake --summary`, `ps -eo pid,etime,cmd | grep '[m]y-job'` — and check whether output actually
landed (`ls -la <output-dir>/`). Anything that failed to run, and why, is itself handover
information.

### 3. Tag provenance on every material fact

A reader must be able to tell a measured number from an assumed one.

| Tag | Meaning | Rule |
|---|---|---|
| `VERIFIED` | Observed this session | Give the command or file that produced it. If it came from an uncommitted scratch join, say so. |
| `COMMITTED` | In the repo | Give the SHA and path. |
| `ASSERTED` | Believed, unchecked | Say what would check it. |
| `ASSUMED` | The work rests on it | Say what breaks if it is wrong. |

Then capture the four things that exist nowhere but the context window:

1. **Decisions + rationale** — what was chosen and *why that instead of the alternative*. A decision
   without its reason gets silently re-litigated.
2. **Corrections** — what was believed and turned out wrong. Highest-value section: without it the
   next session confidently re-derives the same error.
3. **Rejected alternatives** — considered and dropped, with the reason, so they don't return as
   fresh ideas.
4. **Scratch numbers not in the repo** — record the value *with the command that reproduces it*, or
   say plainly it must be recomputed.

Schema discoveries get special handling: a renamed column, a unit or sign convention, a join key
that isn't unique. Durable → fix `CLAUDE.md` or write a memory file and link it. True only of the
in-flight work → it belongs here.

### 4. Write to `.claude/handover/`

```bash
mkdir -p .claude/handover
```

Filename `.claude/handover/YYYY-MM-DD_<topic-slug>.md` — date first so the newest sorts last and
`prime` can find it mechanically. Use `$ARGUMENTS` for the slug. State the path back to the user.

If a file already exists for today's date, **overwrite it** — same day, same handover, and a newer
snapshot strictly supersedes the older one. This keeps "newest file" unambiguous for `prime`.

Do not edit handovers from earlier dates. They are a dated trail; only the newest is read. If this
session finished work an older one describes, one line in §1 saying so is enough.

### 5. Split durable facts into memory

Handover is *task state* — disposable once the work lands. Memory is *durable knowledge* — the
environment quirk, the schema gotcha, the user preference that still matters in three months. Write
those as memory files with a `MEMORY.md` pointer and **link** them here; never copy.

### 6. Cold-read check

Re-read it holding only `CLAUDE.md` and the README. It fails unless:

- [ ] The next action is a command or an edit to a named file — not "continue the work".
- [ ] Every path is real (`ls` / `test -f` it; do not trust recall).
- [ ] Every claim carries a tag; every decision carries its reason.
- [ ] Every number has a reproducing command or is flagged "recompute before use".
- [ ] Running jobs list run dir, job id, where output lands, and how to tell success from failure.
- [ ] Constraints that cause damage if forgotten are stated — read-only upstream trees, where jobs
      must be submitted from, identifiers that must never be reused, mandated tool substitutions.
- [ ] Nothing restates the README or `CLAUDE.md`.

---

## Output template

Drop sections that are genuinely empty. Never drop §1 or §2.

````markdown
# Handover — <topic>

Date: <YYYY-MM-DD> · Anchor commit: `<sha>` on `<branch>`
Context: [CLAUDE.md](../../CLAUDE.md) · [<subproject README>](<path>) · [memory](<link>)

## 1. State, in one paragraph

<What this work is, what state it reached, what blocks it. Object, method, limitation, decision.
State, not narrative — no timeline of what happened when.>

## 2. Next action

<One thing: a command, or an edit to a named file. Name any prerequisite first.>

```bash
<exact command>
```

Expected: <what success looks like>. If instead <X>: <what that means, where to look>.

## 3. In flight / uncommitted

| What | Where | State |
|---|---|---|
| <run tag / branch / file> | <run dir, output prefix, path> | <running since / staged / untracked> |

<For a long-running job: run dir, job id, launch command, where output lands, and how to tell
"still running" from "hung" from "failed".>

## 4. Decisions

| Decision | Reason | Alternative rejected, and why |
|---|---|---|

## 5. Corrections — read before trusting anything upstream

<What was believed and is now known wrong, with the corrected version. Include corrections to the
README, `CLAUDE.md`, or memory — and say whether you fixed the source or it is still stale.>

## 6. Numbers and their provenance

| Quantity | Value | Provenance | Committed? |
|---|---|---|---|

<Flag anything from an uncommitted scratch join "recompute before publishing".>

## 7. Open questions for the analyst

<Decisions that are the user's, not the agent's. Options, then a recommendation.>

## 8. Gotchas

<Environment quirks found this session; traps that cost time. Repo-wide conventions belong in
`CLAUDE.md` — link, do not copy.>
````

---

## Notes

- **Terse and mechanistic.** The reader is the analyst who built this project. No preamble, no recap.
- **Link, never duplicate.** The copy is always the one that goes stale.
- **Do not commit unless asked** — follow the repo's convention in `CLAUDE.md`.
- **"Work is progressing" is a failed handover.** Be specific enough that the next session's first
  tool call is productive.
- **Do not launder uncertainty.** If you don't know whether a run finished, write "unknown — check
  with `<command>`". A confident wrong statement is worse than an admitted gap.
