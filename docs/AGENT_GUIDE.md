# AGENT_GUIDE.md
Version: 0.1
Status: Canonical (must be read before any agentic work)

This document defines the non-negotiable operating rules for human- or agent-driven development in this repository.

It exists to prevent architectural drift, silent assumption changes, and engine-coupled design.

---

## 1. Authoritative Documents

The following documents are AUTHORITATIVE. They define the system and must not be contradicted.

- /docs/DCC-Barony-Spec.md
- /docs/DCC-Barony-Engineering.md
- /docs/DCC-Barony-DataSchemas.md

If behavior is unclear, these must be consulted first.
If behavior is missing, update these docs before implementing code.

---

## 2. Hard Invariants

- Barony-specific code MUST live only in:
  - /mod/dccb/integration/*
- Engine-agnostic logic MUST live only in:
  - /mod/dccb/core/*
  - /mod/dccb/systems/*
- Declarative content MUST live only in:
  - /mod/dccb/data/*

- Do NOT mix engine hooks with business logic.
- Do NOT bypass the event bus for cross-system communication.
- Do NOT invent Barony APIs, hook names, or data structures.
  - If unknown, create adapter stubs with TODOs and clear log output.

---

## 3. Scope Control

- One module per task/PR.
- No cross-module refactors unless explicitly approved.
- No schema changes without updating:
  - DCC-Barony-DataSchemas.md
  - and affected validation logic.

- If an engine limitation is discovered:
  - Document it in /docs/Barony-Integration-Notes.md
  - Adjust integration adapters first.
  - Revise core specs only if strictly required.

---

## 4. Required Outputs for Every Task

Every agentic change set must include:

1. A concise summary of what changed.
2. Why the change exists (which doc/section it implements).
3. A validation checklist (how a human verifies success).
4. Expected log output or observable runtime effect.

---

## 5. Logging & Determinism

- All major actions must log via core/log.lua.
- All randomness must go through core/rng.lua.
- Seed and active region/floor rules must always be printable.
- Silent failure is not acceptable.

---

## 6. Documentation Discipline

- New behaviors require doc updates.
- Removed behaviors require doc updates.
- Temporary hacks must be labeled TODO and logged at startup.

Docs are part of the system. They are not optional.

---

## 7. Review Checklist (for humans or reviewer agents)

- [ ] Files changed match allowed scope.
- [ ] No engine calls outside /integration.
- [ ] No logic added without doc reference.
- [ ] Deterministic behavior preserved.
- [ ] Logs clearly show system state.
- [ ] No silent fallbacks.

---

End of AGENT_GUIDE.md
