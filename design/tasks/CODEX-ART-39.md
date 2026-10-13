# CODEX-ART-39 · Frey: one head size in every row (fix round after ART-38)

- Request: D32 ② (사용자 2026-10-11: 머리 크기를 한 캐릭터의 모든 프레임에서 같게) and D33 (Frey 재작업, 6프레임). **Candidates only**; nothing in `smash-nine-prototype/` changes.
- Unit: one unit, branch `codex/frey-39`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.
- Settings stay: `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`.

## What the lead measured
The ART-38 rows have the detail, but their heads are not the anchor's size. The factor per sheet was chosen by eye, and big poses were shrunk to fit the cell.

The new lead tool is `tools/sprite_pipeline/head_scale.py`. It finds the anchor head (`frey-idle-v2` frame 1: wings, circlet, face) in each frame at scales 0.60–1.60 and takes the median over frames scoring ≥ 0.6. Self-test: the anchor rescaled ×0.7 … ×1.3 is recovered exactly.

| Row | Factor used | Head scale | Head-matched factor |
| --- | ---: | ---: | ---: |
| idle-v2 (anchor) | 0.2418 | 1.00 | — |
| walk-v2 | 0.2797 | 1.00 | ok |
| jump-v1 | 0.205 | 1.02 | ok |
| fall-v1, hurt-v1 | 0.205 | low score (eyes shut, tilted) | same image and factor as jump → ok unless your 4× look disagrees |
| shield-v1 | 0.2762 | 1.06 | 0.261 |
| attack-v4 | 0.235 | 0.92 | 0.255 |
| attack_up-v1 | 0.27 | 0.90 | 0.30 |
| attack_down-v1 | 0.255 | 0.82 | 0.311 |
| attack_air_side-v1 | 0.245 | 0.80 | 0.306 |
| dash_strike-v1 | 0.245 | 0.76 | 0.322 |
| rising_cleave-v2 | 0.25 | 0.70 | 0.357 |
| spike_followup-v3 | 0.24 | 0.74 | 0.324 |
| descent-v3 | 0.24 | 0.68 | 0.353 |
| tumble-v3 | 0.27 | 0.88 (frames 1 and 6; the rotated ones score low) | 0.307 |

## Tasks
1. **`normalize.py --lift-scale K`** (0–1, default 1): multiply every airborne lift in the sheet by the same K. The game's physics already puts her in the air, so the lift inside the cell is only cosmetic; scaling it uniformly keeps the arc. Add a test. Add a line for `head_scale.py` in the README.
2. For every row in the table that is not ok:
   - Re-normalise the same raw (`art/raw/frey-37/`, `art/raw/frey-38/`) at the head-matched factor.
   - If frames do not fit, lower `--lift-scale` (one value for the sheet) and/or use one common x shift for the whole sheet.
   - If a frame still does not fit, **regenerate that motion once** with a compact pose:
     - sword angled up/back or down/forward instead of fully extended
     - hair and cape closer to the body, knees tucked in the air
     - Image 1 = the anchor, so she is drawn at the anchor's size
     - say in the prompt that the whole pose, sword included, must fit a square about 1.2× her standing height on each side
   - Then normalise at the factor that gives head scale 1.00.
   - Never shrink to fit; never one frame at its own scale.
3. Acceptance for every row: `head_scale.py` median 0.96–1.04 (rotated tumble frames excepted; judge those by eye). Also:
   - all frames in the cell: border clear, 4 px margin
   - spill 0, detail ≥ 90
   - one face; arms, sword and shield intact; no effects
4. Look at every frame at 4× next to the anchor before calling a row done.
5. Output: overwrite the row's candidate **in place**, same file name, so the viewer keeps one candidate per row. Update the `.json` note to say the head is matched. `reports/codex-art-39/<row>/`: `compare.png` (4×, anchor | candidate), `metrics.json` (factor, lift scale, head-scale result), `prompt.txt` if regenerated. Raw generations go to `art/raw/frey-39/<row>/`.
6. Report `reports/codex-art-39/README.md` (Korean): the table above with the after column, which rows were regenerated, what is still wrong. Plus `commit.ps1`.

## Writable
`tools/sprite_pipeline/**`, `art/bakeoff/frey/*` (the rows above, in place; leave `retired/` alone), `art/raw/frey-39/**`, `reports/codex-art-39/**`. Hard stop 100 minutes; finish the row in progress, list the rest.
