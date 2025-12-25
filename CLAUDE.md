# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Under Dog Lord is a **wave defense + kingdom management + exploration** game built with GameMaker Studio 2024 (GML). Players garrison units in buildings, deploy them to defend against monster waves from the north, and send expeditions to explore fog-covered territories.

**Language**: Korean (한국어) - All game text, documentation, and code comments are in Korean.

## World Structure

```
              [심연의 경계] ← Monster waves (North)
                    │
[미개척 영역] ◄── [왕국 영지] ──► [미개척 영역]
   (West)           (Castle)         (East)
                    │
              [미개척 영역]
                 (South)
```

- **심연의 경계 (Abyss Border)**: North - Monster wave spawn point
- **왕국 영지 (Kingdom)**: Center - Player's castle, buildings, unit garrison
- **미개척 영역 (Unexplored)**: East/West/South - Fog-covered, explorable with expeditions

## Build & Run

- **IDE**: GameMaker Studio 2024.14.2+ required
- **Run**: Open `under_dog_lord.yyp` in GameMaker IDE, press F5 to run
- **Build**: Use GameMaker IDE build options for target platform

## Architecture

### Data-Driven Design

All game elements (skills, units, effects, buildings) are defined as **struct data**, not hardcoded logic:

```gml
// Add new skill = add data only
skill_fireball = {
    name: "파이어볼",
    effects: [{ type: "damage", amount: 200, damage_type: "fire" }]
}
```

### Core Systems

| System | Description | Key Concepts |
|--------|-------------|--------------|
| **Skill/Effect** | Composable effect system | Effects chain together; targeting via filters |
| **Unit** | Race/class-based units | Stats scale with level; AI by role |
| **Battle** | Wave defense combat | 9 deployment positions (FL/FC/FR/BL/BC/BR/WL/WC/WR) |
| **Economy** | Buildings & resources | Job buildings (직업) vs Race buildings (종족) |
| **Exploration** | Expedition system | Stamina-based travel; outposts for rest; fog discovery |

### Tag System

Universal tag-based filtering for targeting, buffs, dispels:
- Effect tags: `buff`, `debuff`, `dot`, `hot`
- Element tags: `fire`, `ice`, `electric`, `shadow`, `holy`
- Race tags: `human`, `undead`, `demon`, `beast`, `slime`, `dragon`
- Role tags: `tank`, `dps`, `healer`, `support`

### AI Design Philosophy

- **Enemy AI**: Simple and predictable (3 types: `ai_rush`, `ai_ranged`, `ai_boss`)
- **Ally AI**: Complex role-based behavior (7 types: tank, healer, ranged_dps, melee_dps, assassin, support, summoner)

## Code Structure

```
scripts/
├── scr_data.gml          # Skill and unit template data
├── scr_debug.gml         # Debug utilities, damage calc, combat log

objects/
├── obj_debug_controller/ # Debug test scene controller

docs/                     # Design documentation (Korean)
├── INDEX.md              # System overview and quick reference
├── SKILL_EFFECT_SYSTEM.md
├── UNIT_SYSTEM.md
├── BATTLE_SYSTEM.md
├── ECONOMY_SYSTEM.md
```

## Key Implementation Patterns

### Creating Units from Templates

```gml
var unit = create_unit_from_template("fire_mage", "ally", 10);
```

### Damage Calculation

Uses armor formula: `damage * (100 / (100 + defense))` with penetration reducing effective defense.

### Stat System

- **Primary stats**: HP, mana, physical/magic attack/defense, attack speed, movement speed, range
- **Secondary stats**: crit chance/damage, dodge, accuracy, lifesteal, penetration, regen
- **Resistance**: CC resist, debuff resist

## Design Documentation

Comprehensive system specs in `docs/` folder (Korean):
- **INDEX.md**: Start here - contains world structure, system relationships, quick reference table
- **EXPLORATION_SYSTEM.md**: Expeditions, stamina, outposts, fog discovery
- Reference specific docs when implementing: skills → SKILL_EFFECT_SYSTEM.md, units → UNIT_SYSTEM.md, etc.

## GML Conventions

- Use `$` accessor for dynamic struct keys: `struct[$ key]`
- Check struct members with `variable_struct_exists()`
- Use `??` for null coalescing: `value ?? default`
