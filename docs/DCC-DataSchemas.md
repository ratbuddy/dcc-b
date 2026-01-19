# DCC-B Data Schemas

Version: 0.2
Status: Draft (iterative)

This document defines the **data contracts** for DCC-B. These schemas are designed to be:
- Easy to validate offline (JSON Schema friendly)
- Easy to author by hand or generate with AI tools
- Stable interfaces for Lua runtime systems

All IDs are lowercase kebab-case unless otherwise noted.

Directory conventions (recommended):
- `/mod/dccb/data/regions/*.json`
- `/mod/dccb/data/floor_rules/*.json`
- `/mod/dccb/data/npc_archetypes/*.json`
- `/mod/dccb/data/reward_tables/*.json`
- `/mod/dccb/data/mutations/*.json`
- `/mod/dccb/data/defaults/config.json`

---

## 0. Common Types

### 0.1 ID
- Type: string
- Format: `^[a-z0-9]+(?:-[a-z0-9]+)*$`
- Example: `nyc-subway`, `floor-1-onboarding`, `sponsor-gilded`

### 0.2 Weight
- Type: number
- Meaning: relative probability, must be > 0
- Rule: weights are normalized by the caller

### 0.3 Tag Set
- Type: object
- Keys: string, Values: boolean or string/number
- Example:
  - `"tags": { "urban": true, "underground": true, "wetness": 0.4 }`

### 0.4 Weighted List Item
Object with an ID plus weight and optional constraints.
- `id` (ID, required)
- `w` (Weight, required)
- `when` (ConditionExpr, optional)
- `tags` (Tag Set, optional)

### 0.5 ConditionExpr (minimal)
Condition expressions must be easy to parse in Lua.
Represented as a simple object; all fields optional; if absent, condition is true.

Supported fields (phase 1):
- `min_floor`: number
- `max_floor`: number
- `region_is`: [ID]
- `has_rule`: [ID]
- `not_rule`: [ID]
- `difficulty_at_least`: number
- `difficulty_at_most`: number

Example:
- `"when": { "min_floor": 2, "has_rule": ["low-light"] }`

---

## 1. defaults/config.json

Purpose: baseline configuration (merged with overrides).

Required fields:
- `version` (string)
- `seed_mode` (string enum: `engine`, `fixed`, `time`)
- `fixed_seed` (number; required if seed_mode=fixed)
- `region_mode` (string enum: `random`, `pinned`, `weighted`)
- `pinned_region_id` (ID; required if region_mode=pinned)
- `npc_roster_size` (number)
- `logging_level` (string enum: `ERROR`, `WARN`, `INFO`, `DEBUG`)
- `enable_ui_overlay` (boolean)
- `difficulty_curve` (ID or enum label; phase 1 may keep as string)

Optional fields:
- `data_packs` (array of strings) — for future modular content packs
- `enable_validation_strict` (boolean) — fail fast on warnings
- `debug_print_active_tables` (boolean)

Example (minimal):
  {
    "version": "0.1",
    "seed_mode": "engine",
    "fixed_seed": 12345,
    "region_mode": "random",
    "pinned_region_id": "nyc-subway",
    "npc_roster_size": 3,
    "logging_level": "INFO",
    "enable_ui_overlay": false,
    "difficulty_curve": "default"
  }

---

## 2. Region Profiles (`/regions/*.json`)

### 2.1 Purpose
Regions make runs feel like geographically distinct “shards” of a larger dungeon.
Regions constrain:
- asset sets / prop pools
- enemy factions / ecology
- hazards / traversal modifiers
- NPC archetype weights
- loot bias

### 2.2 Schema: RegionProfile
Required:
- `id` (ID)
- `name` (string)
- `description` (string)
- `tags` (Tag Set)
- `asset_sets` (object)
- `enemy_factions` (object)
- `hazard_rules` (object)
- `npc_archetypes` (array of Weighted List Item)
- `loot_bias` (object)
- `traversal_modifiers` (object)

Recommended/optional:
- `starting_chunk_templates` (array of IDs) — future use
- `music_set` (ID) — future use

#### 2.2.1 asset_sets
This is intentionally abstract; it’s a “capability list” the Integration Layer maps to engine-specific assets.

Fields (phase 1):
- `tileset_ids` (array of string IDs known to integration)
- `prop_pool_ids` (array of ID)
- `lighting_profile_id` (ID; optional)

