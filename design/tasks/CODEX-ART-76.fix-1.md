# CODEX-ART-76 fix-1 · Monsters batch 3: the same size in every row

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan track 2 (monsters).
- Batch 2 (ART-74) showed rows drawn at different sizes: the rune golem's walk was 15% smaller than its idle, the drone's hurt 16% smaller. Its fix pass measured one stable part per row and corrected each row's single factor (`reports/codex-art-74/README.md`, `reports/codex-art-74/fix_pass.py`, the size table). Batch 3 (ART-76: muspelheim_magma_boar, niflheim_glacier_wolf, niflheim_frost_owl, jotunheim_storm_wisp, yggdrasil_root_guardian, yggdrasil_root_oracle) was never measured this way.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/tester/SmashNine`, branch `codex/art-76-fix-1` (from the latest main). The ART-76 raws are in this clone under `art/raw/monsters-76/`; if a raw is missing, say so and skip that row.
- Candidates only; nothing under `smash-nine-prototype/` or `tools/` changes; do not run Godot.

## Work
1. For each batch-3 monster, measure one stable part per row against `idle` (as ART-74 fix-1 did), at 4x.
2. Every row within ±5% of `idle`. Fix a row by changing its single factor and rebuilding it from its raw (no per-frame scaling). Rebuild the assembled `<id>_sheet-v1.png`.
3. Also from the ART-76 report: the boar's idle detail is under 85 on three frames, and the boar (3 px) and wolf (5 px) attacks barely move forward (target 8 px). Improve them only if a rebuild from the raw can (factor, offset); otherwise list them.

## Output
- Replace the affected `art/bakeoff/monsters/<id>-<row>-v1.png` + `.json` (factor updated) and `<id>_sheet-v1.png`.
- `reports/codex-art-76/fix-1/README.md` (Korean): the size table (monster × row, part, size, ratio before and after), point 3, before/after boards.
- `reports/codex-art-76/fix-1/commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`. Do not run it.

## Writable
`art/bakeoff/monsters/<batch-3 ids>-*-v1.*`, `art/bakeoff/monsters/<batch-3 ids>_sheet-v1.png`, `art/raw/monsters-76/**`, `reports/codex-art-76/fix-1/**`.

Hard stop: 90 minutes.
