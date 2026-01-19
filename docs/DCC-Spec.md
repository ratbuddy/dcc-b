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

The system is structured as layered systems above the game engine's native zone generation.

Meta Layer (show logic, announcer, sponsors)  
↓  
Floor Director (escalation, rule sets, mutations)  
↓  
Region Director (geographic constraints & content filters)  
↓  
Zone Integration Layer (Engine hooks - currently ToME)  
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
- Constrains all zone generation  

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
- Mutates zone generation  
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
- Intercept zone generation  
- Apply region constraints  
- Apply floor mutations  
- Inject special zones/events  
- Register system hooks  

Owns:
- Engine hook bindings (currently ToME hooks)
- Zone generator adapters  
- Actor spawn interception  
- Zone tagging system  

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

The Meta Layer can affect future floors, contestant evolution, zone rules, and reward quality. It never directly generates zones.

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
→ Mutate Zone Generators  
→ Generate Zone Level  
→ Inject Events  
→ Run Floor  
→ Resolve Meta Effects  
→ Evolve Contestants  

Floors represent system transitions, not biomes.

---

## 7. Verticality Strategy

Verticality is first-class in DCC-B, but expressed through **systemic depth and layered spatial rules** rather than literal 3D geometry.

In a 2D zone-based engine like ToME, verticality manifests as:

### 7.1 Multi-Level Zones
- Floors represent distinct zone levels with inter-level connections
- Each level can have different rule sets, enemy pools, and environmental properties
- Vertical progression through stairs, portals, shafts, or zone transitions

### 7.2 Positional Dominance
- Chokepoints and line-of-sight advantages in 2D space
- Terrain height represented abstractly through modifiers (elevation tags, cover bonuses)
- Tactical positioning creates "high ground" effects without true 3D rendering

### 7.3 Layered Risk via Zone Rules
- Floor-to-floor rule layering creates escalating challenge
- Environmental pressure increases through zone-specific hazards, not stacked rooms
- Generator parameter shifts between levels create vertical variety

### 7.4 Spectacle Spaces
- Arena zones with special connection rules
- Multi-exit zones that branch or converge
- Event zones that modify subsequent zone generation

### 7.5 Forced Movement
- Zone transition mechanics (falling through trap doors = forced zone change)
- Teleportation and displacement effects
- One-way passages and locked progression paths

**Core principle:** Verticality in DCC-B means systemic depth—floors that feel mechanically distinct and progression that creates layered spatial complexity—not necessarily 3D geometry or physics simulation.

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
- Hook zone generation  
- Region stub  
- Floor counter  
- Announcer console output  

Phase 2 – Control  
- Region-filtered actor spawns  
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
