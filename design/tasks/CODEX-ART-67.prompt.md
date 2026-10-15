You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): redraw the effects drawn around the characters (auras, orbits, marks, shields, seals) to the level of the new sprites. Your card: `design/tasks/CODEX-ART-67.md`. Read it first. Then read `design/tasks/CODEX-ART-66.md` and `reports/codex-art-66/README.md` (the method you repeat, with its `build_fx66.py`), `design/SKILLS.md`, `smash-nine-prototype/assets/art/effects/README.md` and `effects/passive/README.md`, and the code that draws each file.

Rules:
- Work only in this clone (branch `codex/art-67`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other unit runs.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/fx-67/`.
- Keep every file's contract exactly. Look at every result at 1x and 4x on the body where the game shows it; it must not hide the body.
- Hard stop: 120 minutes. Deliver finished characters in the card's order and list the rest.
- `.git` may not be writable: write `reports/codex-art-67/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: per character, the files delivered, the checks, what is still wrong.
