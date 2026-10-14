# CODEX-ART-54 · An 8-frame walk where the feet clearly alternate: Frey and Luna first

- Request: 사용자 2026-10-14 "모든 캐릭터들의 현재 걸음걸이가 어색함이 느껴진다. 양 발이 번갈아 가며 앞으로 내딛는 모습이 아니다. 먼저 Frey와 Luna의 걸음걸이를 8프레임으로 변경해볼것." Method D35, rules D32–D34. **Candidates only**; the user judges in the motion viewer, then the other characters follow.
- Unit: branch `codex/walk-54`, clone `SmashNine-units/builder-frey/SmashNine`. No other unit runs.

## Why today's walks fail
In side view the near and far legs look alike, and the 6 frames do not show a clear contact → passing → contact rhythm. So the eye cannot tell which foot is stepping, and the walk reads as a shuffle in place.

## The walk: 8 frames, loop, 13.3 fps
13.3 fps keeps today's 0.6 s cycle (6 frames at 10 fps). Right-facing side view. Two steps per cycle; the far leg is drawn slightly darker and partly behind the near leg, so the alternation reads at 1×.
1. **Contact (near leg forward):** near heel down far in front, far leg stretched behind on its toe; body at the middle height.
2. **Down:** weight lands on the near leg, its knee bends; the far foot lifts off behind; the body is at its lowest (head 1–2 px lower).
3. **Passing:** the far leg swings forward under the body, knee bent, foot clear of the ground; the near leg stands straight under the hips.
4. **Up:** the near leg pushes off on its toe behind; the far leg reaches forward; the body is at its highest (head 1–2 px higher).
5. **Contact (far leg forward):** far heel down in front, near leg stretched behind on its toe. The mirror of 1.
6. **Down:** weight on the far leg; the near foot lifts behind; lowest.
7. **Passing:** the near leg swings forward under the body; the far leg stands straight.
8. **Up:** the far leg pushes off behind; the near leg reaches forward; highest.

Arms swing opposite to the legs:
- **Frey:** the sword arm swings a little; the shield arm stays steady in front.
- **Luna:** the free arm swings and the wand arm swings less.

Hair, cape, ribbon and skirt lag one frame behind the body bob.

## How
- One generation per character: 8 cells, 4×2, 512-px cells (2048×1024).
  - Image 1 = the anchor (`art/bakeoff/frey/frey-idle-v2.png`, `art/bakeoff/luna/luna-idle-v3.png`, both now in the game) for size, look and detail.
  - Image 2 = the current game walk row ×4 nearest, for the costume in motion only; do not copy its legs.
- Prompt structure and detail style line as in the accepted Frey/Luna prompts (`reports/codex-art-38/walk/prompt.txt`, `reports/codex-art-43/walk/prompt.txt`). One pose line per frame as above. No effects, no dust.
- A second generation only if the first fails the leg check below.
- `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00 --ground-all`. One factor matched to the anchor head (`head_scale.py --anchor <anchor>:0`, median 0.96–1.04).
- **Leg check:**
  - Make `reports/codex-art-54/<stem>/feet.png`: the lower 48 px of all 8 frames at 4× in a row, with the near leg's foot marked in each.
  - Frames 1 and 5 must show different legs in front. Frames 3 and 7 must show the passing leg clearly lifted.
  - Say for each frame which leg is forward.
- Other checks: border clear, 4 px margin, spill 0, detail at the character's level (Frey ≥ 90, Luna ≥ 85), one face, sword/shield/wand intact.

## Output
- `art/bakeoff/frey/frey-walk-v3.png` and `art/bakeoff/luna/luna-walk-v2.png`: 1024×128, 8 cells.
- Each has a `.json` `{"note": "<Korean>", "fps": 13.3, "frames": 8}`.
- Raw generations go to `art/raw/walk-54/` (git-ignored).
- `reports/codex-art-54/<frey|luna>/`: `prompt.txt`, `compare.png` (4×, current walk | new walk), `feet.png`, `metrics.json`.
- `reports/codex-art-54/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/frey/frey-walk-v3.*`, `art/bakeoff/luna/luna-walk-v2.*`, `art/raw/walk-54/**`, `reports/codex-art-54/**`. Hard stop 45 minutes.
