# CODEX-QA-25 · Does Nova's test miss a slow J under load since start-ups count physics ticks?

- Request (2026-10-25, relayed by the check session): the Rio worktree session suspects that since `501f0978` (start-ups wait on physics-tick timers) `tests/test_nova_prototype.gd`'s `_wait_for_source_script` misses Nova's slow J attack when the PC is loaded. Reproduce or rule it out. **Report only**: no product or test edits outside your paths.
- Base, folder, Godot, neighbours: as in `CODEX-QA-24.md` (same folder `qa-b`, run after QA-24).

## Background
`_wait_for_source_script` polls 100 times with `await create_timer(0.005).timeout` (idle-frame timers) for the attack Area2D the J creates. The J's start-up now ends inside a physics step; the attack lives about 0.075–0.12 s. Under load one process frame can run several physics steps (up to `max_physics_steps_per_frame`), so an attack might be created and freed between two polls. Before `501f0978` the start-up ended on an idle frame.

## Measure
1. Run `tests/test_nova_prototype.gd` 20 times with no extra load, and 20 times under load: (a) `--max-fps 15` or `10`, (b) two other headless Godot processes running a bot soak at the same time (say how many cores were busy). Count passes/fails and the exact failure message.
2. An instrumented copy of the momentum test in your folder: log per event the physics frame and process frame when the J is pressed, when the attack enters the tree, when it is freed, and each poll. Show a timeline for one passing and one failing run (if any fail).
3. If you can, show the same timeline with an idle-frame start-up for comparison by **subclassing in your test folder** (e.g. a Nova subclass overriding `_wait_action` back to `create_timer(seconds)`), not by editing product code.
4. Whether any other test uses the same polling pattern (`create_timer(0.00x)` loops looking for a node that lives briefly): list them with file:line and whether they could miss the same way.

## Report
`reports/codex-qa-25/README.md` (Korean): the pass/fail table per condition first, the timelines, the cause (measured vs guessed), the owner (test helper or game) and a proposed fix location (e.g. poll per `physics_frame` like `_wait_for` in the same file). Scripts `smash-nine-prototype/tests/analysis/codex_qa_25/`, logs `reports/codex-qa-25/logs/`, `reports/codex-qa-25/files.txt`.

## Writable
`reports/codex-qa-25/**`, `smash-nine-prototype/tests/analysis/codex_qa_25/**`.

Hard stop: 45 minutes.
