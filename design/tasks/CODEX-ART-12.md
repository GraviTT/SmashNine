# CODEX-ART-12 · The last 11 cut frames: poses that overlap in the source

- Request: routine 2026-10-08 "스프라이트가 조금씩 잘려서 어색한 부분들이 보였다 … 스프라이트 하나하나씩을 보고 분석" and 사용자 "Codex를 적극 활용할것."
- Unit: Builder · Lead (verifies and merges): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/sprite-fix-a2`
- Running at the same time: Codex analyst `codex/ult-review-12` (read-only review). **This task does not edit product source.**
- Timeout: given in the prompt.

## Where things stand

The v2 sheets (`assets/art/<id>/<id>[_body]_sheet.png`, 768x896, 6x7 cells of 128 px, feet y=120) were cut out of generated sources (`*_v2_source.png`; Rio: `*_v2_rework_source.png`) with equal-width rectangles, so anything crossing a rectangle line was cut. Tonight the lead re-extracted 37 frames by connected pixel groups (`smash-nine-prototype/tests/art_preview/frame_reextract_lead/reextract.gd`, boards in `routine/2026-10-08-night/results/reextract/`). That tool cannot separate poses whose pixels **touch or overlap** in the source, so these 11 frames are still cut (row = animation row, c = column, 0-based):

| Sheet | Frames | What is wrong |
| --- | --- | --- |
| `frey/frey_sheet.png` | attack r4c2, r4c3 | r4c2's sword and blue slash are mostly missing; r4c3 is cut on both sides (cape and sword) |
| `nova/nova_female_sheet.png` | attack r4c1, r4c2 | cut at the right / left edge |
| `rio/rio_female_sheet.png` | attack r4c0, r4c1, r4c2 | r4c0's slash is cut at the top; r4c1-2 hair and cape cut by a vertical line on the left |
| `rio/rio_female_sheet.png` | shield r5c1, r5c2, r5c3, r5c4 | the crystal shield is cut by a vertical line on the right |

See them enlarged in `routine/2026-10-08-night/results/frame_audit_after/<sheet>_flags.png` (red boxes; ignore the other red boxes, which are straight edges in the source art itself) and the source poses in the source images (Rio female shield row: `routine/2026-10-08-night/results/reextract/rio_female_source_row5.png`; there each pose's sword runs under the next pose's hair).

## Task

For each of the 11 frames: take that pose **whole** from its source, separating it from the neighbouring pose by hand where they touch (a mask you decide by looking at the enlarged source; the neighbour's sword/hair/cape must not come along). Then scale it with nearest neighbour to **the same scale as the rest of that sheet** (the body must stay the size of the neighbouring frames: compare head and body height with the frame before and after) and place it where the current frame's body is (feet y=120, same x as the current body, so it does not jump). Keep a 4 px transparent margin; if a wide effect cannot fit, shrink only that effect or let the effect stop short, never the body. Binary alpha, the sheet's palette as is, no new drawing except a minimal hand touch where a mask boundary leaves a hole.

Do not change any other frame: the other 173 frames must stay pixel-identical (check it).

## Acceptance (the lead runs these)

- `godot --headless --path smash-nine-prototype -s tests/analysis/lead/frame_audit.gd -- --out=<dir> <the 3 sheets>`: the 11 frames no longer flagged, or flagged only for a straight edge that is in the source art itself (say which).
- Side-by-side board per frame (current | fixed, 3x) and the frame in its row at 2x so the size and position match its neighbours.

## Writable paths

`smash-nine-prototype/assets/art/frey/frey_sheet.png`, `smash-nine-prototype/assets/art/nova/nova_female_sheet.png`, `smash-nine-prototype/assets/art/rio/rio_female_sheet.png`, `smash-nine-prototype/tests/art_preview/sprite_fix_a2/**`, `reports/codex-art-12/**`. Everything else is read-only.

## Report (`reports/codex-art-12/README.md`, Korean)

Per frame: what was cut, how you separated it, before/after board; the pixel-identical check for the other frames; what a human should still judge. Commit, or `reports/codex-art-12/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.

## Round 2 (branch `codex/sprite-fix-a3`, 2026-10-08 ~03:00)

Round 1 fixed Rio female shield r5c1–r5c4 (merged `21b3682`). Still cut, all **attack** frames where the body or effect touches the neighbouring pose in the source:

| Sheet | Frames |
| --- | --- |
| `rio/rio_female_sheet.png` | r4c0 (slash cut at top), r4c1, r4c2 (hair/cape cut on the left), r4c3 (cape cut on the left) |
| `frey/frey_sheet.png` | r4c2 (sword and blue slash missing), r4c3 (cut both sides) |
| `nova/nova_female_sheet.png` | r4c1, r4c2 |
| `luna/luna_sheet.png` | r4c3 (wand and sparkles cut on the left) |

Same rules as above, plus: the attack frames in these rows were shrunk by the original builder to fit the cell, so **match the body size of the other frames in the same attack row** (not the idle size). Writable paths add `smash-nine-prototype/assets/art/luna/luna_sheet.png`, `smash-nine-prototype/tests/art_preview/sprite_fix_a3/**`, `reports/codex-art-12/round2/**`. Keep inspection images out of `smash-nine-prototype/` (put them under `reports/codex-art-12/round2/`).
