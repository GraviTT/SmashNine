# CODEX-ART-100b fix (unit `art-b`) · Jupi: the hurt strip with planted feet

- Follows `design/tasks/CODEX-ART-100.md` and your own report `reports/codex-art-100b/README.md`. The lead accepted your walk, jump, fall and land (merged `2d2ca54c`). The walk's frame 8 arm swing and the land's frame 2 legs are accepted as they are.
- **Hurt** was held: her feet move 7 px between frames (the limit is 3). Her feet stay on the line while she is hit, so they must not slide.
- Unit: `art-b`, branch `codex/jupi-100b-fix`, clone `SmashNine-units/art-b/SmashNine`. Your raw generations from ART-100 are in `art/raw/jupi-100b/`. Unit `art-a` fixes the victory and defeat in another clone at the same time. **Candidates only:** nothing under `smash-nine-prototype/` changes.

## The hurt strip
- The motion is unchanged (ART-72): 3 frames at 12 fps, holding the last; hit snap, recoil, recovering; feet on the line.
- First, re-normalize your accepted source with **one shared horizontal anchor for the row** (`reports/codex-art-96b/normalize_idle.py`), the same factor, `--cell 128`, `--ground-all`. If the planted boots then move at most 3 px, that is the fix.
- If they still slide, the source poses move her feet. Redraw with the walk's fixed-reference method:
  - frame 1 first
  - then frames 2 and 3, each with the anchor as Image 1, frame 1 as Image 3, and the words "feet exactly where they are in Image 3; only the upper body recoils"
  - up to 3 generations in all
- Acceptance:
  - the boots move at most 3 px between frames (measure the boots, not the staff)
  - head scale matched to the anchor (0.96–1.04 or 4× crops)
  - detail ≥ 90 % of the anchor's, border clear, 4-px margin, spill 0
  - the 4× board beside the anchor

## Output
- `art/bakeoff/jupi/jupi-hurt-v1.png` + `.json` (`{"note": "<Korean>", "fps": 12, "frames": 3, "loop": false}`).
- `reports/codex-art-100b-fix/`: the 4× board, `feet.json`, `metrics.json`, `prompts.txt`, `README.md` (Korean, UTF-8), `commit.ps1` (the paths as a literal string array, only your files and this card, no `git add -f`, nothing under `art/raw/`; do not run it).

## Writable
`art/bakeoff/jupi/jupi-hurt-v1.*`, `art/raw/jupi-100b/**`, `reports/codex-art-100b-fix/**`. Hard stop: 45 minutes.
