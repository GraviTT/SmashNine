# CODEX-ART-65 · Rio male: the four missing rows, in poses that fit the cell

- Request: 사용자 2026-10-15 "Rio 스프라이트는 전체 새로운 후보로 채택." Every new Rio candidate goes into the game. The male body still lacks four rows; they block the integration because both bodies share one row table.
- Method: exactly ART-61 (`design/tasks/CODEX-ART-61.md`, your own `reports/codex-art-61a/`). The walk follows ART-59, with ART-64's passing frames.
- **Fix the cause:** at head scale the poses were too big for the cell. Draw more compact poses; never shrink the factor below the head match.
- Unit: branch `codex/rio-65`, clone `SmashNine-units/builder-frey/SmashNine`. This is the same clone as ART-61 unit A, so your raws and prompts are there. No other unit runs.

## The four rows (`rio_male`, anchor `art/bakeoff/rio/rio_male-idle-v2.png`)

| Row | Cell | What failed | Draw it like this |
| --- | --- | --- | --- |
| `walk` 8 @13.3, loop | 128 | at head scale the drawing is 152×130 | a shorter stride: both feet within about 90 px. The sword held low and close along the body, angled down. The cape tight behind. No part may come within 4 px of the cell edge. |
| `fall` 1 | 128 | the vertical pose overflows the height | knees bent and drawn up, arms in, the cape short above. About 100 px tall at most. |
| `shield` 6 @12 | 128 | head 0.94, 4 px margin fails | the sword vertical and close in front of the body, braced, knees slightly bent. Match the head (0.96–1.04) first, then check the margin. |
| `infinity_overdrive` 6 @11 | 192 | the sword overhead leaves the cell top | the sword raised only to head height and angled back over the shoulder, or the body lower in a crouch, so the tip stays 4 px inside the cell |

**The walk**, exactly as ART-59 and ART-64:
- grey mannequin; frame 1 first; then the accepted frame 1 as Image 3 for every other frame
- frames 3 and 7 in the passing pose: the standing foot midway between its neighbours, the lifted foot beside the standing ankle
- `walk_bob.py` once
- `walk_feet.py`: frames 3 and 7 have one planted foot within ±6 px of the midpoint, and no foot moves more than 25 px between two frames
- the costume board against the idle

## Settings and checks (as ART-61)
- `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row matched to the anchor head (`head_scale.py`, 0.96–1.04; 4× crops when scores are low).
- Border clear, 4 px margin, spill 0, detail ≥ 79; one face; hands, sword and boots intact.
- 4× next to the anchor.
- Up to 3 generations per row. A row that still fails: report the best attempt.

## Output
- `art/bakeoff/rio/rio_male-<row>-vN.png` (next free version), plus `.json`:
  - `note`: plain Korean
  - `fps`, `frames`
  - `cell` and `feet` for 192
- `reports/codex-art-65/<row>/`: `prompt.txt`, `compare.png`, `metrics.json`. For the walk, also `onion.png`, `feet.json`, `bob.json`.
- `reports/codex-art-65/README.md` (Korean, short) and `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.
- Raw generations go to `art/raw/rio-65/`.

## Writable
`art/bakeoff/rio/rio_male-{walk,fall,shield,infinity_overdrive}-v*` (new files only), `art/raw/rio-65/**`, `reports/codex-art-65/**`. Hard stop: 70 minutes.
