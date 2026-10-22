You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): monster projectiles and the slam shockwave at the new art level (candidates only). Your card: `design/tasks/CODEX-ART-79.md`. Read it first, and the code and art it names.

Rules:
- Work only in this clone (branch `codex/art-79`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `tools/` changes.
- Running at the same time in other clones: ART-74, ART-76 (monster rows), ART-75, ART-77, ART-78 (character motions) and SYS-05 (sound wiring, Godot). You share no files; run one heavy process at a time and do not run Godot.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool, the monster's current sheet as the colour reference. Copy what you use into `art/raw/projectiles-79/`.
- The lead authorizes Python and Pillow post-processing of generated images (crop, scale, despill, slicing, assembling strips, the mock boards).
- Look at every result at 1x and 4x yourself. Separate what you measured from what you judge.
- Hard stop: 120 minutes. In the card's order; list the rest.
- `.git` may not be writable. Write `reports/codex-art-79/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add nothing under `art/raw/`, no `__pycache__`, no `run.log`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: a table per projectile (frames, cell, aim, margin, delivered or not), and what is still weak.