Example:
  "asset_sets": {
    "tileset_ids": ["urban-concrete", "subway-tile"],
    "prop_pool_ids": ["props-urban", "props-subway"],
    "lighting_profile_id": "lighting-flicker"
  }

#### 2.2.2 enemy_factions
Fields:
- `allowed` (array of Weighted List Item) — faction IDs or spawn group IDs
- `banned` (array of ID; optional)
- `elite_bias` (number 0..1; optional)

Example:
  "enemy_factions": {
    "allowed": [
      { "id": "humanoid-scavengers", "w": 3 },
      { "id": "vermin-swarm", "w": 1 }
    ],
    "banned": ["arcane-constructs"],
    "elite_bias": 0.15
  }

#### 2.2.3 hazard_rules
Fields:
- `hazards` (array of Weighted List Item) — hazard IDs
- `base_intensity` (number 0..1)
- `intensity_by_floor` (array of objects; optional)

Example:
  "hazard_rules": {
    "hazards": [
      { "id": "low-light", "w": 2 },
      { "id": "slick-floors", "w": 1 }
    ],
    "base_intensity": 0.25
  }

#### 2.2.4 loot_bias
Fields:
- `table_weights` (array of Weighted List Item) — reward table IDs
- `rarity_bias` (number -1..+1; optional) — negative = stingier, positive = richer
- `box_theme_ids` (array of ID; optional)

Example:
  "loot_bias": {
    "table_weights": [
      { "id": "loot-modern-scrap", "w": 3 },
      { "id": "loot-medical", "w": 1 }
    ],
    "rarity_bias": 0.1,
    "box_theme_ids": ["crate-industrial", "crate-sponsor"]
  }

#### 2.2.5 traversal_modifiers
Fields:
- `verticality_bias` (number 0..1) — prefer stairs/rooftops/etc
- `trap_density` (number 0..1)
- `room_compactness` (number 0..1)

Example:
  "traversal_modifiers": {
    "verticality_bias": 0.65,
    "trap_density": 0.25,
    "room_compactness": 0.4
  }

### 2.3 Example RegionProfile (complete)
  {
    "id": "nyc-subway",
    "name": "NYC Subway Shard",
    "description": "Concrete, tile, and service tunnels with cramped vertical connectors.",
    "tags": { "urban": true, "underground": true },
    "asset_sets": {
      "tileset_ids": ["urban-concrete", "subway-tile"],
      "prop_pool_ids": ["props-urban", "props-subway"],
      "lighting_profile_id": "lighting-flicker"
    },
    "enemy_factions": {
      "allowed": [
        { "id": "humanoid-scavengers", "w": 3 },
        { "id": "vermin-swarm", "w": 1 }
      ],
      "banned": [],
      "elite_bias": 0.15
    },
    "hazard_rules": {
      "hazards": [
        { "id": "low-light", "w": 2 },
        { "id": "slick-floors", "w": 1 }
      ],
      "base_intensity": 0.25
    },
    "npc_archetypes": [
      { "id": "ex-transit-worker", "w": 2 },
      { "id": "street-doc", "w": 1 }
    ],
    "loot_bias": {
      "table_weights": [
        { "id": "loot-modern-scrap", "w": 3 },
        { "id": "loot-medical", "w": 1 }
      ],
      "rarity_bias": 0.1,
      "box_theme_ids": ["crate-industrial", "crate-sponsor"]
    },
    "traversal_modifiers": {
      "verticality_bias": 0.65,
      "trap_density": 0.25,
      "room_compactness": 0.4
    }
  }

---

## 3. Floor Rule Sets (`/floor_rules/*.json`)

### 3.1 Purpose
Floors are **rule layers**. A floor rule set defines:
- active rules
- mutation activations
- spawn/loot modifiers
- event injections

### 3.2 Schema: FloorRuleSet
Required:
- `id` (ID)
- `name` (string)
- `description` (string)
- `floor_number` (number) — which floor this targets (phase 1)
- `rules` (array of ID) — named rules; pure labels for now
- `mutations` (array of MutationActivation)
- `spawn_modifiers` (object)
- `loot_modifiers` (object)
- `event_injections` (array of EventInjection)

Optional:
- `difficulty_scalar` (number)
- `tags` (Tag Set)

#### 3.2.1 MutationActivation
Required:
- `id` (ID) — mutation id (from /mutations)
- `params` (object; optional)
- `when` (ConditionExpr; optional)

Example:
  { "id": "mut-low-light", "params": { "intensity": 0.6 } }

