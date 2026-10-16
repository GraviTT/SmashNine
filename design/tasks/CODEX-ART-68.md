# CODEX-ART-68 · Rio: four rows redrawn with the head at the idle's size

- Request: 사용자 2026-10-17 "Rio 머리 다시 그림 후보 Codex로 진행해줘." (sprite audit D40, finding B6: `reports/debate-sprite-audit/decision.md`, picture `reports/sprite-audit-2026-10-16/images/08-rio-head.png`).
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-ui/SmashNine`, branch `codex/art-68` (from the latest main). This clone ran ART-61 unit B (Rio female), so its raws (`art/raw/rio-61b/`) and prompts are there. No other unit runs.
- Method: ART-65 (`design/tasks/CODEX-ART-65.md`): **compact poses at head scale; never shrink the factor below the head match.** Settings as ART-61 (`design/tasks/CODEX-ART-61.md`, `reports/codex-art-61b/`):
  - `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`
  - one factor per row, matched to the anchor head
- **Candidates only.** Nothing under `smash-nine-prototype/` changes; the user picks in the motion viewer.

## Why these rows
The audit measured the heads smaller than the idle's: male `attack` 0.76, female `attack` 0.86, `low_sweep` 0.72, `dimension_slash` 0.72 (`reports/codex-qa-19/head_scale_measurements.json`). Two causes, both from ART-61:
- **`attack`** (128-px cell): it reused the `mana_combo` drawing at the largest factor that fit the cell (0.225 instead of 0.261), so the head came out small.
- **`low_sweep`, `dimension_slash`** (192-px cell): ART-61 reported head 1.00 and 1.02, but on the face they read about 0.72–0.8. The hair-inclusive match was fooled by the long hair.

So the head check this time is on the **face**, not on a box that includes the hair.

## The four rows

| Form (anchor) | Row | Cell | Draw it like this |
| --- | --- | --- | --- |
| `rio_female` (`art/bakeoff/rio/rio_female-idle-v2.png`) | `low_sweep` 6 @30 | 192 | the same low sword sweep, but compact: crouch lower and keep the blade's arc short and close, so the tip stays 4 px inside the cell at head scale |
| `rio_female` | `dimension_slash` 6 @23 | 192 | the same blink thrust, but a shorter lunge: front knee bent, sword arm bent until the strike, the blade extended only on the strike frame and inside the cell |
| `rio_female` | `attack` 6 @21 | 128 | a compact 6-frame sword swing of her own (not the scaled `mana_combo`) that fits 128 at head scale: blade close to the body, short arc, nothing above the head by more than the hair |
| `rio_male` (`art/bakeoff/rio/rio_male-idle-v2.png`) | `attack` 6 @21 | 128 | the same, for the male body |

For every row:
- keep the row's motion and contract:
  - 6 frames
  - feet on the line: y=120 in 128 cells, y=152 in 192 cells
  - the strike drawing on frame 3 (the game shows it when the hit comes out, D38)
- costume exactly as the anchor idle
- one face
- hands, sword and boots intact
- no effects drawn in the sprite

## Checks (each row, before it counts as done)
- **Face match**, 0.96–1.04 against the anchor, on at least 4 frames. Measure on 4× crops: eye-to-eye distance, and face width at the eyes (cheek to cheek, hair excluded).
  - Also run `head_scale.py`.
  - If the two disagree, the face numbers decide.
  - Board: `reports/codex-art-68/<row>-face.png` with each frame's face at 4× next to the anchor's face, same scale.
- Border clear, 4 px margin, spill 0, detail ≥ 79 (as ART-61).
- Feet on the line. The strike pose on frame 3.
- Up to 3 generations per row. A row that still fails: report the best attempt and why it fails.
- **Do not fake the measurement.** Do not paste or scale the idle's head onto other frames; the lead checks every frame at 3× for one face.

## Writable

| Path | For |
| --- | --- |
| `art/bakeoff/rio/rio_female-low_sweep-v2.*`, `rio_female-dimension_slash-v2.*`, `rio_female-attack-v2.*`, `rio_male-attack-v2.*` (`.png` + `.json`: note in Korean, frames, fps, cell, feet, factor) | the candidates |
| `art/raw/rio-68/**` (git-ignored) | raw generations |
| `reports/codex-art-68/**` | boards, `README.md` (Korean), `prompts.txt`, `commit.ps1` (no `git add -f`, nothing under `art/raw/`, no `__pycache__`) |

Hard stop: 120 minutes. Do the rows in the table order. The two 192-px rows come first, because the game uses them (`low_sweep` = female ↓J, `dimension_slash` = K).
