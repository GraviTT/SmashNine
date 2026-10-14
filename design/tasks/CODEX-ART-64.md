# CODEX-ART-64 · Rio female walk: redraw only the passing frames 3 and 7 (last try)

- Request: 사용자 2026-10-15 "…이후 Rio의 스프라이트 리메이크 진행… 성공한 사례만 따라갈것." The successful case is ART-58 (and ART-63 for Nova male): keep the good frames and redraw only the failing ones. **This is the last try**; if it fails, the lead decides with what exists.
- Unit: branch `codex/walk-64`, clone `SmashNine-units/builder-ui/SmashNine`. This is the same clone as ART-61 unit B: your walk attempt is in `reports/codex-art-61b/walk/` (`prebob.png`, the `frame-*` folders) and `art/raw/rio-61b/walk/`. Other units run in other clones.

## What failed (`reports/codex-art-61b/walk/`, `walk_feet.py`)
| Frame | Standing foot | Target | Other problem |
| --- | --- | --- | --- |
| 3 (stands on the near leg) | 87 | 78.5 ± 6 | the lifted toe drags in the ground band; the move 3 → 4 is 27 px |
| 7 (stands on the far leg) | 86 | 78.75 ± 6 | the move 7 → 8 is 25.5 px |

Redraw both as true passing poses:
- the standing foot directly under the hips, further back than now
- the swinging foot lifted 6–12 px beside the standing ankle, its toe clear of the ground

## Method (ART-58 + ART-61, unchanged)
- **References:**
  - Image 1 = `art/bakeoff/rio/rio_female-idle-v2.png` frame 0, 4×
  - Image 2 = that frame's grey mannequin panel
  - Image 3 = your accepted walk frame 1
  - Image 4 = a legs-together frame of the old in-game walk (`art/bakeoff/rio/rio_female-walk-v2.png`; pick it with `walk_feet.py`)
- **Prompt:** your ART-61 walk words plus ART-58's passing-pose words.
- **Normalise:** the same settings. One factor per generation, matched to the new anchor's head (0.96–1.04).
- **Assemble:** put the two new frames into your pre-bob strip (`prebob.png`) and run `walk_bob.py` once.
- **Retries:** up to 3 generations per frame. Keep the best.

## Acceptance (as ART-59)
- `walk_feet.py`:
  - frames 3 and 7 have exactly one planted foot, within ±6 px of the target
  - no foot moves more than 25 px between two frames
- Costume against the idle in all 8 frames.
- Bob shifts within ±3 px.
- Border, margin, spill; detail ≥ 73.

## Output
- If it passes: `art/bakeoff/rio/rio_female-walk-v3.png` (1024×128, 8 cells) and a `.json`: `note` in plain Korean, `"fps": 13.3`, `"frames": 8`.
- Either way, save the best strip as `reports/codex-art-64/best.png`, plus `onion.png`, `feet.json`, `bob.png`, `bob.json`, `prompts.txt`.
- `reports/codex-art-64/README.md` (Korean, short) and `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.
- Raw generations go to `art/raw/walk-64/`.

## Writable
`art/bakeoff/rio/rio_female-walk-v3.*`, `art/raw/walk-64/**`, `reports/codex-art-64/**`. Hard stop: 30 minutes.
