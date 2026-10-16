You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): a new defeat motion (row `defeat`, 6 frames) for all eight fighter forms. Your card: `design/tasks/CODEX-ART-69.md`. Read it first. Then read:
- `design/tasks/CODEX-ART-61.md` and `reports/codex-art-61b/README.md` (how the move rows were drawn)
- `tools/sprite_pipeline/README.md`
- `design/DECISIONS.md` rows D32–D37

Rules:
- Work only in this clone (branch `codex/art-69`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` changes.
- Running at the same time: ART-68 (Rio heads) in another clone. You share no files.
- Follow the card's method; do not try other methods.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Generate with your built-in image tool, the form's anchor idle as the reference image. Copy what you use into `art/raw/defeat-69/`.
- The head check is on the face (card, Checks). Look at every frame yourself at 4×. Separate what you measured from what you judge by eye.
- Hard stop: 150 minutes. Deliver forms in the card's order and list the rest.
- `.git` may not be writable. Write `reports/codex-art-69/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add nothing under `art/raw/`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: a table per form (factor, face ratio on frames 1–3, detail, margin, feet, delivered or not), and what is still wrong.
