# Debate log — pixelfx reinforcement of the basic effects

## Round 1 (`attack.md`, 2026-11-04)

- **D1 accept.** The hit follow-up (S5) needs one owner. Today `Attack.gd:163` runs the victim's hit and the attacker's callback, both reach `_spawn_hit_effect`, and Rio's wave skips the attacker callback (`SKILLS.md:21`). The new afterglow spawns from one place in the hit path, once per successful hit, never on a miss, block or parry. A test counts spawns per hit for melee, projectile and monster hits.
- **D2 accept.** The bench's NOW is out of date: `motions.mjs:127` draws Luna without her stars, `:177` plays the old dust. Every comparison's "now" must be the game as it is: an in-game capture at the match camera, or a bench row checked against one. The bench follows the game, never the other way round.
- **D3 accept.** "Spawn beside the slash art" only covers swords. Luna's J are projectiles (`Luna.gd:365`), Nova's vector strikes switch the shared trail off on purpose (D40). The launch follow-through belongs to the character's fire function, the flight to the projectile, the hit to the hit path. Before building S1, a table maps each form's ground, air and directional J to its spawn function.
- **D4 accept.** Five mandatory slots for six sets would be 60 new candidates and 90 matches, the clutter the user just complained about. The slots become a checklist; a cheap triage (in-game captures, the lead and Codex) decides which items need work; batches stay at 2–3 items. Idle presence is optional per form.
- **D5 accept.** Per-batch cost is not a pass mark. Before batch 1, measure a baseline in a crowded web match (p95/p99 frame time, most live effect sprites); every batch re-measures the total against one absolute budget.
- Codex's closing note, also taken: try Frey's attack follow-through (S1) and hit afterglow (S5) together first, to see how they stack, before fixing the order. And do not assume two authors give variety: compare the lead's and a Codex builder's version of one item (quality, fixes needed, cost) before splitting the work that way.

**Revision of the position (2026-11-04):** slots are a checklist, not a quota; a Frey pilot (S1+S5) comes first, with now = the current game; candidates are now + A + B differing on one clear axis (Codex's blind: e.g. sharp moment vs directional linger), never colour swaps; judging uses the match-camera capture with a zoom toggle; an absolute web frame budget is set before batch 1.

Open points: none. Every point closed by acceptance; no rebuttal round was needed.
