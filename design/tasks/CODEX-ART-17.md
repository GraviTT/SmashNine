# CODEX-ART-17 · Hazard, monster and seal art from the in-game art QA

- Request: 사용자 2026-10-08 "그림이 어색해지는 것은 모두 Codex에게 맡기고, 퀄리티의 문제가 있어 보이는 것들도 스스로 판단하여 보강할것." Findings from CODEX-QA-15 (`reports/codex-qa-15/README.md`, evidence in `reports/codex-qa-15/evidence/`).
- Unit: Builder · Lead (integrates the code side): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/hazard-art-17`
- Running at the same time: Codex analyst (bot retest, headless). **This task does not edit product source.**
- Timeout: given in the prompt.

## Deliverables (1 art pixel = 1 screen pixel, like the v2 fighters; style of the realm sets)

| # | File(s) | Size | What | QA finding |
| --- | --- | --- | --- | --- |
| 1 | `assets/art/hazards/quake_warning.png` | 4 frames x 96x16 (384x16) | horizontally **tileable** cracking-ground pulse laid on every platform top during the Jotunheim quake warning (replaces a flat 10 px yellow bar) | P1 #4 |
| 2 | `assets/art/hazards/quake_impact.png` | 6 frames x 128x64 | dust-and-rock burst played along platforms when the quake hits (bottom-centre anchor) | P1 #4 |
| 3 | `assets/art/hazards/vine_bridge.png` | 96x24 (same size) | the temporary bridge with a bright yellow-green 1–2 px top rim and buds so it stands out from the forest and the normal platforms; ends readable when tiled | P2 #6 |
| 4 | `assets/art/hazards/light_beam_base.png`, `light_beam_mid.png`, `light_beam_top.png` | base 96x64, mid **6 frames x 96x128 vertically tileable**, top 96x64 | Asgard light column: the middle repeats up a 1080 px column (no more one 64x128 picture stretched), base where it hits the floor, top fading into the sky | P2 #7 |
| 5 | `assets/art/hazards/fire_pillar_base.png`, `fire_pillar_mid.png`, `fire_pillar_top.png` | same layout | Muspelheim fire pillar (up to 690 px tall), flame tip on top | P2 #7 |
| 6 | `assets/art/monsters/mossling_sheet.png`, `ember_imp_sheet.png` | same sizes (576x384, 96 px cells, same frames and positions) | add a 1–2 px rim of the opposite colour temperature on every frame (mossling: teal/cream; imp: violet/pale gold) so they read against their own realms | P2 #10 |
| 7 | `assets/art/effects/yuki_seal_idle.png` | 4 frames x 64x64 | Yuki's planted binding talisman while it waits (5 s): a small floating paper seal with a faint pulse; replaces a placeholder rectangle | P1 #3 |

Keep the old `light_beam.png` and `fire_pillar.png` (fallback). Update `assets/art/hazards/README.md` (sizes, anchors, tiling direction, frame rate) and the monster README if there is one. Check tiling seams at 2x; check monsters against their realm backgrounds (`assets/art/realm_vanaheim/bg_far.png`, `realm_muspelheim/bg_far.png`) in a preview.

Generate with your image tool; post-process with Godot's Image API (scripts under `smash-nine-prototype/tests/art_preview/hazard_art_17/`); do not install packages or download files. Big inspection images go under `reports/codex-art-17/`.

## Writable paths

`smash-nine-prototype/assets/art/hazards/**`, `smash-nine-prototype/assets/art/monsters/mossling_sheet.png`, `ember_imp_sheet.png`, `smash-nine-prototype/assets/art/effects/yuki_seal_idle.png`, `smash-nine-prototype/tests/art_preview/hazard_art_17/**`, `reports/codex-art-17/**`.

## Report (`reports/codex-art-17/README.md`, Korean)

Before (the QA evidence) / after previews per item, seam checks, anchors and frame rates for the lead's integration, what a human must judge. Commit, or `reports/codex-art-17/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.

## Round 2 · fixes from the lead's in-game check (branch `codex/hazard-art-17b`)

Integrated in game (column = top + middle repeated down + base, scaled to the column width; quake cracks along platform tops; impact bursts; Yuki seal). Lead captures: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/lead-captures/art17/hazard_01_active.png` (Asgard beams), `hazard_05_active.png` (Muspelheim pillars), `hazard_08_warning.png` / `hazard_08_active.png` (quake).

| # | File | Measured problem | Fix |
| --- | --- | --- | --- |
| 1 | `light_beam_mid.png` | frames 2–4 (index 1–3) have rows 111–123 empty or thin (empty rows 13 / 2 / 4, rows under 1/3 filled 0 / 11 / 9); frames 1, 5, 6 are full | every frame covers all 128 rows like frame 1, and the top and bottom 4 rows match across **all six** frames, so any frame tiles under any frame |
| 2 | `fire_pillar_mid.png` | frames 2–5 (index 1–4): empty rows 12 / 2 / 6 / 7, thin rows 1 / 11 / 7 / 6, all in rows 111–123 | same |
| 3 | `quake_impact.png` | frame sizes run small, big, medium, tiny, big, medium; the 4th drops back | say whether it is a deliberate second burst; otherwise order it to burst then settle |

In game every repeat of a short frame showed a ~12 px gap that flickered as the frames changed. Verify with numbers (per frame: empty rows 0, rows under 1/3 filled 0) and a preview that tiles frames in the sequence 1,2,3,4,5,6 and 6,1 vertically at 2x. Same writable paths; report section "Round 2" in `reports/codex-art-17/README.md`; commit script `reports/codex-art-17/commit-round2.ps1`.

## Round 3 · column joints (branch `codex/hazard-art-17c`)

**My round-2 card was wrong:** it asked for the top and bottom 4 rows to match across all six frames. The game shows the **same frame in every repeat** of a column at a time (one tiled strip, frames swapped together), so each frame only has to tile with **itself**. Forcing frame 1's 67 px band onto the narrower frames now sticks out on both sides at every repeat and reads as rings around the column (lead capture `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/lead-captures/art17b/hazard_05_active.png`; zoom at fire x 410–530, y 230–570).

Measured (opaque width in px: body rows 20–107 / rows 0–3 and 124–127):

| Frame | fire_pillar_mid | light_beam_mid |
| --- | --- | --- |
| 1 | 67 / 67 | 66 / 67 |
| 2 | 56 / 67 | 52 / 67 |
| 3 | 54 / 67 | 46 / 67 |
| 4 | 49 / 67 | 55 / 67 |
| 5 | 57 / 67 | 63 / 67 |
| 6 | 63 / 67 | 64 / 67 |

Fix both `fire_pillar_mid.png` and `light_beam_mid.png` (same sizes, frame order and timing): every frame seamless with itself — its bottom rows continue into its own top rows in width, centre and pattern; no row wider than the frame's body; no dark line at the joint; keep all 128 rows filled. Edit the existing frames (no regeneration). Verify with numbers (per frame: width of rows 0–3 and 124–127 within ±2 px of its body, wrap difference between row 127 and row 0) and a preview tiling each frame 3x under itself at 2x. Same writable paths; report section "Round 3"; commit script `reports/codex-art-17/commit-round3.ps1`.

## Round 4 · one dark row in the fire frames (branch `codex/hazard-art-17d`)

After round 3 the joints are clean (light beam seamless in game). One thin dark line still crosses every repeat of the fire pillar in game, about 23 px above each joint at the in-game scale (lead capture `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/lead-captures/art17c/hazard_05_active.png`, rows y = 255, 391, 527 at x 445–495). It is **row 110** of `fire_pillar_mid.png` frames 2–5 — where the round-2 fill of rows 111–123 meets the original frame's dark bottom edge. Measured centre brightness (x 36–59 of the frame):

| Frame | rows 108 / 109 / **110** / 111 / 112 |
| --- | --- |
| 2 | 0.66 / 0.63 / **0.49** / 0.72 / 0.70 |
| 3 | 0.70 / 0.61 / **0.52** / 0.74 / 0.74 |
| 4 | 0.72 / 0.70 / **0.51** / 0.50 / 0.52 (rows 110–112) |
| 5 | 0.57 / 0.59 / **0.41** / 0.48 / 0.48 |

Frame 1's soft valley at rows 107–112 is the original art; leave it. `light_beam_mid` frames 2–4 dip only softly at rows 108–110 (0.73–0.84 vs 0.88+); smooth them only if it shows at 1x. Blend the dark row(s) into their neighbours (same colours, no new shapes); keep everything else, including the round-3 joints. Verify: no row in rows 100–120 more than 0.08 darker than the mean of its two neighbours (centre band), and the round-3 joint numbers unchanged. Same writable paths; report section "Round 4"; commit script `reports/codex-art-17/commit-round4.ps1`.
