---
name: execute
description: Execute an implementation/analysis plan
argument-hint: "[path-to-plan]"
---

# Execute: Implement from Plan

## Plan to Execute

Read plan file: `$ARGUMENTS`

## Plan mode: exit first

**This skill cannot run in plan mode.** Implementing tasks and running validation commands are
exactly what plan mode forbids. Plan mode is this skill's precursor, not a wrapper for it.

If you are in plan mode holding a finished plan, that is the signal to **exit**, not to plan again.
Do not re-derive a plan `plan-analysis` already wrote — call `ExitPlanMode`, get approval, then
execute the existing plan against its own tasks and acceptance criteria.

## Execution Instructions

### 1. Read and Understand

- Read the ENTIRE plan carefully
- Understand all tasks and their dependencies
- Note the validation commands to run
- Review the testing / validation strategy

### 2. Execute Tasks in Order

For EACH task in "Step by Step Tasks":

#### a. Navigate to the task
- Identify the file and action required
- Read existing related files if modifying (and the real data headers before writing any parser)

#### b. Implement the task
- Follow the detailed specifications exactly
- Maintain consistency with existing code patterns and the project's conventions (schemas, units, sign preservation)
- Document non-obvious choices; log where the project logs
- **Never hard-wire what a re-run would change** — dataset paths, cohort names, thresholds,
  transforms, seeds and output roots belong in `params/`, not in `bin/`. This is the whole of what
  makes the stage re-runnable for a sensitivity analysis or a new dataset later.
- **Write to the variant's namespace** — `results/<variant>/<run-tag>/`, with the variant tag read
  from the params file, never a path literal.
- **If the plan has you copying an existing script, stop.** Add a parameter to the shared one whose
  default reproduces the current behaviour, so `main` still runs to the same result. A forked
  implementation is how a sensitivity analysis quietly stops testing the same method. If the method
  genuinely differs, that is a new stage — say so before writing it.

#### c. Verify as you go
- After each change, check syntax (and that the orchestrator graph still parses, e.g. `nextflow ... -preview` / `snakemake -n`)
- Ensure imports/dependencies resolve
- Confirm any new data schema matches the documented column contract

### 3. Implement the Validation Strategy

After completing implementation tasks:

- Create the tests / smoke configs specified in the plan
- Implement the positive/negative controls the plan names
- Cover the edge cases the plan lists

### 4. Run Validation Commands

Execute ALL validation commands from the plan in order:

```bash
# Run each command exactly as specified in the plan
```

If any command fails:
- Fix the issue
- Re-run the command
- Continue only when it passes

### 5. Final Verification

Before completing:

- ✅ All tasks from the plan completed
- ✅ Tests / smoke runs created and passing
- ✅ All validation commands pass
- ✅ Code follows project conventions and schema contracts
- ✅ Nothing that varies between runs is a literal in `bin/`; each run wrote only to its own
  `results/<variant>/` namespace
- ✅ If a shared script gained a parameter, `main` still runs and produces the same result
- ✅ Documentation (stage README / CLAUDE.md) updated as needed

## Output Report

### Completed Tasks
- Tasks completed; files created (paths); files modified (paths)

### Validation Added
- Tests / smoke configs / controls implemented and their results

### Validation Results
```bash
# Output from each validation command
```

### Ready for Commit
- Confirm changes complete and validations pass

### Next skill

In order, skipping what does not apply:

1. **`readme <dir>`** — if this created a new subproject, it has no README yet and is not anchored
   in the index.
2. **`commit`** — validations pass, so the work is committable.
3. **`report-findings <dir>`** — only if the stage produced *results*, not merely code that runs. A
   passing smoke run is not a result.
4. **`handover <topic>`** — if the plan is only partly executed and the session is ending.

Name the exact next invocation, and say plainly which plan tasks are still outstanding.

## Notes

- If you hit issues not addressed in the plan, document them
- If you must deviate from the plan, explain why
- If validation fails, fix until it passes — don't skip validation steps
