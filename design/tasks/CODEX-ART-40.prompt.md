You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter). Your card: `design/tasks/CODEX-ART-40.md`. Read it first. Then read:
- `design/DECISIONS.md` row D34
- `reports/codex-art-39/README.md` and `reports/codex-art-38/README.md`
- `tools/sprite_pipeline/README.md`
- `tools/sprite_pipeline/head_scale.py`

Rules:
- Work only in this clone (branch `codex/frey-40`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other Codex unit is running; you have the machine.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- The raw generations from ART-37 to ART-39 are in `art/raw/`. Regenerate only if a frame does not fit in 192.
- Measure every row with `head_scale.py` and look at it at 4× next to the anchor. Separate what you measured from what you judge by eye.
- Frey only. Hard stop at 75 minutes.
- `.git` may not be writable: write `reports/codex-art-40/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: per row the head scale, factor, lift scale and source raw; what is still wrong.
