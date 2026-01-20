# TASK_TEMPLATE.md
Version: 0.2

This template is used to define agentic or human tasks in a way that minimizes drift and maximizes reviewability. **Do not leave any angle brackets in the completed template, they cause llm parsers to fail**

Copy this file when creating a new task description.

---

## Task Title
Short, concrete, implementation-scoped title

---

## Goal

What specific system capability is being added or changed?

Example:
"Implement deterministic RNG streams in core/rng.lua."

---

## Authoritative References

List the exact sections of canonical docs this task implements.

- DCC-Spec.md: section
- DCC-Engineering.md: section
- DCC-DataSchemas.md: section if relevant
- ToME-Integration-Notes.md: section if relevant

---

## Allowed Files

List the only files/directories this task may modify.

Example:
- /game/addons/tome-dccb/hooks/load.lua
- /docs/ToME-Integration-Notes.md

If a file or folder is not listed here, it is out of scope.

---

## Forbidden Files / Changes

List files/directories that must NOT be touched.

Also list categories of changes that are explicitly forbidden, even if they would be made
inside otherwise allowed files.

Example:
- /mod/dccb/systems/*
- /mod/dccb/integration/*
- /mod/dccb/data/*
- No addon restructuring
- No new loaders, harnesses, or logging frameworks unless explicitly stated
- No speculative engine hooks
- No gameplay systems or architecture work

---

## Inputs

What data, events, or assumptions does this task rely on?

Example:
- ToME successfully loads addon and executes hooks/load.lua
- te4_log.txt is available for verification

---

## Outputs

What concrete outputs should exist after completion?

Example:
- A real ToME hook fires and prints a confirmation line
- te4_log.txt contains expected output

---

## Acceptance Criteria

Objective, human-verifiable conditions.

Example:
- te4_log.txt shows "[DCCB] FIRED: ToME:load"
- te4_log.txt shows "[DCCB] FIRED: Player:birth"

---

## Validation Steps

Exact steps a human takes to verify correctness.

Example:
1. Launch ToME with addon enabled
2. Start a new run
3. Confirm te4_log.txt contains expected hook output

---

## Non-Goals

Explicitly list what this task must not attempt.

Any PR that advances a non-goal is invalid, even if acceptance criteria pass.

Example:
- No gameplay logic
- No engine hook exploration beyond what is explicitly listed
- No architecture or framework work
- No logging system introduction

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
- Files touched

---

End of TASK_TEMPLATE.md
