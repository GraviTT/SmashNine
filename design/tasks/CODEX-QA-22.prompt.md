You are a Codex analyst unit for SmashNine (Godot 4.7 2D fighter): retest the QA-21 findings with the same inputs, and measure what the sound wiring would play in real matches (no sound files exist yet; count the requests). Your card: `design/tasks/CODEX-QA-22.md`. Read it first, then `reports/codex-qa-21/README.md`, `design/AUDIO.md`, `reports/codex-sys-05/README.md`.

Rules:
- Work only in this clone (branch `codex/qa-22`). Write only the card's writable paths. Report only: no product code changes.
- Running at the same time in other clones: image units. You are the only unit running Godot; run one Godot process at a time.
- Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first.
- Separate what you measured from what you guess.
- Hard stop: 150 minutes. In the card's order; list what you could not do.
- `.git` may not be writable. Write `reports/codex-qa-22/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add no `__pycache__` and no log over 1 MB
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: the retest table, the top sound findings (busiest ids, never-fired ids, filtered counts), the regression result.
