You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter). Your card: `design/tasks/CODEX-ART-41.md`. Read it first. Then read:
- `reports/codex-art-40/README.md`
- the earlier descent prompts in `reports/codex-art-38/descent/prompt.txt` and `reports/codex-art-39/descent/prompt.txt` (they produced the "natural landing" the user rejected)
- `tools/sprite_pipeline/README.md`

Rules:
- Work only in this clone (branch `codex/frey-41`) and write only the paths in the card's "Writable" section. Nothing under `smash-nine-prototype/` changes.
- No other Codex unit is running; you have the machine.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages.
- Generate with your built-in image tool; copy what you use into `art/raw/frey-41/`.
- The point of this round is the feel: a dive that slams the sword into the ground. Look at every frame at 4× next to the anchor and the current game row. Measure the head scale. Separate what you measured from what you judge by eye.
- Hard stop at 45 minutes.
- `.git` may not be writable: write `reports/codex-art-41/commit.ps1` (stage only your files, no `git add -f`, nothing under `art/raw/`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean: what each frame shows, the head scale, the factor and lift scale, what is still wrong.
