# CODEX-ART-71 fix-1 · Monsters batch 1: the same size in every row

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan track 2 (monsters).
- Batch 2 (ART-74) showed rows drawn at different sizes: the rune golem's walk was 15% smaller than its idle, the drone's hurt 16% smaller. Its fix pass measured one stable part per row and corrected each row's single factor (`reports/codex-art-74/README.md`, `reports/codex-art-74/fix_pass.py`, the size table). Batch 1 (ART-71: mossling, ember_imp, asgard_aegis_ram, asgard_runic_raven, alfheim_moon_stag, alfheim_moon_moth) was never measured this way.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine`, branch `codex/art-71-fix-1` (from the latest main). The ART-71 raws may still be in this clone under `art/raw/monsters-71/`; if a raw is missing, say so and skip that row.
- Candidates only; nothing under `smash-nine-prototype/` or `tools/` changes; do not run Godot.

## Work
1. For each batch-1 monster, measure one stable part per row against `idle` (as ART-74 fix-1 did), at 4x. The moth's `attack` (blink) is meant to shrink: measure only its first and last frames.
2. Every row within ±5% of `idle`. Fix a row by changing its single factor and rebuilding it from its raw (no per-frame scaling). Rebuild the assembled `<id>_sheet-v1.png`.
3. Also from the ART-71 report: the ram's charge frames floated (feet at y=63–66). Put grounded feet on y=72 (±1) if the raw allows it by the row offset; say what you did.

## Output
- Replace the affected `art/bakeoff/monsters/<id>-<row>-v1.png` + `.json` (factor updated) and `<id>_sheet-v1.png`.
- `reports/codex-art-71/fix-1/README.md` (Korean): the size table (monster × row, part, size, ratio before and after), the ram feet, before/after boards.
- `reports/codex-art-71/fix-1/commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`. Do not run it.

## Writable
`art/bakeoff/monsters/<batch-1 ids>-*-v1.*`, `art/bakeoff/monsters/<batch-1 ids>_sheet-v1.png`, `art/raw/monsters-71/**`, `reports/codex-art-71/fix-1/**`.

Hard stop: 90 minutes.
