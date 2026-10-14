You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): Rio remake phase 1, the male and female idle anchors. Your card: `design/tasks/CODEX-ART-60.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-51.md` and `reports/codex-art-51/` (Nova's anchors: the method you repeat)
- `design/DECISIONS.md` rows D25 and D32–D37
- `tools/sprite_pipeline/README.md`

Rules:
- Work only in this clone (branch `codex/rio-60`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- Unit A (8-frame walks, ART-59) runs at the same time in another clone. You share no files.
- Follow the card's method exactly; do not try other methods.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/rio-60/`.
- Look at every result yourself at 4×. Separate what you measured from what you judge by eye.
- Hard stop: 40 minutes.
- `.git` may not be writable: write `reports/codex-art-60/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: per body, the factor, head scale, body height, detail, what is still wrong.
