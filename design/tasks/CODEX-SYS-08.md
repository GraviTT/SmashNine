# CODEX-SYS-08 · QA-22 follow-ups: moon gate re-crossing, sound request rates, story sound hooks

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan track 5 (QA lane, fixes after QA-22).
- Read `reports/codex-qa-22/README.md` first (its numbers are the "before" of this card), then `design/AUDIO.md`, `scripts/audio/`, `scripts/realms/RealmHazards.gd`.
- Unit: Builder (code). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/sys-08` (from the latest main). **You are the only unit running Godot.** You write the product code; the lead reviews and merges.
- The story session is closed; its files have no pending changes. This card may add **one-line sound hooks** in `scripts/story/StorySession.gd`, `scripts/ui/StoryDialogue.gd` and `scripts/ui/StoryScreens.gd`, nothing else in them.

## 1. Moon gates: no ping-pong
After the exits were put on platform tops (`c52d784`), bots near an exit cross back and forth: QA-22 saw Frey cross 4 times in 4 seconds (seed 2106, t=153.25–157.47 s), every 1.0 s (`GATE_COOLDOWN`).
- Raise the per-fighter gate cooldown to **2.5 s**, and keep the "step out before it takes you back" rule.
- `tests/test_realm_gimmicks.gd`: re-entering within 2.5 s does not carry; after 2.5 s (having stepped out) it does.
- Re-run QA-22's gate soak for seeds 2105 and 2106 (`tests/analysis/codex_qa_21/gate_soak.gd` as QA-22 ran it) and report the passes per bot per active window, before and after.

## 2. Sound request rates
QA-22 measured, in the watched realm, `land` up to 22 requests a second, `hurt` 22, `hit_light` 19 (8 bots). Every one of them would play once files exist (only the 40 ms gap and the voice caps hold them back).
- Add a per-id minimum gap to the catalog (`gap_ms`, default 40). Start with `land` 150, `hurt` 70, `hit_light` 50, `hit_heavy` 60, `swing_light` 60, `swing_heavy` 60, `tumble` 120, `monster_hurt` 70. Say why for any other value you choose.
- `land` plays only after at least 0.12 s in the air (a small hop or a platform edge is silent). Keep the state per fighter in the audio code, not in `PlayerBase`'s movement.
- Measure again with QA-22's recorder (`tests/analysis/codex_qa_22/audio_recorder.gd`, the same three battle seeds): requests that **would play** per second per id, before and after. Report the peaks.
- Tests in `tests/test_audio.gd`: the gaps hold per id; a short hop does not play `land`; a real jump does.

## 3. Story sound hooks
QA-22: `story_text` and `story_advance` never fire, and the story result and ending screens keep `music_story` (no `results`, `victory`, `music_results`), and the story exit (Q) plays no `portal`.
- `story_text` when a dialogue line appears, `story_advance` when the player advances it (`scripts/ui/StoryDialogue.gd`).
- On the story result screen: `results`, then `victory` when the stage was won, and `music_results`; on the ending: `victory` and `music_results` (`scripts/ui/StoryScreens.gd`).
- `portal` when the player leaves through the exit (`scripts/story/StorySession.gd`).
- One line each, through `AudioManager`'s helpers; no story logic changes. Update `design/AUDIO.md` (no id left "needs a story-session hook").
- Test: a story stage driven as QA-22 drove it requests these ids at those moments.

## Every change
- Hit boxes, damage, timing, AI (except the gate cooldown above) and saves do not change.
- The full suite `smash-nine-prototype/tests/run_all.ps1` once at the end; report its last lines.

## Output
- the code and tests; `reports/codex-sys-08/README.md` (Korean): the three parts with before/after numbers
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no logs over 1 MB

## Writable
`smash-nine-prototype/scripts/realms/RealmHazards.gd` (the gate cooldown), `smash-nine-prototype/scripts/audio/**`, the one-line hooks in `smash-nine-prototype/scripts/story/StorySession.gd`, `smash-nine-prototype/scripts/ui/StoryDialogue.gd`, `smash-nine-prototype/scripts/ui/StoryScreens.gd`, `smash-nine-prototype/characters/common/PlayerBase.gd` (only if the land hook must move; say why), `smash-nine-prototype/tests/test_audio.gd`, `smash-nine-prototype/tests/test_realm_gimmicks.gd`, `smash-nine-prototype/tests/analysis/codex_sys_08/**`, `design/AUDIO.md`, `reports/codex-sys-08/**`.

Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Hard stop: 150 minutes.
