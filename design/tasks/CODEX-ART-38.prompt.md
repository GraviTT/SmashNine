You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter). Your card: `design/tasks/CODEX-ART-38.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-37.md` and `reports/codex-art-37/README.md` (phase 1: the settings, the prompts in `reports/codex-art-37/*/prompt.txt` and the anchor factor)
- `tools/sprite_pipeline/README.md`
- `smash-nine-prototype/characters/frey/Frey.md`

Rules:
- Work only in this clone (branch `codex/frey-38`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other Codex unit is running; you have the machine.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate images with your built-in image tool; copy the ones you use into `art/raw/frey-38/<row>/`. Phase 1 raws are in `art/raw/frey-37/`.
- Order:
  1. Task 0 (green pockets).
  2. The rows in the card's order: one motion per generation, a second generation only if the first fails.
- Before you call a row done, look at every frame yourself at 4× next to the current game frame and the anchor. Count spill over all visible pixels. Separate what you measured from what you judge by eye.
- Frey only. Hard stop at 130 minutes: deliver the finished rows and list the rest.
- `.git` may not be writable: write `reports/codex-art-38/commit.ps1` (stage only your files; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, covering:
  - the Task 0 result (pocket counts before → after)
  - each row's file and result
  - what is still wrong
  - the rows you did not reach
