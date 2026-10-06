# Smash Nine Realms - Final Development Goal

This document defines the current final development target for **Smash Nine Realms**.

It is intended to keep future development aligned with the full game vision, even while individual prototype details continue to change.

## Game Overview

**Smash Nine Realms** is a 2D pixel-style **platform brawler battle royale**.

Players choose characters from different fantasy and heroic worlds, fight across nine collapsing realms, collect souls, grow during the match, and compete to become the final survivor.

The core goal is not simply to add many systems. The game should combine:

- Satisfying action controls
- Clear attack and hit feedback
- Space control through knockback
- Strategic pressure from collapsing realms
- Short-match growth choices
- Fast, dense, replayable brawler matches

## Target Player Experience

A full match should follow this overall flow:

```text
Character select
-> Spawn in one of the nine realms
-> Explore, fight, and collect souls
-> Choose growth upgrades
-> React to realm collapse warnings
-> Move toward safer realms
-> Fight in a shrinking battlefield
-> Enter the central realm
-> Final brawl
-> Final survivor is decided
```

The target match length is approximately **5 to 7 minutes**.

The game should avoid long-term in-match grinding. Instead, it should focus on quick decisions, action skill, growth choices, position control, and escalating combat pressure.

## Genre Definition

The final game is a combination of:

```text
2D platform action
+ brawler-style combat
+ battle royale survival
+ match-based roguelike growth choices
+ fantasy multiverse character battles
```

The combat reference point is close to platform brawlers such as **Super Smash Bros.**, but the defeat structure is different.

This game does not rely on instant ring-out death as the main rule. Instead, it uses **HP-based survival with ring-out damage**.

## Core Differentiators

## 1. The Nine Realms

The battlefield is built around a 3x3 structure of nine realms.

Each realm should have its own:

- Visual theme
- Terrain layout
- Environmental gimmick
- Hazards
- Tactical identity

Over time, realms collapse in a random or semi-random order.

The central realm is closed during the early phase and opens later, becoming the final combat destination.

## 2. HP-Based Brawler Survival

The game uses HP as the primary defeat condition.

- A character is defeated when HP reaches 0.
- Ring-out does not instantly defeat the player.
- Ring-out causes HP damage.
- Ring-out damage increases as the match progresses.
- Early phases allow more recovery and respawn room.
- Later phases increase survival pressure.

The goal is to reduce unfair instant deaths while preserving the tension and spatial pressure of platform brawler combat.

## 3. Knockback as Space Control

Knockback is not mainly a home-run mechanic.

Its primary purpose is to create **position advantage**.

Attackers should be able to:

- Push opponents away
- Control center stage
- Take high ground
- Claim safe territory
- Force opponents toward danger zones

Defenders should still have:

- Recovery opportunities
- Air control
- Counterplay windows
- A chance to return to the fight

The combat should feel physical and tactical, not like players are instantly launched out of the match.

## 4. Soul Growth System

Players collect souls during the match through actions such as:

- Fighting other players
- Defeating monsters
- Breaking soul crystals
- Taking map objectives

Each match includes **three growth choices**.

At each growth point, the player chooses one option from three random choices.

Growth effects are divided into two broad types:

- Stat upgrades
- Action-changing upgrades

Examples:

- Increased HP
- Increased attack power
- Increased movement speed
- Reduced cooldowns
- Added air dash
- Modified basic attack
- Extra effect on a skill
- New recovery option

The growth system should make each match feel different without overwhelming the core action.

## 5. Character Combat Identity

All characters share the same broad control structure:

```text
Move
Jump
Basic attack
Skill 1
Skill 2
Ultimate
```

However, characters should feel different through:

- Basic attack behavior
- Directional attacks
- Aerial attacks
- Skill structure
- Movement style
- Range
- Recovery options
- Combat role

Basic attacks are expected to be used more often than skills, so basic attack variation is central to character identity.

## Combat Direction

The combat should be built around this input-to-result chain:

```text
Input
-> Character body reacts
-> Attack motion is readable
-> Hit produces clear impact
-> Opponent is displaced
-> Attacker gains position
-> Defender regains control and responds
```

The player should feel:

- "I pressed the button."
- "My character physically responded."
- "I swung the attack."
- "The hit connected."
- "The opponent moved because of my action."
- "I gained or lost space."
- "I can continue making decisions."

