You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter). Your card: `design/tasks/CODEX-ART-37.md`. Read it first, then `design/tasks/CODEX-ART-36.md` and `reports/codex-art-36a/README.md` (the method you are improving), `tools/sprite_pipeline/README.md`, `characters/frey/Frey.md` (under `smash-nine-prototype/`).

Rules:
- Work only in this clone (branch `codex/frey-37`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other Codex unit is running; you have the machine.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate images with your built-in image tool; copy the ones you use into `art/raw/frey-37/<row>/`.
- Look at every frame yourself at 4× next to the current game frame before you call a row done. Separate what you measured from what you judge by eye.
- Frey only. Do the card's tasks in order; hard stop 50 minutes, then deliver the finished parts.
- `.git` may not be writable: write `commit.ps1` (stage only your files, commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: what you changed, the detail table (before → after), each row's result and file, what is still wrong.
