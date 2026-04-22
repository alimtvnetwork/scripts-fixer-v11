# Generic Install Spec — Awaiting Checklist Confirmation

## Description
User asked for a generic, cross-repo install-script behavior spec covering strict release-tag mode, main-branch fallback, and versioned-repo discovery (v1..v20 parallel). A 15-item confirmation checklist was posted in chat covering naming, discovery range, probe mechanism, strict-mode triggers, and spec file layout. Implementation is **blocked** until the user replies with per-item confirmations.

## Root Cause
Several semantic ambiguities in the original brief that must be resolved before the spec can be written generically and unambiguously:
- "Next twenty repos" was clarified to mean **fixed window v1..v20** (latest user msg) — but earlier they said "both directions current-1 + current+20". Need final lock-in.
- Whether discovery should auto-upgrade or just log.
- Exact strict-mode triggers (flag names, env-var names, URL patterns).

## Steps to Reproduce
1. User runs `quick-install` / `release-install` / `error-manage` from any repo.
2. Behavior should match the generic spec — but the spec doesn't exist yet.

## Attempted Solutions
- [x] Draft 15-item checklist posted to user — awaiting reply
- [ ] Write 7 spec files under `spec/00-generic-install-script-behavior/`
- [ ] Update `mem://features/install-bootstrap` to reference the generic spec
- [ ] Produce per-repo migration plan

## Priority
High — user explicitly asked for this and wants to share the spec with other AIs.

## Blocked By
User confirmation on the 15-item checklist (see chat).
