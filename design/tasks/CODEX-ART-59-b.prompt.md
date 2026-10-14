You are Codex builder unit B for SmashNine (Godot 4.7 2D fighter): 8-frame walks for **Nova male, then Nova female**, by the method that worked for Frey and Luna. Your card: `design/tasks/CODEX-ART-59.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-57.md`, `design/tasks/CODEX-ART-58.md` and their reports `reports/codex-art-57/`, `reports/codex-art-58/` (the method you repeat)
- `tools/sprite_pipeline/README.md` (normalize, head_scale, "Walk head bob", "Walk feet")

Rules:
- Work only in this clone (branch `codex/walk-59b`). Write only unit B's paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- Unit A (Brave Luna and Yuki) runs at the same time in another clone. You share no files.
- Follow the card's method exactly; do not try other methods or start a second round.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/walk-59/<stem>/`.
- Look at every result yourself at 4×. Separate what you measured from what you judge by eye.
- Hard stop: 90 minutes.
- `.git` may not be writable: write `reports/codex-art-59/commit-b.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: per character, delivered or not, the measurements (frames 3/7 standing foot, largest foot move, bob shifts, head scale, detail), what is still wrong.