#### 3.2.2 spawn_modifiers
Fields (phase 1):
- `enemy_density` (number 0..2; 1=baseline)
- `elite_chance_add` (number -1..+1)
- `faction_weight_overrides` (array of Weighted List Item; optional)

#### 3.2.3 loot_modifiers
Fields:
- `box_rate` (number 0..2)
- `rarity_bias` (number -1..+1)
- `table_weight_overrides` (array of Weighted List Item; optional)

#### 3.2.4 EventInjection
Required:
- `event_id` (ID)
- `w` (Weight) OR `once` (boolean) — choose one
- `params` (object; optional)
- `when` (ConditionExpr; optional)

Example:
  { "event_id": "arena-pull", "once": true, "params": { "timer_sec": 120 } }

### 3.3 Example FloorRuleSet
  {
    "id": "floor-1-onboarding",
    "name": "Onboarding Chaos",
    "description": "High scavenging, low elites, teach systems via pressure spikes.",
    "floor_number": 1,
    "rules": ["scarcity-lite", "tutorial-pressure"],
    "mutations": [
      { "id": "mut-reward-box-boost", "params": { "box_rate": 1.3 } }
    ],
    "spawn_modifiers": {
      "enemy_density": 0.9,
      "elite_chance_add": -0.1
    },
    "loot_modifiers": {
      "box_rate": 1.3,
      "rarity_bias": 0.0
    },
    "event_injections": [
      { "event_id": "announcer-intro", "once": true }
    ]
  }

---

## 4. NPC Archetypes (`/npc_archetypes/*.json`)

### 4.1 Purpose
NPC archetypes define contestant “starting identity”:
- starting stats & skill biases
- personality/risk policy defaults
- build path preferences
- utility role

### 4.2 Schema: NPCArchetype
Required:
- `id` (ID)
- `name` (string)
- `description` (string)
- `tags` (Tag Set)
- `base_stats` (object)
- `personality` (object)
- `build_preferences` (object)
- `loadout_bias` (object)

Optional:
- `barks_set_id` (ID)
- `region_affinity` (array of IDs)

#### 4.2.1 base_stats
Keep engine-independent. Integration maps to engine-specific stats.
Fields (phase 1):
- `stat_bias` (object of {stat_id: number})
- `hp_scalar` (number 0.5..2.0; optional)

Example:
  "base_stats": { "stat_bias": { "str": 1, "dex": 0, "int": -1 } }

#### 4.2.2 personality
Fields:
- `risk` (number 0..1) — 0 cautious, 1 reckless
- `teamplay` (number 0..1)
- `greed` (number 0..1)
- `aggression` (number 0..1)

#### 4.2.3 build_preferences
Fields:
- `preferred_build_paths` (array of Weighted List Item) — build path IDs
- `avoid_tags` (array of ID; optional)
- `prefer_tags` (array of ID; optional)

#### 4.2.4 loadout_bias
Fields:
- `weapon_tags` (array of Weighted List Item) — abstract tags, mapped by integration
- `armor_tags` (array of Weighted List Item)
- `consumable_tags` (array of Weighted List Item)

### 4.3 Example NPCArchetype
  {
    "id": "street-doc",
    "name": "Street Doc",
    "description": "Improvises healing, prioritizes survival and utility.",
    "tags": { "support": true, "urban": true },
    "base_stats": { "stat_bias": { "str": -1, "dex": 0, "int": 1 } },
    "personality": { "risk": 0.2, "teamplay": 0.8, "greed": 0.3, "aggression": 0.4 },
    "build_preferences": {
      "preferred_build_paths": [
        { "id": "build-path-medic-util", "w": 3 },
        { "id": "build-path-throwables", "w": 1 }
      ]
    },
    "loadout_bias": {
      "weapon_tags": [ { "id": "light-weapon", "w": 2 }, { "id": "ranged", "w": 1 } ],
      "armor_tags": [ { "id": "light-armor", "w": 2 } ],
      "consumable_tags": [ { "id": "healing", "w": 3 }, { "id": "utility", "w": 1 } ]
    }
  }

---

## 5. Reward Tables (`/reward_tables/*.json`)

### 5.1 Purpose
Reward tables drive “boxes” and sponsor outcomes.
Tables are referenced by RegionProfile loot_bias and FloorRuleSet loot modifiers.

### 5.2 Schema: RewardTable
Required:
- `id` (ID)
- `name` (string)
- `description` (string)
- `entries` (array of RewardEntry)

