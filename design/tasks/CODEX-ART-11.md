# CODEX-ART-11 · Monsters, fireball and soul crystal at the fighters' pixel density

- Request: routine 2026-10-08 "남는 시간 작업: 몬스터·크리스탈 128px·1배 Codex 카드" (approved plan) and 사용자 "Codex를 적극 활용할것."
- Unit: Builder · Lead (integrates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/monsters-v2-b`
- Running at the same time: Codex builder `codex/sprite-fix-a` (fighter sheet fixes). **This task does not edit product source.**
- Timeout: given in the prompt.

## Why

Fighters are now drawn at 1x (1 art pixel = 1 screen pixel, `CODEX-ART-08`). Monsters, the fireball and the soul crystal are still 64 px / 48 px art blown up 1.5x, so they look coarser than the fighters. Redraw them at 1x **at the same on-screen size**, keeping their accepted designs (`assets/art/monsters/`, `assets/art/objects/`, `reports/codex-art-05a/preview.png`).

## Deliverables (replace the files at the same paths)

| File | Old | **New** | Contract |
| --- | --- | --- | --- |
| `monsters/mossling_sheet.png` | 384x256, 64 px cells at 1.5x | **576x384, 6 x 4 cells of 96x96 at 1x** | rows idle 4 / walk 6 / attack 4 / hurt 1, facing right, **feet y=72**, centre x≈48 |
| `monsters/ember_imp_sheet.png` | same | **same as above** | attack row = throwing a fireball |
| `monsters/ember_fireball.png` | 24x24 at 1.5x | **36x36 at 1x** | flying right |
| `objects/soul_crystal.png` | 4 x 48x64 at 1.5x | **4 x 72x96 at 1x (288x96)** | shimmer loop, crystal bottom at y≈84 |
| `objects/soul_crystal_shatter.png` | same | **4 x 72x96 (288x96)** | breaking |

Every frame keeps at least 4 px of transparent margin: no straight cut edges, no fragments (the lead checks with `smash-nine-prototype/tests/analysis/lead/frame_audit.gd`-style bounding-box tests: a bounding-box edge with 16+ filled pixels counts as a cut). Same pixel-art style, outline weight and palette discipline as the v2 fighter sheets. Generate with your image tool; post-process with Godot's Image API; do not install packages or download files.

## Writable paths

`smash-nine-prototype/assets/art/monsters/**`, `smash-nine-prototype/assets/art/objects/**`, `smash-nine-prototype/tests/art_preview/monsters_v2_b/**`, `reports/codex-art-11/**`. Everything else is read-only.

## Report (`reports/codex-art-11/README.md`, Korean)

Old (at 1.5x) vs new (at 1x) side by side next to a v2 fighter sheet, alignment table (feet, centre, margin per frame), what a human must judge. Commit, or `reports/codex-art-11/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
