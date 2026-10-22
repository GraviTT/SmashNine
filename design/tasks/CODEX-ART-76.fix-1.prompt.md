You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): make every row of the batch-3 monster candidates the same size as its idle. Your card: `design/tasks/CODEX-ART-76.fix-1.md`. Read it first, then `reports/codex-art-76/README.md` and `reports/codex-art-74/README.md` (the method to reuse).

Rules:
- Work only in this clone (branch `codex/art-76-fix-1`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `tools/` changes. Do not run Godot (QA-22 runs it in another clone).
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow); `PYTHONDONTWRITEBYTECODE=1`; no installs, no downloads. The lead authorizes Python and Pillow post-processing (rebuilding rows from raws with a new factor, offsets).
- Separate what you measured from what you judge. Look at every changed row at 4x.
- Hard stop: 90 minutes.
- `.git` may not be writable. Write `reports/codex-art-76/fix-1/commit.ps1` and do not run it (only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`; end the message with `Co-Authored-By: Codex <noreply@openai.com>`).
- Final answer in Korean, short: the rows changed (ratio before → after), point 3, what is still weak.
