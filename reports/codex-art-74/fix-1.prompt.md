You are the same Codex builder unit, continuing CODEX-ART-74 (monsters batch 2) in this clone, branch `codex/art-74`. Your work so far is uncommitted here; keep it. Read `design/tasks/CODEX-ART-74.md` and your `reports/codex-art-74/README.md` again. Your raws are in `art/raw/monsters-74/`.

## The lead's review
Slinger, gear beetle and cog drone keep their identity and read well: keep them, except point 2 for the drone. Two things must change.

### 1. Colours: the vine hound and the seed sprite drifted
- `vanaheim_vine_hound`: the current sheet is a mossy green hound with a dark brown body and a green eye glow. The candidate turned yellow-gold leaves on an orange-brown body. Bring it back to the current sheet's greens and browns.
- `vanaheim_seed_sprite`: the current sheet is green leaves with a green glowing eye and a white flower. The candidate turned yellow-olive with a teal eye. Bring back the greens and the green eye glow; keep the white flower.
- Method: a palette remap from the current sheet (Python and Pillow; the lead authorizes it), the same mapping for every row of that monster, so the rows still match one another. If a remap cannot reach the colours cleanly (muddy shading, lost detail), regenerate those rows with the current sheet as the colour reference (up to 2 tries per row).
- Show it: a board per monster with the current sheet, the old candidate and the fixed candidate side by side at 1x and 4x.

### 2. The same size in every row
The rune golem's `walk` frames are about 15% smaller than its `idle` (compare the rune circle and the head), so the golem would shrink when it starts walking. The cog drone's `hurt` looks smaller than its `idle` too.
- For **every** monster of this batch, measure one stable part per row against `idle` (for example the golem's rune circle and head, the drone's body ring, the beetle's shell, the slinger's head and hood, the hound's head, the sprite's eye and body).
- Every row within ±5% of `idle`. Fix a row by changing that row's single factor and rebuilding it from its raw; do not scale single frames.
- Report a table: monster × row, the part measured, the size, the ratio to `idle`, before and after.

Also, if it is cheap: the seed sprite's attack reach was 6 px (target 8 px).

## Output
- Replace the affected `art/bakeoff/monsters/<id>-<row>-v1.png` + `.json` (the factor in the json updated) and the assembled `<id>_sheet-v1.png`.
- Boards in `reports/codex-art-74/` updated; README (Korean): what changed in this pass, the size table, the colour boards.
- Write `commit.ps1` again (only your files, include this prompt file, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`). Do not run it.

## Rules
- Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `tools/` changes. Do not run Godot.
- Running at the same time in other clones: ART-75 and ART-76 (images) and SYS-07 (Godot).
- Hard stop: 90 minutes.
- Final answer in Korean, short: the colour fix (how, per monster), the size table (rows changed), and what is still weak.
