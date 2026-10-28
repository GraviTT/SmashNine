You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): the last sprite repairs — the root guardian's top margin, the vine hound speckle, the legacy stag attack row, and two head rechecks. Your card: `design/tasks/CODEX-ART-90.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/art-90`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `tools/` changes. Never change a file that is in the checkpoint (`-v1` images, adopted rows); the not-yet-published `-v2`/`-fix1` files named in the card may be updated in place. `qa23/` is a read-only copy: do not commit it.
- Running at the same time in another clone: ART-89 (character motions). Do not touch its rows. Do not run Godot.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Re-slice from raws or sources first; use your built-in image tool only to retry a frame, with the row's other frames as references. Copy what you use into `art/raw/art-90/`. The lead authorizes Python and Pillow post-processing (crop, scale, despill, speckle clean-up, slicing, assembling strips and sheets).
- Look at every changed frame at 1x and 4x yourself. Separate what you measured from what you judge.
- Hard stop: 120 minutes.
- `.git` may not be writable. Write `reports/codex-art-90/commit.ps1` and do not run it. Stage with `git add --pathspec-from-file` (a list file). It must:
  - stage only your files (the card and this prompt included; not `qa23/`)
  - not use `git add -f`
  - add nothing under `art/raw/`, no `__pycache__`, no `run.log`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: per item done / not needed / not done, with the measures.
