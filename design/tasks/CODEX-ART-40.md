# CODEX-ART-40 · Frey move rows in 192-px cells at the anchor's head size (D34)

- Request: the user chose "기술 시트 칸을 192px로" (2026-10-13). The lead had shown that Frey's big moves do not fit a 128-px cell at the idle head size, and that the current game sheets shrink them too (heads 0.62–0.86). Decision D34; rules D32 and D33. **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: one unit, branch `codex/frey-40`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.
- 192-px cell:
  - feet line y=152 (cell/2 + 56: on screen this is the same place as y=120 in a 128 cell)
  - torso centre x=96
  - same pixel scale as the base sheet; nothing is scaled down
- Settings stay: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.

## Tasks
1. **`normalize.py --cell N`** (default 128) **and `--feet-y Y`** (default cell/2 + 56, giving 120 for 128 and 152 for 192):
   - Put the torso anchor at cell/2.
   - Border, margin and output checks use that cell.
   - The compare board shows a 128 reference row next to a 192 candidate at the same pixel scale, feet lines aligned.
   - Add tests. Do not change how `head_scale.py` measures; it already reads any strip height.
2. Make these rows 192-px candidates with head scale 0.96–1.04 (`head_scale.py --anchor art/bakeoff/frey/frey-idle-v2.png:0`):
   - `attack_up` (now 0.96 at 0.295)
   - `attack_down`, `attack_air_side`, `dash_strike`, `rising_cleave`, `spike_followup`, `descent`
   - `tumble` (0.98 at 0.307 with lift scale 0; use lift 1.0 again now that there is room)
   - the J chain `attack`: it moves to the move sheet as the row `attack_chain` when the lead puts it in the game
   
   For each row:
   - Source: the better drawing of the ART-38 raw and the ART-39 regeneration. Say which you used and why.
   - Re-normalise at the head-matched factor, `--lift-scale 1` unless a frame does not fit.
   - Only if a frame still does not fit in 192, regenerate once with a compact pose.
3. Acceptance for every row:
   - head-scale median 0.96–1.04
   - border clear, 4 px margin
   - spill 0, detail ≥ 90
   - one face; arms, sword and shield intact; no effects
   - looked at 4× next to the anchor
4. Output:
   - Overwrite in place (same `frey-<row>-vN` names) as 1152×192 strips.
   - The `.json` adds `"cell": 192, "feet": 152`. The `frey-attack-v4.json` note says it becomes the move-sheet row `attack_chain`.
   - `reports/codex-art-40/<row>/`: `compare.png` (4×, anchor | candidate) and `metrics.json` (factor, lift scale, head scale, source raw).
   - Raw generations, if any, go to `art/raw/frey-40/`.
5. Report `reports/codex-art-40/README.md` (Korean): a table per row (head scale, factor, lift, source), what is still wrong. Plus `commit.ps1`: no `git add -f`, nothing under `art/raw/`.

## Writable
`tools/sprite_pipeline/**` (`head_scale.py` measuring logic unchanged), `art/bakeoff/frey/*` (the 9 rows above, in place; leave `retired/` alone), `art/raw/frey-40/**`, `reports/codex-art-40/**`. Hard stop 75 minutes.
