You are a Codex tool unit for SmashNine (Godot 4.7 2D fighter): game clips of the effects around the characters (guard, auras, orbits, marks, seals, ultimates), with effects on/off, in the motion viewer. Your card: `design/tasks/CODEX-TOOL-02.md`. Read it first. Then read `design/tasks/CODEX-TOOL-01.md`, `reports/codex-tool-01/README.md`, `smash-nine-prototype/tests/capture_move_clips.gd` (as fixed by the lead), `reports/codex-tool-01/encode_clips.py`, `design/SKILLS.md`, `reports/codex-art-67/README.md`, `tools/motion_viewer/README.md`, `build.mjs`, `index.html`.

Rules:
- Work only in this clone (branch `codex/tool-02`) and write only the paths in the card's "Writable" section. No game code changes.
- No other unit runs.
- Godot console: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`. Run `--headless --import` once before tests. The capture needs a window (not headless); run one capture at a time.
- Python: `C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe` (numpy, Pillow). Do not install packages. Set `PYTHONDONTWRITEBYTECODE=1`.
- Look at a middle frame of every new clip yourself before you finish.
- Hard stop: 110 minutes.
- `.git` may not be writable: write `reports/codex-tool-02/commit.ps1` (stage only your files, no `git add -f`; commit message ending `Co-Authored-By: Codex <noreply@openai.com>`) and do not run it.
- Final answer in Korean, short: the scenes made (count), what each shows, the capture command, what is still wrong.
