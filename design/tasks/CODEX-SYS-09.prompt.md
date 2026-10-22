You are a Codex builder unit for SmashNine (Godot 4.7 2D fighter): story dialogue expressions and shadow faces, wired with a fallback so adopting a picked candidate is a file copy. Your card: `design/tasks/CODEX-SYS-09.md`. Read it first, then `scripts/ui/StoryDialogue.gd`, `scripts/story/StoryCatalog.gd`, `design/STORY.md` and `reports/codex-art-73/README.md`.

Rules:
- Work only in this clone (branch `codex/sys-09`). Write only the card's writable paths. In the story files change only the faces (StoryDialogue) and add face tags to the line lists (StoryCatalog); the story text, flow and saves do not change.
- Do not copy any candidate from `art/bakeoff/` into `assets/`. Tests make their own textures in code.
- Running at the same time in another clone: an image unit. You are the only unit running Godot; run one Godot process at a time.
- Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Run the full suite `smash-nine-prototype/tests/run_all.ps1` once at the end.
- Separate what you measured from what you assume.
- Hard stop: 120 minutes.
- `.git` may not be writable. Write `reports/codex-sys-09/commit.ps1` and do not run it (only your files, no `git add -f`, no `__pycache__`, no log over 1 MB; end the message with `Co-Authored-By: Codex <noreply@openai.com>`).
- Final answer in Korean, short: what changed, how many lines got which face, the tests, the full suite result.
