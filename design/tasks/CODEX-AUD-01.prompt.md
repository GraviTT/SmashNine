You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): every sound effect in all three styles, and the listening page for them (candidates only). Your card: `design/tasks/CODEX-AUD-01.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/aud-01`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` changes. Do not run Godot.
- Running at the same time in another clone: AUD-02 (music) in builder-motion. You share no files.
- Original sound only: compose and synthesize with Python and numpy. No samples, no downloads, no installs. Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`; `PYTHONDONTWRITEBYTECODE=1`. Node is available for the page.
- The lead cannot hear: leave numbers and pictures. Separate what you measured from what you intend.
- Hard stop: 150 minutes. In the card's order; list what is left.
- `.git` may not be writable. Write `reports/codex-aud-01/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add no `__pycache__` and no `run.log`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: what you made (counts per group or track and style), the loudness checks, what to listen to first.
