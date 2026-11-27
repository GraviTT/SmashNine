# CODEX-ART-100 fix (unit `art-a`) · Jupi: victory with planted feet, defeat resting on the floor

- Follows `design/tasks/CODEX-ART-100.md` and your own report `reports/codex-art-100a/README.md`. The lead accepted your idle (frame 1 is the anchor, pixel-identical), attack and shield (merged `6404f610`). Two rows are left:
  1. **Victory:** the source poses move her feet. They slide 7.5 px (first try) and 9 px (second try), even on one shared horizontal anchor.
  2. **Defeat:** your first try reads all six steps, but in frames 5 and 6 her body hangs 5 and 4 px above the floor line. Your second try's staff floats in the air.
- Unit: `art-a`, branch `codex/jupi-100a-fix`, clone `SmashNine-units/art-a/SmashNine`. Your raw generations from ART-100 are in `art/raw/jupi-100a/`. **Candidates only:** nothing under `smash-nine-prototype/` changes.

## 1. Victory: redraw with her feet planted
- Same motion: a short win, the staff twirled, ending planted beside her with a bright smile.
- Draw it so her boots stay on one spot in every frame. The twirl is in her arms and the staff; her hips turn a little at most.
- If one image of six poses keeps moving the feet, use the walk's fixed-reference method:
  - frame 1 first
  - then each other frame with the anchor as Image 1, frame 1 as Image 3, and the words "feet exactly where they are in Image 3"
- Normalize as before (`--cell 192`, feet y=152, one factor matched to the anchor head, one shared horizontal anchor).
- Acceptance: the planted boots move at most 3 px between neighbouring frames (measure the boots, not the staff); head scale, detail, border, margin and spill as before.
- Up to 3 generations in all.

## 2. Defeat: your first try, with the lying frames on the floor
- Do not regenerate unless the steps below fail.
- Re-normalize your first try (same factor 0.310, `--cell 192`):
  - frames 1–3, where she is standing: feet on y=152
  - frame 4 (falling): keep its height from the source
  - frames 5 and 6 (lying): **move each down so the lowest pixel of her body, staff left out, rests on y=152**
- The staff in frames 5 and 6 lies on the floor beside her, or stays in her hand on the floor. If it hangs in the air after that move, say so.
- A vertical move of a whole frame is allowed here because ART-69 asks that frames 5 and 6 rest on the line. Do not scale, stretch or repaint any frame.
- Acceptance:
  - body contact with y=152 in frames 5 and 6 within 1 px
  - the six steps still read in order
  - border, margin and spill as before
  - the 4× board beside the anchor

## Output
- `art/bakeoff/jupi/jupi-victory-v1.png` + `.json` (`{"note": "<Korean>", "fps": 8, "frames": 6, "loop": false}`) and `art/bakeoff/jupi/jupi-defeat-v1.png` + `.json` (`"fps": 10`).
- `reports/codex-art-100a-fix/`: the 4× boards, `feet.json` (victory), `floor.json` (defeat frames 5 and 6), `metrics.json`, `prompts.txt`, `README.md` (Korean, UTF-8), `commit.ps1` (the paths as a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`; do not run it).

## Writable
`art/bakeoff/jupi/jupi-victory-v1.*`, `art/bakeoff/jupi/jupi-defeat-v1.*`, `art/raw/jupi-100a/**`, `reports/codex-art-100a-fix/**`. Hard stop: 60 minutes.
