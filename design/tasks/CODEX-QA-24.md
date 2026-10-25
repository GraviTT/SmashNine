# CODEX-QA-24 · Reproduce three spots flagged after the 2026-10-21 bug review

- Request (2026-10-25, the user's status check, relayed by the check session): reproduce the three "다시 볼 곳" in `reports/status-2026-10-25/bug-check.md` section 4 (copied into this folder as `reports/status-2026-10-25-bug-check.md`). **Report only.** Do not change product code; the lead decides later, after the user's check.
- Base: tag `checkpoint-2026-10-25` (`main` `c51a417f`). Your folder is a plain export of that commit (no `.git`).
- Unit: Analyst. Folder `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/qa-b/SmashNine`. Cards QA-24, QA-25, QA-26 run in this order in this folder.
- Running at the same time: an image-analysis unit (Python, no Godot) in `qa-a`, and other sessions' Codex units on this 4-core PC. **You are this session's only Godot unit: one Godot process at a time** (except where QA-25 asks for deliberate load).
- Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless, `--import` once first.
- Background: `reports/bugfix-review-2026-10-21.md` (fixes 1–6), `characters/common/PlayerBase.gd` (`_wait_action`, `_respawn`, `_play_sprite_action`, `_update_character_sprite`), `scripts/story/StorySession.gd` (`pause_stage`, `resume_stage`, `update_hud`), `scripts/Main.gd` (`_update_hud`), `scripts/ui/MatchHud.gd` (`set_status`, `_set_match_hud_visible`). Drive story stages the way `tests/analysis/codex_qa_21/story_edges.gd` (`_start(stage)`) and `story_cutin.gd` do; inputs through `Input.parse_input_event` like a player.

## A. Story pause × start-up timers (fix `501f097`)
Start-ups (`_wait_action`), Frey's ultimate aftershock and the end of Luna's heart laser wait on physics-tick SceneTreeTimers with `process_always`. `pause_stage()` sets `get_tree().paused = true` and `Engine.time_scale = 0.0` to hold them.
- In a story stage, press a move with a start-up (Frey J and her ground ultimate; Rio's L rune shield has a long wait; Luna's heart laser if you can reach Brave form), then Esc inside the start-up. Stay paused for at least 2 s of wall time (count process frames), then resume (the menu action or Esc/Enter as the game takes it).
- Measure: did the attack area, aftershock or laser end happen **during** the pause (it must not); physics ticks from the press to the strike, with and without a pause; the remaining wait after resume against the expected one (±1 tick); `Engine.time_scale` after resume vs the game speed setting.
- Also: pause during the 1.0 s respawn protection blink and during hitstun — do they continue where they stopped?

## B. Hurt pose after a ring-out respawn (fix `2195855`)
`_respawn()` clears the attack lock and hitstun but not `sprite_action`, `sprite_action_timer`, `hurt_motion_duration`, `landing_motion_timer`.
- Battle royale (bots, seed 1001 or a dummy setup): hit a fighter with a strong hit (tumble ≥ 480 knockback) and with a light one (hurt), then put it past `ringout_y` the next physics frame so it rings out while the hurt/tumble action runs. Hold a direction for the 1 s after respawn.
- Per physics frame for 1 s after respawn: `character_sprite.animation`, frame, `sprite_action`, `sprite_action_timer`, `hitstun_timer`, `attack_lock_timer`, position change. Report how long a hurt/tumble pose shows while the fighter can already move, for each of the 8 bodies.
- Note which bodies have multi-frame hurt rows (SYS-06 optional strips) at this checkpoint; if none are in the game, say so.

## C. HP bar on a story scene change (fix `6355541`)
`Main._update_hud` calls `hud.set_status` (HP bar visible only while `clock_label` is) before `story_session.update_hud()` sets `clock_label.visible` for the scene.
- Story stages with a mid or post scene (and the stage start): per process frame around each transition (10 frames before, 30 after), record `hud.hp_bar.visible`, `hud.clock_label.visible`, `story_session.phase`, the dialogue's visibility, `hud.overlay.visible`. Count frames where the HP bar shows while a scene or overlay shows, and the reverse (combat with no HP bar).
- Same for pause/resume and the stage result.

## Every finding
Severity 상/중/하, exact repro (script, stage, seed, frame), measured vs guessed, the owning component and the likely fix location (file:line). If a spot is fine, say so with the numbers.

## Output
- `reports/codex-qa-24/README.md` (Korean): one table per spot (A, B, C) first, then details.
- Scripts `smash-nine-prototype/tests/analysis/codex_qa_24/`, numbers `reports/codex-qa-24/*.json`, logs `reports/codex-qa-24/logs/` (no log over 1 MB).
- `reports/codex-qa-24/files.txt`: every file you wrote (no git here; the lead commits).

## Writable
`reports/codex-qa-24/**`, `smash-nine-prototype/tests/analysis/codex_qa_24/**`. Nothing else. Do not write `user://` save files of the real game; use test paths as QA-21 did.

Hard stop: 75 minutes for this card.
