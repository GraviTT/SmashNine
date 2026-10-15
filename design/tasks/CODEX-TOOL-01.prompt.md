You are a Codex tool unit for SmashNine (Godot 4.7 2D fighter): real game clips of every basic attack with effects on/off, and a speed preview, in the motion viewer. Your card: `design/tasks/CODEX-TOOL-01.md`. Read it first. Then read `design/SKILLS.md` (the moves), `tools/motion_viewer/README.md`, `tools/motion_viewer/build.mjs`, `tools/motion_viewer/index.html`, `smash-nine-prototype/tests/capture_attacks.gd` (an older windowed capture), `characters/common/PlayerBase.gd` (`_play_sprite_pose`, `basic_attack`).

Rules:
- Work only in this clone (branch `codex/tool-01`) and write only the paths in the card's "Writable" section. No game code changes.
- An effect-art unit runs at the same time in another clone; you share no files.
- Godot console: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`. Run `--headless --import` once before tests. The capture needs a window (not headless); run one capture at a time.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow; WebP works). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Local server for checking the viewer: port 8073 only (never 8060 or 8071). Close it when done.
- Hard stop: 100 minutes.
- `.git` may not be writable: write `reports/codex-tool-01/commit.ps1` (stage only your files, no `git add -f`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: the clips made (count, sizes), the capture command, what the viewer now shows, what is still wrong.
