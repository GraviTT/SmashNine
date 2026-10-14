# CODEX-ART-56 · The 8-frame walk, third round: consistent frames with a smooth head bob (Frey, Luna)

- Request: 사용자 2026-10-14 "…양 발이 번갈아 가며 앞으로 내딛는 모습이 아니다. 먼저 Frey와 Luna의 걸음걸이를 8프레임으로 변경해볼것." **Candidates only.**
- Unit: branch `codex/walk-56`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.

## Where we are
- **ART-54:** one image of 8 frames. The near leg led both steps (a limp).
- **ART-55:** pose-guided by the colour-coded mannequin (`reports/codex-art-55/walk_reference_*.png`), one generation per frame. The legs now alternate, but the frames do not match each other.
  - Frey's face centre jumps between y = 40 and 53 out of the cycle order: 42, 49, 44, 49, 53, 48, 40, 42. A natural bob is 2–4 px and follows the cycle.
  - Frey's sword flips to point backward in frame 7.
  - Luna's height runs from 78 to 87 px and her area varies by 22 %.
  
  Played at 13.3 fps, this jitters.

## This round: keep the per-frame pose control, add frame-to-frame consistency
Use `art/bakeoff/frey/frey-walk-v4.png` and `art/bakeoff/luna/luna-walk-v3.png` as the starting set.

**Bob target** (face centre y relative to frame 1, in output pixels; + is down):

| Frame | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Pose | contact | down | passing | up | contact | down | passing | up |
| Target y | 0 | +2 | −1 | −2 | 0 | +2 | −1 | −2 |

Tolerance ±1 px. Measure the face centre with an eye or face landmark that works for the character:
- Frey: blue eyes and skin.
- Luna: magenta eyes, because the skin mask catches her legs.

Say what you used and show it on `bob.png`.

**Equipment target:**
- Frey: the sword in the near hand points forward-down in every frame, swinging at most about 15°. The shield stays on the far arm in front.
- Luna: the wand stays in the near hand. The free arm swings opposite the legs.

**For each frame that misses either target, regenerate it:**
- Image 1 = the anchor (look and detail).
- Image 2 = that frame's single mannequin panel (the leg pose).
- Image 3 = **the already accepted neighbouring frame** (frame 1 first, then each next frame from the last accepted one).
- Prompt: "the same drawing as Image 3: identical body proportions, head size, armour, hair mass and equipment angle; change only the legs (and the opposite arm swing) to Image 2's pose."
- Up to 3 generations per frame. Keep the one closest to both targets.

**Normalise:**
- `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00 --ground-all`, one factor per generation matched to the anchor head (`head_scale.py`, 0.96–1.04, or 4× crops when scores are low).
- Never move a frame up or down to fake the bob; the bob comes from the drawing, with the feet on the ground line.

**Acceptance for each character:**
- every frame within the bob tolerance and the equipment target
- the leg check from ART-55 still holds: frames 1 and 5 lead with different legs, 3 and 7 lift the swinging leg
- the 8-frame GIF at 13.3 fps reads as smooth walking with no jitter; say so plainly
- border clear, 4 px margin, spill 0, detail (Frey ≥ 90, Luna ≥ 85)

## Output
- `art/bakeoff/frey/frey-walk-v5.png`, `art/bakeoff/luna/luna-walk-v4.png`: 1024×128, 8 cells.
- Each has a `.json` `{"note": "<Korean>", "fps": 13.3, "frames": 8}`.
- Deliver only a character that passes. Otherwise report the best attempt and what failed.
- Raw generations go to `art/raw/walk-56/` (git-ignored).
- `reports/codex-art-56/<frey|luna>/`: `bob.png` (face centre per frame against the target), `feet.png`, `walk.gif`, `compare.png`, `metrics.json`, prompts.
- `reports/codex-art-56/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/frey/frey-walk-v5.*`, `art/bakeoff/luna/luna-walk-v4.*`, `art/raw/walk-56/**`, `reports/codex-art-56/**`. Hard stop 100 minutes.
