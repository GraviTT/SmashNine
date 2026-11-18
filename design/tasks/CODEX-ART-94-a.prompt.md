You are Codex builder unit A for SmashNine (Godot 4.7 2D fighter): Xion phase 1, **her look, direction A "the long coat"**. Your card: `design/tasks/CODEX-ART-94.md`. Read it first. Then read:
- `reports/xion-kit-2026-11-18/art-brief.md`, `smash-nine-prototype/characters/xion/Xion.md`, the Xion section of `design/SKILLS.md`
- `design/tasks/CODEX-ART-53.md`, `CODEX-ART-62.md` and their reports (main art), `design/tasks/CODEX-ART-60.md` and `reports/codex-art-60/` (an idle anchor)
- `design/DECISIONS.md` rows D22, D25 and D32–D37, `tools/sprite_pipeline/README.md`

Rules:
- Work only in this clone (branch `codex/xion-94a`). Write only the card's "Writable" paths for letter a. Nothing under `smash-nine-prototype/` changes.
- Unit B makes the other direction at the same time in another clone. You are blind to it: never open `art/bakeoff/xion/b/` or `reports/codex-art-94b/`.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/xion-94a/`.
- Look at every result yourself (the illustration at full size, the sprite at 4×). Separate what you measured from what you judge by eye.
- Save every text file as UTF-8.
- Hard stop: 80 minutes. Deliver what is finished and list the rest.
- `.git` may not be writable: write `reports/codex-art-94a/commit.ps1` as the card says and do not run it.
- Final answer in Korean, short: the design in three lines, then a table (file, size, measured checks, delivered or not), and what is still wrong.
