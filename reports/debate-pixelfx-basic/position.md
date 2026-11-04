# Lead position (frozen before the blind run, 2026-11-04)

Question: how to reinforce the player characters' basic effects with pixelfx (plan only; the user will run it).

## Answer

1. **Scope: a "basic set" of five slots per form**, not skills or ultimates (those stay Codex art):
   - S1 attack follow-through: what is left after each J hit/slash (Frey's sparks are the model).
   - S2 landing and jump: takeoff puff, air-jump mark, landing by drop height (Luna's small/big stardust is the model).
   - S3 run steps: one kick-up per footfall, played within one step (Frey's dust, re-timed 11-04).
   - S4 idle presence: a looped overlay in the character's motif, head and face kept clear (Luna's v3 stars).
   - S5 hit follow-up: a short pixelfx afterglow on the attacker's existing Codex hit spark (mixed), small and short because it fires the most.
   Forms: Frey, Luna, Brave Luna, Yuki, Nova (male/female share effects), Rio (male/female share) = 6 effect sets.
2. **Order: by slot across all forms, not by character.** Batch 1 S1 (most seen, attack feel), batch 2 S2, batch 3 S3, batch 4 S4, batch 5 S5. Each batch is judged in one sitting, so the cast stays consistent (whose effect is whose, same strength) and the hooks are written once per slot.
3. **Method: custom `sn-` pixelfx effects at 1x detail sized to the 95-px bodies**, the character's palette and motif, baked to Vfx strips. Library effects only as starting points (the test showed they are drawn for 24x38 actors).
4. **Candidates: two per slot per form, made by two hands**: A by the lead (pixelfx code), B by a Codex builder writing its own `sn-` effect from the same spec card, blind to A. Different hands give real alternatives instead of parameter tweaks. Both are rendered on the bench in game timing next to "now".
5. **Judging: the new pairwise viewer.** For each slot and form: now vs A vs B as a round-robin league (3 matches), draws allowed, a note per match on what each side does better. The lead reads the records, decides, and says why; only decided effects are wired.
6. **Rules every candidate meets** (from the user's verdicts so far): v2 strength (clearly visible), nothing round the head and face, timed to the motion (a per-step effect ends within the step; landing size follows the drop), the body never hidden, 1 art px = 1 screen px, additive light only on dark-safe colours, nothing while hidden in a bush or in the F2 style.
7. **Wiring: only through the shared hooks** (`get_motion_overlays`, `get_motion_frame_effects`, `character_landing_effect`, a follow-through spawn beside the slash art). Extend `test_motion_fx` per slot.
8. **Checks before the user sees a batch:** bench clips at 2x for detail plus an in-game capture at the match camera (0.85) with 8 fighters, web build on 8060, and a crowded-fight frame-time check on the web build (no effect batch may cost more than a few ms per frame).

## Reasons

- The four tested effects worked because each was custom-sized and timed to one motion; the library pieces were too small and the first pass too timid.
- Slot batches keep the cast consistent and make the user's comparisons fast (same question six times in a row).
- Two independent authors give a real choice; the user said the old viewer got too complex, and three short matches per item is the least judging that still compares against "now".

## Key assumptions

- The user means the always-on effects (attack follow-through, movement, idle, hits), not skills.
- 8-player matches can carry one more layer of effects if each is short and per-character coloured.
- A Codex builder can write pixelfx effect code well enough from a spec card and the four examples.
- The web build has frame-time headroom for roughly 6–10 extra effect sprites per fighter on screen.

## What would change my mind

- Evidence that the matches are already visually busy at the match camera (then S4 idle and S5 hit drop, or become per-player only).
- A measured frame-time cost on the web build that makes per-step and per-hit effects too expensive.
- Codex's pixelfx code needing more fixes than writing B from A's code with a different idea.
- The user wanting to finish one character at a time (D30/D35 style) instead of slot batches.
