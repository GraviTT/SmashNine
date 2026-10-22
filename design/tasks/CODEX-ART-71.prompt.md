You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): the monsters at the new art level, batch 1 of 3 (six monsters). Your card: `design/tasks/CODEX-ART-71.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/art-71`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` changes.
- Running at the same time in other clones: ART-72 (character motions) and AUD-01a (sounds). You share no files; run one heavy process at a time.
- Follow the card's method; do not try other methods.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool. Copy what you use into `art/raw/monsters-71/`. For each monster pass the current sheet as the identity reference and, after the anchor, the accepted anchor idle as Image 1.
- Look at (or measure) every result yourself. Separate what you measured from what you judge.
- Hard stop: 150 minutes. Deliver finished work in the card's order and list the rest.
- `.git` may not be writable. Write `reports/codex-art-71/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add nothing under `art/raw/`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: a table per monster and row (frames, fps, factor, margin, detail, delivered or not), the viewer change, and what is still wrong.
