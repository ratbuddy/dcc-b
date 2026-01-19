# DCC-B: Dungeon Crawler Carl Framework

High-level engineering and systems design specification for an engine-agnostic dungeon crawler system that transforms into a procedural "dungeon show" simulator inspired by Dungeon Crawler Carl-style mechanics. Currently targets Tales of Maj'Eyal (ToME / T-Engine4) as the integration layer.

---

## 1. Project Goal

Build a modular, data-driven dungeon crawler system that provides:

- Region-seeded dungeon shards  
- Escalating “floor rules” instead of static biomes  
- Deep, nonstandard progression systems  
- Simulated contestant teammates (not just helpers)  
- Meta-systems (announcer, rewards, evolving dungeon logic)

Primary focus: system composition and extensibility, not handcrafted content.

---

## 2. Non-Goals

- Not recreating the novels scene-for-scene  
- Not building a new engine  
- Not MMO simulation  
- Not multiplayer-first  
- Not dependent on massive handcrafted maps  

---

## 3. Architectural Overview

The system is structured as layered systems above the game engine's native dungeon engine.

Meta Layer (show logic, announcer, sponsors)  
↓  
Floor Director (escalation, rule sets, mutations)  
↓  
Region Director (geographic constraints & content filters)  
↓  
Dungeon Integration Layer (Engine hooks - currently ToME)  
↓  
Actors (players, contestants, enemies)

Each layer constrains the ones below it.

---

## 4. Core System Modules

### 4.1 Region Director (World Shard System)

Responsible for making each run feel like a small slice of a massive dungeon.

Responsibilities:
- Selects region seed at run start  
- Loads region profile  
- Constrains all dungeon generation  

Owns:
- Asset/tileset sets  
- Prop pools  
- Enemy taxonomies  
- Hazard logic  
- NPC archetype weights  
- Loot bias profiles  
- Traversal modifiers  

Conceptual interface:

RegionProfile  
- id  
- asset_sets  
- enemy_factions  
- hazard_rules  
- npc_archetypes  
- loot_bias  
- traversal_modifiers  

The Region Director never generates floors. It only filters and biases all downstream systems.

---

### 4.2 Floor Director (Escalation Engine)

Responsible for turning “floors” into rule layers, not places.

Responsibilities:
- Tracks run progression  
- Selects floor rule sets  
- Mutates dungeon generation  
- Injects global mechanics  
- Triggers systemic events  

Owns:
- Floor rule definitions  
- Mutation pipelines  
- Escalation curves  
- Global modifiers  

Conceptual interface:

FloorState  
- floor_number  
- active_rules[]  
- mutation_flags  
- global_modifiers  

The Floor Director is the core behavioral engine.

---

### 4.3 Dungeon Integration Layer

Thin translation layer between DCC systems and game engine internals.

Responsibilities:
- Intercept dungeon generation  
- Apply region constraints  
- Apply floor mutations  
- Inject special rooms/events  
- Register system hooks  

Owns:
- Engine hook bindings (currently ToME hooks)
- Generator adapters  
- Spawn interception  
- Room tagging system  

This is the only module that should deeply depend on engine-specific APIs.

---

### 4.4 Contestant System (Players + Simulated Teammates)

Responsible for making the dungeon feel populated by other competitors.

Responsibilities:
- Generate NPC contestants  
- Manage builds and leveling  
- Apply personality bias  
- Coordinate party behavior  
- Track contestant-level meta state  

Owns:
- NPC build generator  
- Archetype definitions  
- Growth heuristics  
- Risk profiles  
- Social behaviors  

Conceptual interface:

Contestant  
- stats  
- skills  
- build_path  
- personality_profile  
- utility_role  
- social_flags  

Contestants are modeled as players of the dungeon, not mobs.

---

### 4.5 Meta Layer (The Show)

Responsible for everything that makes the dungeon a televised system, not just a place.

Responsibilities:
- Announcer system  
- Achievement detection  
- Reward pipelines  
- Sponsor systems  
- Global run modifiers  
- Narrative pressure  

Owns:
- Event listeners  
- Meta triggers  
- Reward resolution  
- Run-wide state  

Conceptual interface:

ShowState  
- active_modifiers  
- sponsor_bias  
- achievement_flags  
- run_mutations  

The Meta Layer can affect future floors, contestant evolution, dungeon rules, and reward quality. It never directly generates rooms.

---

## 5. Data-Driven Design

All systems must be driven by external declarative data, not hardcoded logic.

Examples:
/regions/*.json  
/floor_rules/*.json  
/npc_archetypes/*.json  
/reward_tables/*.json  
/mutations/*.json  

AI tools should be able to author, tune, and expand content without touching code.

---

## 6. Run Lifecycle

Start Run  
→ Pick Region Seed  
→ Initialize Show State  
→ Generate Contestants  

For each Floor:  
→ Determine Floor Rules  
→ Mutate Generators  
→ Generate Dungeon Chunks  
→ Inject Events  
→ Run Dungeon  
→ Resolve Meta Effects  
→ Evolve Contestants  

Floors represent system transitions, not biomes.

---

## 7. Verticality Strategy

Verticality is first-class.

Used for:
- layered traversal  
- risk/reward structures  
- dominance mechanics  
- spectacle spaces  
- forced movement rules  

The generator must support stacked rooms, drops and climbs, overwatch spaces, vertical hazards, and multi-layer arenas.

---

## 8. System Invariants

- Regions constrain, they do not generate  
- Floors mutate rules, not geography  
- Contestants are long-lived agents  
- Meta systems bend reality  
- Dungeon integration remains thin  
- All progression is systemic  
- All major logic is data-driven  

---

## 9. Prototype Phases

Phase 1 – Skeleton  
- Hook dungeon generation  
- Region stub  
- Floor counter  
- Announcer console output  

Phase 2 – Control  
- Region-filtered spawns  
- Floor rule injection  
- NPC contestant generator  

Phase 3 – Identity  
- Build trees  
- Contestant evolution  
- Reward box system  

Phase 4 – Show Logic  
- Sponsor systems  
- Meta mutations  
- Escalating floor behaviors  

---

## 10. Success Criteria

The project is succeeding if:

- Floors feel mechanically different, not just harder  
- Runs feel geographically distinct  
- NPCs feel like competitors, not pets  
- New systems can be added without refactoring  
- The dungeon meaningfully surprises the designer  

---

## 11. Working Methodology

- This document is authoritative  
- All subsystem design must conform to it  
- Chats with AI tools are disposable  
- This file is the canonical reference  
- Outputs from tools are merged back here  

---
