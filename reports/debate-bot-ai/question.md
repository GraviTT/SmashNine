# Debate: how should the bots change to be smarter (and more fun to watch and fight)?

User (2026-10-08): "봇 문제는 현재 밝혀진 것들을 Codex와 토론하여 해결하고, 더 똑똑하게 만들어 볼것."

## The question

Given the observed symptoms below and the code, which changes to the bot brain should we make, in what order, and with which concrete rules (thresholds, functions, signals)? Up to 7 changes, strongest first.

## Decision criteria (ranked)

1. **Looks smart to a person watching or fighting it**: uses the moves a human would (aiming up/down, guarding, recovering, picking sensible targets), does not stand around or chase what it cannot reach.
2. **Healthy matches**: median length stays in 5–7 min, no long standoffs, ring-outs and KOs come from play, not bot mistakes.
3. **Fair across the five characters**: no character gains or loses mostly because the bot plays it badly.
4. **Beatable and readable**: not frame-perfect; reaction delays and misses like a decent human.
5. **Low risk**: small, testable changes in the existing structure; deterministic with match seeds.

## Constraints

- Godot 4.7 GDScript. Bot brain is `smash-nine-prototype/scripts/EnemyAI.gd` (one per fighter); fighters `characters/common/PlayerBase.gd` + one folder per character (`characters/<id>/<Id>.gd`, `<Id>.md` describes the moves).
- Scales in `scripts/GameScale.gd` (attacks x2, realms x1.5, run x1.2, jumps 1.5x higher, knockback 1.5x — changed today, decision D27 in `design/DECISIONS.md`).
- `EnemyAI.debug_snapshot()` and the F4 panel show each bot's state, action, target, intent and a reason.
- No new dependencies; CPU per bot per frame must stay small (8 bots, 60 fps, also in the web build).

## Observed symptoms (measured or seen; no fixes implied)

1. In bot matches, bots never use up, down, air-up or air-down basic attacks, even with a target right above or below them.
2. Bots never guard or parry.
3. Ring-outs went from 9.3 to 11.9 per match (16 matches each) after bots started using their air jump to climb tall rises during normal movement.
4. A bot was seen "engaging" a monster 200 px below it for several minutes without reaching it; in early phases bots spend much of their time on monsters.
5. Nova's ultimate is a three-press slingshot (core, orbit, launch along the orbit's tangent, optional redirect with skill one); bot launches mostly fly away from the opponents.
6. Ultimates fire with a fixed 45% chance whenever an attack is chosen in range.
7. Low-HP bots leave through portals; with the bigger realms, final duels could drag (one bug that froze relocated bots was found and fixed today; matches now median 307 s).

## Files to read

`smash-nine-prototype/scripts/EnemyAI.gd`, `characters/common/PlayerBase.gd` (attack direction, guard, jumps, knockback), `characters/nova/Nova.gd` (ultimate), `scripts/GameScale.gd`, `characters/README.md`, `design/DECISIONS.md` (D27), `routine/2026-10-08-work/results/sweep_after_16_summary.txt`.
