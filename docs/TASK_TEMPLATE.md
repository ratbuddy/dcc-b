# TASK_TEMPLATE.md
Version: 0.1

This template is used to define agentic or human tasks in a way that minimizes drift and maximizes reviewability.

Copy this file when creating a new task description.

---

## Task Title
<Short, concrete, implementation-scoped title>

---

## Goal

What specific system capability is being added or changed?

Example:
"Implement deterministic RNG streams in core/rng.lua."

---

## Authoritative References

List the exact sections of canonical docs this task implements.

- DCC-Barony-Spec.md: <section>
- DCC-Barony-Engineering.md: <section>
- DCC-Barony-DataSchemas.md: <section if relevant>

---

## Allowed Files

List the only files/directories this task may modify.

Example:
- /mod/dccb/core/rng.lua
- /mod/dccb/core/log.lua
- /docs/DCC-Barony-Engineering.md (if doc update required)

---

## Forbidden Files

List files/directories that must NOT be touched.

Example:
- /mod/dccb/systems/*
- /mod/dccb/integration/*
- /mod/dccb/data/*

---

## Inputs

What data, events, or assumptions does this task rely on?

Example:
- run seed available at bootstrap
- logging system initialized

---

## Outputs

What concrete outputs should exist after completion?

Example:
- rng:stream(name) returns deterministic generator
- logs print stream seed derivation

---

## Acceptance Criteria

Objective, human-verifiable conditions.

Example:
- With seed 12345, region stream produces same first 3 values across runs
- Startup log includes base seed and derived stream seeds

---

## Validation Steps

Exact steps a human takes to verify correctness.

Example:
1. Launch game with fixed seed 12345
2. Start new run
3. Confirm log output includes:
   - DCCB seed: 12345
   - RNG stream region seed: <value>

---

## Non-Goals

Explicitly list what this task must not attempt.

Example:
- No gameplay logic
- No Barony hook exploration

---

## Open Questions

Anything that must be clarified before or during implementation.

---

## Required PR Summary Format

Every submission must include:

- Summary of changes
- Why these changes exist
- Validation checklist
- Known limitations / TODOs

---

End of TASK_TEMPLATE.md
