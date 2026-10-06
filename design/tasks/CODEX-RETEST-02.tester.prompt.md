You are the Codex tester unit of Smash Nine Realms. Branch codex/tester-02 in your own clone, card design/tasks/CODEX-RETEST-02.md (read it first, then your previous report reports/codex-tester-01/README.md).
Re-run exactly the inputs of reports/codex-tester-01 (real_input_restart.gd with 10 restarts, real_input_core.gd) against the current main (fix commits 2bba7b1, 17fa35f, 2307d9b) and report a before/after table per item, plus the new checks in the card (start screen HUD, mixed opening pair).
- Real input only (Input.parse_input_event with InputEventKey); reading state to measure is fine.
- Same writing limits as before (card table); do not edit smash-nine-prototype/scripts, characters, scenes, project.godot or existing tests.
- The Codex analyst unit runs headless soaks at the same time: one windowed Godot at a time, keep runs short.
- Godot: C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe . The certificate-store ERROR line is known sandbox noise: count it separately, report every other error.
- If .git is not writable, prepare the commit script.
- Final answer in Korean: before/after table, what is still open, what a human should look at.
