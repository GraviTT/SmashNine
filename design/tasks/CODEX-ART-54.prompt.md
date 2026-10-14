You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): the 8-frame walk for Frey and Luna. Your card: `design/tasks/CODEX-ART-54.md`. Read it first. Then read:
- `reports/frey-rework-2026-10-14.md` (the accepted method)
- `design/DECISIONS.md` rows D25 and D32–D37
- `tools/sprite_pipeline/README.md`
- the files the card names

Rules:
- Work only in this clone (branch `codex/walk-54`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other unit is running.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate with your built-in image tool; copy what you use into `art/raw/walk-54/`.
- Look at every result yourself at the card's zoom. Separate what you measured from what you judge by eye.
- Hard stop as the card says.
- `.git` may not be writable: write `reports/codex-art-54/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: what you made (files), the measurements, what is still wrong.
