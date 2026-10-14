You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): the 8-frame walk, redrawing the two passing frames (3 and 7), **Frey only**. Your card: `design/tasks/CODEX-ART-58.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-57.md` and `reports/codex-art-57/frey/README.md` (your last round: keep its method, references and checks)
- `tools/sprite_pipeline/README.md` ("Walk head bob") and `tools/sprite_pipeline/walk_feet.py`

Rules:
- Work only in this clone (branch `codex/walk-58-frey`). Write only the Frey unit's paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- The Luna unit runs at the same time in another clone. You share no files.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/walk-58/frey/`.
- Look at every result yourself at 4×. Separate what you measured from what you judge by eye.
- Hard stop: 60 minutes.
- `.git` may not be writable: write `reports/codex-art-58/frey/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: what you made (files), the measurements, what is still wrong.