Combat should not feel like invisible hitboxes appearing without body motion.

Key combat requirements:

- Responsive movement
- Readable attack startup
- Clear active hit moments
- Meaningful recovery after whiffing
- Hitstop on impact
- Hit effects
- Damage feedback
- Knockback with understandable direction
- Short but fair hitstun
- Air control and recovery options
- Distinct ground and aerial attacks

## Control Goal

The final basic control layout is:

```text
Move
Jump
Basic attack
Skill 1
Skill 2
Ultimate
```

Basic attacks branch by direction and state:

```text
Neutral attack
Side attack
Up attack
Down attack
Aerial side attack
Aerial up attack
Aerial down attack
```

Each attack type should have a clear purpose:

- Fast poke
- Launcher
- Pushback
- Downward strike
- Aerial chase
- Landing coverage
- Space control

## Initial Character Direction

The first core characters are:

## Frey

Category: Myth / Fantasy  
Role: Valkyrie  
Combat style: Close-range sword fighter

Frey should be the first benchmark character for combat feel.

Target feel:

- Physical
- Direct
- Readable
- Slightly heavy
- Strong at close range
- Good at claiming space

## Yuki

Category: Eastern Myth  
Role: Onmyoji  
Combat style: Ranged controller

Target feel:

- Uses talismans and spells
- Controls space from a distance
- Weaker in direct melee
- Strong at zoning and disrupting movement

## Luna

Category: Magical Girl  
Role: Star Magical Girl  
Combat style: Mid-range area magic

Target feel:

- Wide magical hit areas
- Bright and readable attacks
- Good at covering space
- Moderate mobility and control

## Nova

Category: Super Hero  
Role: Gravity Hero  
Combat style: Mobile impact fighter

Target feel:

- Fast movement
- Gravity-assisted attacks
- Strong aerial control
- Good at chase and repositioning

## Long-Term Character Categories

The full game can expand into multiple world categories:

- Myth / Fantasy
- Eastern Myth
- Western Fantasy
- Super Hero
- Magical Girl

Each category should support different combat archetypes while still fitting the same core control system.

## Final Match Structure

## 1. Early Exploration

Players spawn across the nine realms.

The early phase focuses on:

- Movement
- Initial skirmishes
- Monster fights
- Soul collection
- Soul crystal objectives
- Low ring-out damage
- Recovery and respawn room

## 2. Mid-Match Conflict

Some realms begin collapse warnings.

The mid phase focuses on:

- Moving toward safe realms
- Increased player encounters
- Growth choices
- Positional pressure
- More frequent fights

## 3. Late Convergence

Fewer realms remain.

The late phase focuses on:

- Central realm opening
- Higher ring-out damage
- Completed or near-completed growth builds
- Stronger pressure to fight
- Reduced safe space

## 4. Final Brawl

The remaining players fight around the central realm.

The final phase focuses on:

- Maximum survival pressure
- High-value positioning
- Punishing mistakes
- Deciding the final survivor

## Final Game Modes

The final target modes are:

- Solo: 16 players
- Duo: 8 teams
- Squad: 4 teams

Early development should focus on solo rules first.

Team modes and online multiplayer should be expanded only after the core combat feel and match loop are stable.

## Art Direction

The target art direction is:

```text
2D pixel characters
+ clear combat effects
+ fantasy realm backgrounds with 2.5D depth
+ strong readability during battle
```

Characters should be small, readable, and expressive.

Effects should be clear and satisfying without covering important combat information.

Backgrounds should be visually rich but must not interfere with combat readability.

## Final Success Criteria

The final game should meet these criteria:

- Moving a character feels satisfying.
- Jumping and aerial control feel responsive.
- Basic attacks are enjoyable without relying on skills.
- Each character has a distinct combat identity.
- Hits feel physical and readable.
- Knockback creates space advantage without feeling unfair.
- Defenders have meaningful recovery and counterplay.
- Realm collapse creates strategic pressure.
- Soul growth creates match-to-match variation.
- A match compresses exploration, growth, conflict, and final brawl into 5 to 7 minutes.
- The game is understandable at a glance but deep enough to improve over time.

## One-Sentence Target

**Smash Nine Realms is a short, dense, 2D platform brawler battle royale where satisfying character action, space-control combat, collapsing realms, and match-based growth combine into a fantasy multiverse survival fight.**
