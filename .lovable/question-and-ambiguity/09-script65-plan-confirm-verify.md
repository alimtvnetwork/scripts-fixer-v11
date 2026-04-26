# 09 — Script 65: plan-then-confirm + final verify wiring

**Spec reference:** "Wire plan-then-confirm and a final verify step into
script 65 and add a matching summary output for each action."

## Inference used (Option B)

Followed the same plan→confirm→apply→verify pattern that scripts 66/67
already use via `_shared/confirm.sh` + `_shared/verify.sh`, instead of
inventing a new confirmation/verification surface. Apply mode now does:

1. Forced dry-run pass (PLAN), targets emitted to `targets.tsv` via a
   new `SW_TARGETS_TSV` opt-in in `helpers/sweep.sh`.
2. `confirm_render_plan` + `confirm_prompt` (honours `--yes`).
3. Real apply pass on approval; abort leaves `plan.tsv` for inspection.
4. `verify_run` + `verify_render` re-probes every targeted path.
5. Summary table extended with a per-row **VERIFIED** column
   (`PASS(n)` / `FAIL(n)` / `-`) plus a global `VERIFY: pass/fail/skipped` line.
6. `manifest.json` gains a `verification` block (parity with 66/67).

`--dry-run` keeps its single-pass behaviour (no plan/confirm wrapper)
but still runs verify so the operator can preview "would these be gone?".
`LOGS_OVERRIDE` now honoured (parity with 66/67) so the smoke test can
sandbox logs.

Smoke test result: **21/21 PASS** unchanged.

## How to revert

Revert the additions in `scripts-linux/65-os-clean/run.sh` (the
`confirm.sh`/`verify.sh` source lines, the `_iterate_all_categories`
wrapper, the plan/confirm/verify blocks, the VERIFIED column, and the
manifest `verification` block) and the `_sw_emit_target` helper +
per-primitive emit calls in `helpers/sweep.sh`.