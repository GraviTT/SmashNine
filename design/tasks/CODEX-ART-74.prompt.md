You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): the monsters at the new art level, batch 2 of 3 (six monsters). Your card: `design/tasks/CODEX-ART-74.md`. Read it first, then `reports/codex-art-71/README.md` and everything the card lists.

Rules:
- Work only in this clone (branch `codex/art-74`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `tools/` changes.
- Running at the same time in other clones: ART-76 (monsters batch 3), ART-75 (character motions) and QA-21 (Godot bug hunt). You share no files; run one heavy process at a time and do not run Godot.
- Follow the card's method (the ART-71 method); do not try other methods. Reuse the ART-71 scripts by copying them into `reports/codex-art-74/` and adapting the copies.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool. Copy what you use into `art/raw/monsters-74/`. For each monster pass the current sheet as the identity reference and, after the anchor, the accepted anchor idle as Image 1.
- Look at (or measure) every result yourself. Separate what you measured from what you judge.
- Hard stop: 150 minutes. Deliver finished work in the card's order and list the rest.
- `.git` may not be writable. Write `reports/codex-art-74/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add nothing under `art/raw/`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: a table per monster and row (frames, fps, factor, margin, detail, feet, delivered or not), the lesson checks, and what is still wrong.
