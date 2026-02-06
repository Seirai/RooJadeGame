# Gameplay Design Document

> A sidescroller idle game with Twitch integration, featuring settlement building and exploration toward a mysterious jade asteroid.

---

## Table of Contents

- [Overview](#overview)
- [Core Concept](#core-concept)
- [Settlement System](#settlement-system)
- [Professions](#professions)
- [Progression Systems](#progression-systems)
- [Twitch Integration](#twitch-integration)

---

## Overview

**Genre:** Sidescroller Idle / Settlement Builder
**Platform:** PC (with Twitch integration)
**Target Audience:** Streamers and their communities, plus standalone players

### Game Modes

| Mode | Description |
|------|-------------|
| **Streamer Mode** | Twitch viewers control individual Roos, vote on decisions, and interact with the settlement |
| **Standalone Mode** | NPC Roos fill in for viewers, providing a complete single-player experience |

---

## Core Concept

### The Goal
Expand your settlement deeper into biomes transformed by a mysterious **jade asteroid**. Along the way, encounter and eventually befriend hostile flora and fauna as you journey toward the impact site.

### The Roos
"Roos" are adorable panda NPCs that form the backbone of your settlement:

- In **Streamer Mode**: Each Roo represents a Twitch viewer (e.g., "Bob" from chat becomes a Roo with "Bob" floating above their head) There will also be AI-controlled NPCs.
- In **Standalone Mode**: Roos are all AI-controlled NPCs

---

## Settlement System

### Roo Basics

| Attribute | Description |
|-----------|-------------|
| **Profession** | Determines behavior and contribution to the settlement |
| **Level** | Profession-specific experience that improves efficiency |
| **Equipment** | Gear that provides bonuses (optional) |

### How It Works

1. Roos are assigned professions that unlock as the colony progresses
2. Each Roo levels up in their profession, becoming more efficient over time
3. In Streamer Mode, viewers can choose bonuses at certain level thresholds
4. The player/streamer can manage the distribution of AI pandas and what profession they are.
5. The streamer can also opt to veto player decisions like a dictator for funny drama.

---

## Professions

### Scout
> *Explores the frontier and claims new territory*

| Responsibility | Details |
|----------------|---------|
| **Exploration** | Travels around the settlement fringes during spare time |
| **Land Claiming** | Uncontested, non-hostile ground becomes buildable territory over time |
| **Threat Detection** | Warns of hostile encounters blocking expansion |

---

### Lumberjack
> *Harvests wood from lumber mills*

**Work Cycle:**
1. Walk to assigned lumber mill (based on vacancy and proximity to home)
2. Spend time "working" at the mill
3. Collect wood into personal inventory (amount/rate affected by upgrades)
4. Travel to colony depot and deposit wood for communal use

---

### Miner
> *Extracts stone and jade from quarries*

| Quarry Type | Resource |
|-------------|----------|
| Stone Quarry | Stone |
| Jade Quarry | Jade (premium currency) |

*Functions identically to Lumberjack but at quarries instead of mills.*

---

### Builder
> *Constructs and develops settlement infrastructure*

**Responsibilities:**
- Living quarters
- Facilities (quarries, lumber mills, etc.)
- Other structures

**Priority System:**
| Priority | Condition |
|----------|-----------|
| High | Abundant workers but missing facility (e.g., many lumberjacks, no mill) |
| Medium | Sufficient resources but no suitable housing |
| Manual | Player-specified construction overrides automatic priorities |

**Scaling:** Additional builders speed up construction with diminishing returns.

---

### Fighter
> *Fights for the settlement when there are hostile encounters*

Base combat unit for early-game threats. More combat professions may unlock later.

---

## Progression Systems

### Research
| Requirement | Benefit |
|-------------|---------|
| Research Facility | Unlocks "Scientist" profession |
| Resource Investment | Unlocks new structures, upgrades, and technologies |

### Structural Upgrades
Every facility can be upgraded by investing resources, improving efficiency and output.

### Roo Experience
| Type | Effect |
|------|--------|
| Profession XP | Improves efficiency at current job |
| Overall XP | General improvements (TBD) |

### Equipment
| Unlock | Via |
|--------|-----|
| Workshops | Research/progression |
| Gear Types | Weapons, tools, accessories |

**Distribution:**
- Manual assignment by player/streamer
- Auto-claim by Roos (if enabled)

---

## Twitch Integration

### Voting System
> *Democracy in action*

| Feature | Description |
|---------|-------------|
| **Major Decisions** | Progression, expansion, and combat choices |
| **Autonomous Play** | Settlement can function while streamer is AFK |
| **Viewer Agency** | Chat collectively shapes the settlement's direction |

---

### Viewer Controls

#### Equipment
- Viewers can equip available gear to their Roo (if auto-claim is enabled)

#### Profession & Progression
- Choose their Roo's job
- Select bonuses at level-up milestones
- React to settlement needs in real-time

---

### Leaderboards

**Categories:**
- Work contributions (by facility type)
- Combat statistics
- Activity/engagement

**Time Periods:**
| Period | Description |
|--------|-------------|
| All-Time | Lifetime contributions |
| Monthly | Last 30 days |
| Weekly | Last 7 days |
| Daily | Last 24 hours |
| Hourly | Recent activity |

---

### Special Events

#### Boss Fights
- Major encounters that encourage viewer participation
- Interactive mechanics (e.g., choosing positioning for upcoming attacks)

#### Fight Club *(Optional)*
- Viewer/streamer-initiated PvP event
- Roos compete against each other

#### Map Events
- Dynamic occurrences on the map
- Interactive experiences for both player and viewers

---

## Resources

| Resource | Source | Use |
|----------|--------|-----|
| **Wood** | Lumber Mills | Construction, crafting |
| **Stone** | Stone Quarries | Construction, upgrades |
| **Jade** | Jade Quarries | Premium currency, special items |

---

## Future Considerations

- [ ] IMPORTANT! Ensure game is easily saveable and loadable.
- [ ] Additional professions (Scientist, Healer, etc.)
- [ ] Advanced combat system with more unit types
- [ ] Biome-specific challenges and resources
- [ ] Achievement system for viewers
- [ ] Seasonal events and special content

---

*Document Version: 1.0*
*Last Updated: January 2026*
