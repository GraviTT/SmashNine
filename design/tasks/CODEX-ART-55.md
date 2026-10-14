# CODEX-ART-55 · The 8-frame walk again, pose-guided by a colour-coded mannequin sheet (Frey, Luna)

- Request: 사용자 2026-10-14 "모든 캐릭터들의 현재 걸음걸이가 어색함이 느껴진다. 양 발이 번갈아 가며 앞으로 내딛는 모습이 아니다. 먼저 Frey와 Luna의 걸음걸이를 8프레임으로 변경해볼것." **Candidates only.**
- Unit: branch `codex/walk-55`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.
- **What failed in ART-54** (`reports/codex-art-54/README.md`): asked in words, the generator put the **near leg in front in both contact frames** (1 and 5). That reads as a limp, the same complaint the user has today. Words do not control leg identity, so this round controls it with a picture.

## Step 1 · Build the pose reference (code, no generation)
Write `reports/codex-art-55/make_walk_reference.py` (Pillow) to draw `walk_reference_<frey|luna>.png`: an 8-panel mannequin walk cycle, side view facing right, 4×2 panels of 512 px. Proportions:
- Frey: 3 heads tall (D25)
- Luna: 2.2 heads, chibi

Rules for the mannequin:
- **near (viewer-side) leg and arm: solid orange**
- **far leg and arm: solid blue**, drawn behind the torso and the near limbs
- head and torso: grey
- thick limbs with a clear knee and foot
- a ground line in each panel
- no text inside the panels; put labels under them

The 8 poses, standard walk keys:

| Panel | Pose | Legs | Body |
| --- | --- | --- | --- |
| 1 | contact | orange leg forward, heel down; blue leg behind on its toe | middle height |
| 2 | down | weight on orange, knee bent; blue foot lifting behind | lowest |
| 3 | passing | blue leg swings forward under the hips, knee bent, foot clear; orange leg straight | — |
| 4 | up | orange pushes off on its toe behind; blue reaches forward | highest |
| 5 | contact | **blue leg forward**, heel down; **orange leg behind** on its toe | middle height |
| 6 | down | weight on blue; orange foot lifting behind | lowest |
| 7 | passing | orange leg swings forward under the hips; blue leg straight | — |
| 8 | up | blue pushes off behind; orange reaches forward | highest |

Arms swing opposite to the legs: the orange arm is back when the orange leg is forward.

Check the reference yourself before using it: panels 1 and 5 must show different colours in front.

## Step 2 · Generate, posed by the reference
- Image 1 = the anchor (`art/bakeoff/frey/frey-idle-v2.png` / `art/bakeoff/luna/luna-idle-v3.png`, in the game) for look, size and detail.
- Image 2 = the character's `walk_reference_*.png`.
- The prompt says, in words:
  - each panel copies the mannequin's pose exactly
  - the orange limbs are her near leg and arm, the blue ones her far leg and arm
  - she wears her normal costume colours: no orange or blue limbs
  - the far leg and arm are slightly darker and partly hidden behind the body
  - frames 1–4 lead with the near leg, frames 5–8 with the far leg
- Equipment:
  - **Frey:** the sword in the near hand swings slightly; the shield on the far arm stays steady in front, so her far-arm swing is small.
  - **Luna:** the wand in the near hand swings less; the free far arm swings.
- Hair, cape, ribbon and skirt lag one frame. No effects, no dust, 512-px cells, chroma green `#00FF00`, the accepted detail style line (`reports/codex-art-38/walk/prompt.txt`, `reports/codex-art-43/walk/prompt.txt`).
- **If the one-image generation still fails the leg check, generate the frames one by one**: one image per frame, Image 2 = that single mannequin panel, the same anchor. Normalise each with one factor matched to the anchor head; the drawings differ in size per generation. At most 8 single-frame generations per character.

## Step 3 · Normalise and check
- `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00 --ground-all`.
- Head matched with `head_scale.py --anchor <anchor>:0`, 0.96–1.04.
- **Leg check, which decides acceptance:**
  - Make `reports/codex-art-55/<stem>/feet.png`: the lower 48 px of the 8 frames at 4×, each next to its mannequin panel.
  - In each frame, mark which leg (near/far) is forward.
  - Frames 1 and 5 must lead with different legs; 3 and 7 must show the swinging leg lifted.
  - Also play the 8 frames as a GIF at 13.3 fps (`walk.gif`) and say whether it reads as two alternating steps.
- Other checks: border clear, 4 px margin, spill 0, detail (Frey ≥ 90, Luna ≥ 85), one face, equipment intact.

## Output
- `art/bakeoff/frey/frey-walk-v4.png` and `art/bakeoff/luna/luna-walk-v3.png`: 1024×128, 8 cells.
- Each has a `.json` `{"note": "<Korean>", "fps": 13.3, "frames": 8}`.
- Deliver a character only if it passes the leg check.
- Raw generations go to `art/raw/walk-55/` (git-ignored).
- `reports/codex-art-55/`: the reference script and sheets, and per character `prompt.txt`, `compare.png`, `feet.png`, `walk.gif`, `metrics.json`. Plus `README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/frey/frey-walk-v4.*`, `art/bakeoff/luna/luna-walk-v3.*`, `art/raw/walk-55/**`, `reports/codex-art-55/**`. Hard stop 80 minutes.
