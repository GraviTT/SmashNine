# CODEX-ART-57 · The 8-frame walk, fourth round: the idle's costume kept, a grey mannequin, the bob set afterwards (Frey, Luna)

- Request: 사용자 2026-10-14 "…양 발이 번갈아 가며 앞으로 내딛는 모습이 아니다. 먼저 Frey와 Luna의 걸음걸이를 8프레임으로 변경해볼것." **Candidates only.**
- Two units run at the same time, one character each. They share no files.

  | Unit | Branch | Clone |
  | --- | --- | --- |
  | Frey | `codex/walk-57-frey` | `SmashNine-units/builder-frey/SmashNine` |
  | Luna | `codex/walk-57-luna` | `SmashNine-units/builder-art/SmashNine` |

## What went wrong in ART-56 (the lead's check)
The bob missed by 3–4 px in one or two frames. The bigger problem is the costume, which no check caught.

- **Frey:** the idle and the in-game walk wear brown boots and dark leggings.
  - In the new frames the near leg has white greaves and orange-red boots, and the far leg is navy.
  - In frames 3–4 the far leg turns white too.
  - Frames 1–2 have brown boots; frames 3–8 have red ones.
- **Luna:** the idle and the in-game walk wear knee-high purple boots and hold the wand up in front, star at the top right. The new frames have striped stockings with ankle boots, and the wand is held behind, pointing down.

Two causes:
- The mannequin's orange and blue leaked into the legs.
- Each frame copied the previous one, so the drift grew from frame to frame.

In the game the idle and the walk switch constantly, so the walk must wear exactly the idle's costume and hold the prop the same way.

## Method
**1. Grey mannequin (code, no generation).**
- Copy `reports/codex-art-55/make_walk_reference.py` to `reports/codex-art-57/<id>/make_walk_reference.py`. Keep the 8 poses and proportions.
- Colours, greys only:
  - near limbs light grey `#D0D0D0`, rim `#8A8A8A`
  - far limbs dark grey `#5A5A5A`, rim `#2E2E2E`
  - head and torso mid grey
- Draw the arms the way the character holds them:
  - Frey: the near (sword) arm forward-down, swinging at most 10°; the far (shield) arm steady in front.
  - Luna: the near (wand) arm raised in front and steady; the far (free) arm swings opposite the legs.
- Output: `walk_reference_<id>.png`. Check panels 1 and 5 show different shades in front.

**2. References for each generation.**

| Image | Frame 1 | Frames 2–8 |
| --- | --- | --- |
| 1 · look and detail | idle frame 0, 4× nearest (`art/bakeoff/frey/frey-idle-v2.png` / `art/bakeoff/luna/luna-idle-v3.png`) | same |
| 2 · pose | that frame's single mannequin panel | same |
| 3 · costume while walking | in-game walk frame 0, 4× nearest (`art/bakeoff/frey/frey-walk-v2.png` / `art/bakeoff/luna/luna-walk-v1.png`) | **the accepted frame 1**, for every later frame (never the neighbour) |

**The prompt says, in words:**
- "Image 2 is only a pose guide. Its greys are not clothing."
- Change only the legs and the free arm to Image 2's pose. Keep everything else as in Images 1 and 3.
- The costume:
  - **Frey:**
    - brown leather boots, dark leggings, and silver knee and thigh plates, the same on both legs, as in Image 1
    - silver-and-gold armour, a blue cape with a yellow star, a winged circlet
    - the sword in the near hand pointing forward-down
    - the round blue shield on the far arm in front
  - **Luna:**
    - knee-high purple boots on both legs, no stockings
    - the purple-and-pink dress with white frills of Image 1
    - the wand up in front in the near hand, the star at the top right as in Image 1, steady in every frame
- The far leg is the same costume, only slightly darker and partly behind the near leg.
- The accepted style line, 512-px cell, chroma `#00FF00`, one figure, no effects.

**3. Order and retries.**
- Generate frame 1 first. Accept it only when it passes the costume check (step 5).
- Then generate frames 2–8.
- Up to 3 generations per frame. Keep the one that passes the most checks.

**4. Normalise each generation.**
- `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00 --ground-all`
- One factor per generation, matched to the anchor head with `head_scale.py`, 0.96–1.04.
- At this stage a head within ±4 px of the bob curve is enough.

**5. Checks for each frame, all at 4×.**
- **Costume board** `costume.png`: idle frame 0, in-game walk frame 0 and the 8 new frames side by side. For every frame, say whether these match the idle:
  - boots
  - legs
  - dress or armour
  - the prop
  
  Frey: brown boots, no orange, red, white or navy legs. Luna: knee-high purple boots, no stripes, the wand in front with the star at the top right.
- **Legs** (`feet.png`, as in ART-55):
  - the pose matches the mannequin panel
  - the near leg is in front of the far leg
  - frames 1 and 5 lead with different legs
  - frames 3 and 7 lift the swinging leg
- **Props:**
  - Frey: the sword forward-down within about 15°, the shield on the far arm in front.
  - Luna: the wand up in front, within about 15°.
- **Cleanup:**
  - border clear, 4 px margin, spill 0
  - detail ≥ 90 for Frey, ≥ 85 for Luna

**6. Bob, set afterwards.**
- Run `tools/sprite_pipeline/walk_bob.py` (README section "Walk head bob") on the 8-frame strip, with `--face` around frame 1's eyes and face.
- Every shift must be within ±3 px. Regenerate a frame that would need more.
- Look at its `bob.png` at 4× for any mark in the legs. Do not move frames up or down any other way.

**7. GIF at 13.3 fps.** Say plainly whether it reads as two alternating steps, with no jitter and no costume flicker.

## Output
- `art/bakeoff/frey/frey-walk-v5.png` and `art/bakeoff/luna/luna-walk-v4.png`, after `walk_bob.py`: 1024×128, 8 cells.
- Each has a `.json` `{"note": "<Korean>", "fps": 13.3, "frames": 8}`.
- Deliver only a character that passes. Otherwise report the best attempt and what failed.
- Raw generations go to `art/raw/walk-57/<id>/` (git-ignored).
- `reports/codex-art-57/<id>/` holds:
  - `make_walk_reference.py`, `walk_reference_<id>.png`
  - `costume.png`, `feet.png`, `bob.png`, `bob.json`, `walk.gif`, `compare.png`, `metrics.json`
  - `prompts.txt`, `README.md` (Korean)
  - `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`

## Writable
- **Frey unit:** `art/bakeoff/frey/frey-walk-v5.*`, `art/raw/walk-57/frey/**`, `reports/codex-art-57/frey/**`
- **Luna unit:** `art/bakeoff/luna/luna-walk-v4.*`, `art/raw/walk-57/luna/**`, `reports/codex-art-57/luna/**`

Hard stop: 120 minutes.
