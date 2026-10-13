You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter). Your card: `design/tasks/CODEX-ART-39.md`. Read it first. Then read:
- `reports/codex-art-38/README.md`
- the ART-38 prompts in `reports/codex-art-38/*/prompt.txt`
- `tools/sprite_pipeline/README.md`
- `tools/sprite_pipeline/head_scale.py` (the lead's measuring tool; run `--selftest` once)

Rules:
- Work only in this clone (branch `codex/frey-39`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other Codex unit is running; you have the machine.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- The raw generations from ART-37 and ART-38 are in `art/raw/`. If you regenerate, use your built-in image tool and copy what you use into `art/raw/frey-39/<row>/`.
- Head size is the point of this round. Measure every row with `head_scale.py`, then look at it at 4× next to the anchor. Separate what you measured from what you judge by eye.
- Frey only. Hard stop at 100 minutes: finish the row in progress and list the rest.
- `.git` may not be writable: write `reports/codex-art-39/commit.ps1` (stage only your files; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, covering:
  - for each row: head scale before → after, the factor, the lift scale, and whether it was regenerated
  - what is still wrong
