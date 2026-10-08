# Lead's position (Claude), committed before the blind answer

## Answer (strongest first)

1. **Aim attacks at the target.** Bots set `aim` toward the target's body on every attack; `PlayerBase._get_attack_direction()` uses the bot's aim like a held stick, so up/down/air-up/air-down attacks happen when the target is steeper than |y| ≥ 0.45 of the unit vector. Skills read the same aim (it holds through the attack's start-up). Mobility skill 1 (Frey dash, Nova shift, Rio blink) never aims below +0.2 so a bot does not dash itself off a ledge.
2. **Guard against attacks that are starting.** When an opponent within 190 px x COMBAT, facing the bot, starts a swing (its `attack_lock_timer` goes from 0 to > 0), the bot guards with 40% chance after a 0.08–0.20 s reaction delay and holds 0.25–0.45 s (parry window 0.1 s is hit only by luck of timing). Only on the floor.
3. **Air-jump climbing only over solid ground.** The climb air jump (added today) is used only when there is floor below (`_over_void()` false), so a failed climb lands instead of costing the recovery jump.
4. **Give up on unreachable targets.** If the target stays on another level and the distance has not shrunk by 40 px in 3 s, ignore it for 6 s and re-target; when 3 or fewer fighters remain, players outrank monsters regardless of the early-phase penalty.
5. **Aim Nova's slingshot.** Launch (the third press) when the orbit tangent points within ~35° of the target (dot ≥ 0.82), at most 1.2 s after the orbit starts; if launched off-line, redirect with skill one toward the target.
6. **Ultimates when they will land.** Chance 0.8 when the target is low (< 35% HP) or another opponent is within 300 px of it, 0.25 otherwise.
7. **Keep the low-HP disengage** unless data shows it mainly drags matches.

## Reasons

1–2 are the biggest gaps a watcher notices (whole move sets unused; never blocking); both are cheap. 3 is a direct fix of a regression measured today. 4 fixes a seen stall. 5–6 make ultimates feel deliberate.

## Key assumptions

- Up/down attacks exist and are reasonable for every character (their docs list them).
- Guarding at 40% with a human delay does not make bots frustrating to fight; parries will be rare.
- `_over_void()` (700 px ray x WORLD) is a good proxy for "a failed climb lands safely".
- 3 s / 40 px is enough to separate "unreachable" from "on its way".

## What would change my mind

- Data showing bots already hit well enough with side attacks only (aiming adds little), or that aiming down makes bots fall off stages.
- Guard making matches drag (median length > 7 min) or making bots unbeatable for a human.
- Ring-outs not dropping back toward ~9–10 per match with rule 3.
- A cheaper or more robust rule for unreachable targets (e.g. the navigation graph saying there is no path).