Optional:
- `tags` (Tag Set)
- `rolls` (object) — multiple draws per open
- `gating` (ConditionExpr)

#### 5.2.1 RewardEntry
Required:
- `id` (ID) — reward entry ID
- `w` (Weight)
- `type` (enum: `item`, `currency`, `buff`, `mutation`, `event`)
- `payload` (object) — type-specific

Optional:
- `when` (ConditionExpr)
- `rarity` (enum: `common`, `uncommon`, `rare`, `epic`, `legendary`)
- `tags` (Tag Set)

Type payload guidance (phase 1):
- item: { "item_id": "<engine/item id or abstract id>", "count": 1 }
- currency: { "kind": "gold", "amount": 50 }
- buff: { "buff_id": "buff-regen", "duration_sec": 60 }
- mutation: { "mutation_id": "mut-low-light", "params": {...} }
- event: { "event_id": "spawn-ambush", "params": {...} }

### 5.3 Example RewardTable
  {
    "id": "loot-medical",
    "name": "Medical Cache",
    "description": "Healing and survival items.",
    "entries": [
      { "id": "bandages", "w": 5, "type": "item", "payload": { "item_id": "item-bandage", "count": 2 }, "rarity": "common" },
      { "id": "medkit", "w": 2, "type": "item", "payload": { "item_id": "item-medkit", "count": 1 }, "rarity": "uncommon" },
      { "id": "regen-buff", "w": 1, "type": "buff", "payload": { "buff_id": "buff-regen", "duration_sec": 45 }, "rarity": "rare" }
    ]
  }

---

## 6. Mutations (`/mutations/*.json`)

### 6.1 Purpose
Mutations are named, parameterizable rule changes that can affect:
- generation knobs
- spawns
- loot
- environment/hazards
- meta/show behavior

Mutations can be activated by floors, rewards, or show events.

### 6.2 Schema: Mutation
Required:
- `id` (ID)
- `name` (string)
- `description` (string)
- `kind` (enum: `generation`, `spawn`, `loot`, `hazard`, `meta`)
- `effects` (object) — kind-specific
- `default_params` (object; optional)

Optional:
- `stacking` (enum: `none`, `additive`, `max`, `override`)
- `tags` (Tag Set)

Examples of effects fields (phase 1):
- generation:
  - `verticality_bias_add` (number)
  - `trap_density_add` (number)
  - `room_compactness_mul` (number)
- spawn:
  - `enemy_density_mul` (number)
  - `elite_chance_add` (number)
  - `ban_factions` (array of ID)
- loot:
  - `box_rate_mul` (number)
  - `rarity_bias_add` (number)
- hazard:
  - `add_hazards` (array of Weighted List Item)
  - `hazard_intensity_add` (number)
- meta:
  - `sponsor_bias_add` (object)
  - `announcer_style` (ID)

### 6.3 Example Mutation
  {
    "id": "mut-low-light",
    "name": "Low Light",
    "description": "Visibility reduced; favors ambush and vertical holds.",
    "kind": "hazard",
    "effects": {
      "add_hazards": [ { "id": "low-light", "w": 1 } ],
      "hazard_intensity_add": 0.35,
      "verticality_bias_add": 0.1
    },
    "default_params": { "intensity": 0.6 },
    "stacking": "max",
    "tags": { "visibility": true }
  }

---

## 7. Build Paths (optional, phase 2+)

If you want data-driven leveling/skills, define build paths as separate data.

Suggested directory:
- `/mod/dccb/data/build_paths/*.json`

Minimal schema:
- `id`, `name`, `description`
- `milestones`: array of levels; each milestone grants skills/perks/stat shifts
- `tags`

This is intentionally deferred until systems are wired up.

---

## 8. Cross-File Referential Integrity

The validator must check:
- RegionProfile `npc_archetypes[].id` exists in npc archetypes
- RegionProfile `loot_bias.table_weights[].id` exists in reward tables
- FloorRuleSet `mutations[].id` exists in mutations
- RewardTable mutation/event payload IDs exist (if those systems are enabled)
- All IDs are unique within their file type

---

## 9. Authoring Guidance (for AI tools)

When generating data:
- Prefer small, composable files (one region per file, one floor per file)
- Keep weights simple (1, 2, 3, 5)
- Use tags for semantic routing (e.g., `urban`, `support`, `vermin`)
- Put “engine mapping” IDs (real engine item IDs) behind integration-friendly abstractions when unsure

---
