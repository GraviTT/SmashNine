You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): character motion repairs — the rows outside the face rule and the weak motions, as new candidate versions. Your card: `design/tasks/CODEX-ART-82.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/art-82`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `tools/` changes. Never overwrite an existing file: write the next free version.
- Running at the same time in another clone: ART-81 (audit). You share no files. Do not run Godot.
- Follow the ART-72 method; do not try other methods. Reuse the ART-72/78 scripts by copying them into `reports/codex-art-82/`.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool, the form's anchor idle and the row's own frames as references. Copy what you use into `art/raw/motions-82/`. The lead authorizes Python and Pillow post-processing (crop, scale, despill, slicing, assembling strips, retrying one frame inside a strip). Do not draw or stamp a character's features by code.
- Look at every frame at 4x yourself. Separate what you measured from what you judge.
- Hard stop: 150 minutes. Part 1 first; list what is left.
- `.git` may not be writable. Write `reports/codex-art-82/commit.ps1` and do not run it. It must:
  - stage only your files (the card and this prompt included)
  - not use `git add -f`
  - add nothing under `art/raw/`, no `__pycache__`, no `run.log`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: a table per row (frames redone, face ratios before → after, delivered or not), and what is still weak.
