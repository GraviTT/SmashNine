You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): game wiring for new motions that are being drawn right now. Your card: `design/tasks/CODEX-SYS-06.md`. Read it first, and everything it lists.

Rules:
- Work only in this clone (branch `codex/sys-06`). Write only the card's writable paths.
- Other Codex units run in other clones (art and sound); you are the only one running Godot.
- Every new path must leave today's behaviour unchanged when its row or sheet is absent. Prove both with tests (stand-in rows built from existing frames in the test).
- Godot console binary: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`. Run `--headless --path smash-nine-prototype --import` once first. Run the full suite at the end.
- Do not change gameplay numbers, behaviour, timing or hit boxes. Keep the diffs small: other sessions edit these files too.
- Separate what you measured from what you assume.
- `.git` may not be writable. Write `reports/codex-sys-06/commit.ps1` and do not run it. It must:
  - stage only your files
  - not use `git add -f`
  - add no `__pycache__`
  - end the commit message with `Co-Authored-By: Codex <noreply@openai.com>`
- Final answer in Korean, short: what changed per part (fighters, monsters, screens), the new tests and the full-suite result, and anything you could not do.
