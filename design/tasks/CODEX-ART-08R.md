# CODEX-ART-08R · Rework of the v2 sheets (proportion, clean cell edges, no red fringe)

- Request: same as `CODEX-ART-08` (user 2026-10-07: "등신대 제안대로 진행. 해상도 제안대로 진행."). This is the lead's review of the first pass.
- Unit and branch: the unit that made the sheets, continuing on its own branch (`codex/hires-a` or `codex/hires-b`) from its first-pass commit. Same writable paths as `CODEX-ART-08`.
- **Keep** the main illustrations and face portraits from the first pass (they are good). **Redo only the v2 sheets.**

## Findings (lead review, measured with `tests/art_preview/hires_<a|b>/sheet_audit.gd`)

Audit of the first pass (v1 sheets for comparison: edge 0, fringe 0):

| Sheet | edge_px | fringe_px | idle height | Lead's look |
| --- | ---: | ---: | ---: | --- |
| rio_male_sheet.png | 121 | 0 | 102 | head ≈ 40 px of ≈ 102 → about 2.5 heads, target 3 |
| rio_female_sheet.png | 259 | 0 | 100 | same |
| luna_sheet.png | 238 | 69 | 92 | red outline pixels around the silhouette; effects cut square at cell borders; taller than 84 |
| luna_brave_sheet.png | 164 | 43 | 92 | same |

(Unit A: run the audit on your own first-pass sheets and treat the same thresholds as your findings.)

1. **Proportion.** The sprites are still close to the old chibi. The head (top of the skull/hair mass, not spikes, to the chin) must be about total height / head count: Frey ≈ 33 px of 100, Rio ≈ 32–33 px of 98/96, Nova ≈ 37 px of 92/90, Yuki ≈ 35 px of 88, Luna/Brave Luna ≈ 38 px of 84. Longer legs and torso, narrower head. Use the new main illustration as the body reference, not the old sheet.
2. **Clean cell edges.** `edge_px` must be 0: the outer 2 px ring of every used cell stays transparent. Keep weapons, slash arcs and shield effects inside the cell (scale effects down or shorten them); never clip them, and never let pieces of a neighbouring frame bleed in.
3. **No red fringe.** `fringe_px` must be 0 (pure red pixels left by background removal around the silhouette). Fix the matte, not just the count: no coloured halo of any hue around the outline.
4. Feet y=120, centre x≈64 as before; idle height (feet to topmost opaque row, hair included) within +6 px of the target height.

## Report

- Audit output for each sheet before and after (`godot --headless --path smash-nine-prototype -s tests/art_preview/hires_<a|b>/sheet_audit.gd -- res://assets/art/<id>/<file>`).
- Per sheet: idle frame 0 enlarged 4x with horizontal guide lines at the top of the head, the chin and the feet, and the measured head ratio (total / head).
- Updated contact sheet (v1 at 2x, v2 at 1x, face, illustration). Update `reports/codex-art-08<a|b>/README.md` (Korean) with a "rework" section.
- Commit, or update `reports/codex-art-08<a|b>/commit.ps1` (writable paths only; message ending `Co-Authored-By: Codex <noreply@openai.com>`).

## Unit A first pass (lead audit, 14:43)

| Sheet | edge_px | fringe_px | idle height | Lead's look |
| --- | ---: | ---: | ---: | --- |
| frey_sheet.png | 459 | 0 | 111 | head ≈ 45 px of ≈ 111 → about 2.5 heads, target 3 (100 px); short bars from neighbouring frames under the attack and shield rows |
| nova_male_sheet.png | 102 | 0 | 93–97 | close to 2.5; clipped at cell edges |
| nova_female_sheet.png | 556 | 13 | 93–95 | clipped at cell edges in most rows |
| yuki_sheet.png | 686 | (4810) | 99–100 | the fringe count is mostly her red outfit, so it does not apply to Yuki: check the outline for halos by eye and report it; too tall for 88 |
