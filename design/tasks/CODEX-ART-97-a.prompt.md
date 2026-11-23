You are Codex builder unit `art-a` for SmashNine (Godot 4.7 2D fighter): Xion B stage 2, **attack, shield, victory and defeat**. Your card: `design/tasks/CODEX-ART-97.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-96.md` and `reports/codex-art-96b/README.md` (the anchor you follow: `art/bakeoff/xion/b/xion-idle-b2.png`)
- `design/tasks/CODEX-ART-61.md` and `reports/codex-art-61b/README.md` (rows from an anchor), `design/tasks/CODEX-ART-59.md`, `CODEX-ART-57.md`, `CODEX-ART-58.md` (the walk), `CODEX-ART-72.md`, `CODEX-ART-69.md` (motion strips, defeat)
- `design/DECISIONS.md` rows D25 and D32–D37, `tools/sprite_pipeline/README.md`

Rules:
- Work only in this clone (branch `codex/xion-97a`). Write only the card's "Writable" paths for `art-a`. Nothing under `smash-nine-prototype/` changes.
- Unit `art-b` makes the walk and the jump, fall, hurt and land strips at the same time in another clone. You share no files.
- Follow the card's method exactly; do not try other methods.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/xion-97a/`.
- Look at every result yourself at 4×. Separate what you measured from what you judge by eye.
- Save every text file as UTF-8.
- Hard stop: 120 minutes. Deliver finished rows in the card's order and list the rest.
- `.git` may not be writable: write `reports/codex-art-97a/commit.ps1` as the card says and do not run it.
- Final answer in Korean, short: a table per row (frames, fps, factor, head scale, detail, delivered or not), then what is still wrong.
