# CODEX-ART-97 fix (unit `art-a`) · Xion B: victory feet held in place, defeat redrawn with room per pose

- Follows `design/tasks/CODEX-ART-97.md` and your own report `reports/codex-art-97a/README.md`. The lead accepted your **shield**, and your **attack** as the base sheet's fallback row (a weak pump is fine there). Two rows are left:
  1. **Victory:** the feet jump about 13 px sideways between frames 4 and 5. You found the cause: the normalizer sets each frame's horizontal anchor from a torso band that the raised gun and the scarf cross. That is placement, not drawing.
  2. **Defeat:** not delivered. In both generations the six poses did not stay inside six equal cells.
- Unit: `art-a`, branch `codex/xion-97a-fix`, clone `SmashNine-units/art-a/SmashNine`. Unit `art-b` is still drawing the walk and the jump, fall, hurt and land strips in another clone; you share no files.
- **Candidates only:** nothing under `smash-nine-prototype/` changes.

## 1. Victory: one horizontal anchor for all six frames
- Do not regenerate. Re-normalize your accepted victory source with **one shared horizontal anchor for the whole row**, as ART-96b did for the idle (`reports/codex-art-96b/normalize_idle.py`): one fixed source-grid anchor, the same factor (0.230), `--cell 192`, feet on y=152, `--ground-all`. No per-frame offsets.
- If the source poses themselves drift, pick the anchor that keeps the planted feet steadiest and say which.
- Acceptance:
  - planted feet move at most 3 px between neighbouring frames where she does not step (measure the boots, not the gun or the scarf)
  - head scale, detail, border, margin and spill as before
  - the 4× board beside the anchor

## 2. Defeat: room for every pose
- The motion is unchanged (ART-69): hit recoil, stagger back, knees buckle, falling, hitting the ground, lying still. The guns drop beside her or stay in her hands. No effects.
- Generate it so that no pose can touch its neighbour:
  - **two images of three poses each** (frames 1–3 standing to falling, frames 4–6 on the ground), each pose centred in its own third with wide green gaps, or
  - **one image per pose**, with the anchor as Image 1 and your accepted frame 1 as Image 3 (the walk's fixed-reference method)
- Normalize with **one factor for the whole row**, matched to the anchor head (`head_scale.py --anchor art/bakeoff/xion/b/xion-idle-b2.png:0`, median 0.96–1.04). Use `--cell 192` with feet on y=152 while she stands, and one shared horizontal anchor.
- Frames 5 and 6 rest on y=152, with the body on the floor and not above it. Curl the knees if she is longer than the cell, and keep a 4-px margin.
- Costume exactly as the anchor: coat, scarf, hair, gloves, boots and both guns. One face; hands intact.
- Up to 3 generations in all. If it still fails, deliver nothing and report the best attempt.

## Output
- `art/bakeoff/xion/b/xion-victory-b2.png` + `.json` (overwrite your own held candidate), `art/bakeoff/xion/b/xion-defeat-b2.png` + `.json` (`{"note": "<Korean>", "fps": 10, "frames": 6, "loop": false}`).
- `reports/codex-art-97a-fix/`: the 4× boards, `feet.json` (victory before and after), `metrics.json`, `prompts.txt`, `README.md` (Korean, UTF-8), `commit.ps1` (paths in a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`; do not run it).
- Raw generations go to `art/raw/xion-97a/` (git-ignored).

## Writable
`art/bakeoff/xion/b/xion-victory-b2.*`, `art/bakeoff/xion/b/xion-defeat-b2.*`, `art/raw/xion-97a/**`, `reports/codex-art-97a-fix/**`. Hard stop: 75 minutes.
