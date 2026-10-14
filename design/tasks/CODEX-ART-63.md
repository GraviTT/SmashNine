# CODEX-ART-63 · Nova walks: redraw only the failing frame (male frame 3, female frame 6)

- Request: 사용자 2026-10-15 "다른 캐릭터들도 진행하고… 단, 이번처럼 여러번 실패로 쓸데없는 컨텍스트 낭비는 하지 말고 성공한 사례만 따라갈것."
- The successful case to repeat is ART-58: keep the good frames and redraw only the frame that fails.
- **This is the last try.** If a body still fails, it keeps its current 6-frame walk.
- Unit: branch `codex/walk-63`, clone `SmashNine-units/builder-art/SmashNine`. The same clone as ART-59 unit B: your best attempts are in `art/raw/walk-59/<stem>/` (`final/prebob.png`, `normalized/`, `refs/`, `poses/`). The Rio row units run at the same time in other clones.

## What failed in ART-59 (`reports/codex-art-59/nova_<body>/`)
- **`nova_male`, frame 3** (passing, standing on the near leg):
  - Its standing foot is at x 68; the target is 58.5 ± 6.
  - The move from frame 3 to frame 4 is 27 px (the limit is 25).
  - Redraw it with the standing foot further back, directly under the hips, and the swinging foot lifted beside the standing ankle.
- **`nova_female`, frame 6** (down, weight on the far leg, near foot lifting behind):
  - The lifted leg shows bare skin. Nova wears a full navy bodysuit with cyan boots, so no skin may show.
  - Your retry fixed that but drew the head 1.10–1.12× too big. Match the head to the anchor with one factor per generation, as always.
  - Also bring the 26.5 px move under 25 px.

## Method (ART-58 + ART-59, unchanged)
- **References:** Image 1 = the idle anchor; Image 2 = that frame's grey mannequin panel; Image 3 = the accepted frame 1. For frame 3, add Image 4 = the legs-together in-game walk frame.
- **Prompt:** ART-59's costume words, plus:
  - for frame 3, the passing-pose words
  - for frame 6, "the full navy bodysuit covers both legs to the cyan boots; no skin"
- **Normalise:** the same settings, one factor per generation matched to the anchor head (0.96–1.04).
- **Assemble:** put the new frame into the ART-59 pre-bob strip (`final/prebob.png`), then run `walk_bob.py` once.
- **Retries:** up to 3 generations per frame. Keep the best by the acceptance below.

## Acceptance (as ART-59)
- `walk_feet.py`:
  - frames 3 and 7: one planted foot within ±6 px of the midpoint target
  - no foot moves more than 25 px between two frames
- Costume against the idle in all 8 frames: no skin on the legs.
- Bob shifts within ±3 px; head 0.96–1.04.
- Border, margin, spill; detail ≥ 90 % of the idle.

## Output
- For each body that passes:
  - `art/bakeoff/nova/nova_<body>-walk-v2.png`: 1024×128, 8 cells
  - `.json` beside it: `note` in plain Korean, `"fps": 13.3`, `"frames": 8`
- `reports/codex-art-63/nova_<body>/`: `costume.png`, `onion.png`, `feet.json`, `bob.png`, `bob.json`, `prompts.txt`.
- `reports/codex-art-63/README.md` (Korean, short) and `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.
- Raw generations go to `art/raw/walk-63/`.

## Writable
`art/bakeoff/nova/nova_male-walk-v2.*`, `art/bakeoff/nova/nova_female-walk-v2.*`, `art/raw/walk-63/**`, `reports/codex-art-63/**`. Hard stop: 35 minutes.
