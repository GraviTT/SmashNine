You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): the motion viewer gets a pick button on every candidate, a picks panel, and sections for monster projectiles and dialogue portraits. Your card: `design/tasks/CODEX-TOOL-03.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/tool-03`). Write only the card's writable paths. Nothing under `smash-nine-prototype/` or `art/` changes.
- Running at the same time in other clones: five image units (they add candidate files with the same naming) and SYS-05 (sound wiring, Godot). Do not run Godot.
- Node is available; do not install packages or download anything.
- The page must keep working for everything it does today (speeds, clips, candidates). Test that too.
- Separate what you measured from what you assume.
- Hard stop: 120 minutes.
- `.git` may not be writable. Write `reports/codex-tool-03/commit.ps1` and do not run it. It must:
  - stage only your files (nothing in `tools/motion_viewer/dist/`)
  - not use `git add -f`
  - add no `__pycache__` and no `run.log`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: what the page does now, the checks and their results, the dist size and file count.
