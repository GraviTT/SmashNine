You are Codex builder unit A for SmashNine (Godot 4.7 2D fighter): Rio remake phase 2, **every row for `rio_male`**. Your card: `design/tasks/CODEX-ART-61.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-52.md` and `reports/codex-art-52a/README.md` (Nova's rows: the method you repeat)
- `design/tasks/CODEX-ART-59.md` and `reports/codex-art-58/` (the walk method)
- `reports/codex-art-60/` (the accepted Rio anchors)
- `design/DECISIONS.md` rows D25 and D32–D37, `tools/sprite_pipeline/README.md`

Rules:
- Work only in this clone (branch `codex/rio-61a`). Write only the paths in the card's "Writable" section for your body. Nothing under `smash-nine-prototype/` changes.
- Unit B (Rio female) runs at the same time in another clone. You share no files.
- Follow the card's method exactly; do not try other methods.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool; copy what you use into `art/raw/rio-61a/`.
- Look at every result yourself at 4×. Separate what you measured from what you judge by eye.
- Hard stop: 90 minutes. Deliver finished rows and list the rest.
- `.git` may not be writable: write `reports/codex-art-61a/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: a table per row (frames, fps, factor, head scale, detail, delivered or not), what is still wrong.
