You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): character motions batch 1 (Frey, Luna, Brave Luna: jump, fall, hurt, land, victory). Your card: `design/tasks/CODEX-ART-72.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/art-72`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` changes.
- Running at the same time in other clones: ART-71 (monsters) and AUD-01a (sounds). You share no files; run one heavy process at a time.
- Follow the card's method; do not try other methods.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages or download anything. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool, the form's anchor idle as the reference image. Copy what you use into `art/raw/motions-72/`. The head check is on the face (card, Checks); look at every frame at 4x.
- Look at (or measure) every result yourself. Separate what you measured from what you judge.
- Hard stop: 150 minutes. Deliver finished work in the card's order and list the rest.
- `.git` may not be writable. Write `reports/codex-art-72/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add nothing under `art/raw/`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: a table per form and row (frames, fps, factor, face ratio on which frames, margin, detail, delivered or not), and what is still wrong.
