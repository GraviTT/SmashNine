You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter), unit B (Brave Luna rows). Your card: `design/tasks/CODEX-ART-44.md`. Read it first. Then read:
- `reports/frey-rework-2026-10-14.md` and `reports/codex-art-42/README.md` (the anchors)
- the accepted prompt style in `reports/codex-art-42/*/prompt.txt`
- `tools/sprite_pipeline/README.md`
- `smash-nine-prototype/characters/luna/Luna.md`

Rules:
- Work only in this clone (branch `codex/luna-44`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- unit A (CODEX-ART-43, normal-form rows and the transformation) in the builder-frey clone is running at the same time. Do not touch its files. Keep heavy local work light; image generation is remote.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate with your built-in image tool; copy what you use into `art/raw/luna-44/`.
- Before you call a row done, look at every frame at 4× next to the anchor and the current game row, and measure the head scale. Separate what you measured from what you judge by eye.
- Follow the card's order. At the hard stop, deliver the finished rows and list the rest.
- `.git` may not be writable: write `reports/codex-art-44/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: per row the file, frames, head scale, factor and lift; what is still wrong; rows not reached.
