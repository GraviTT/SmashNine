# CODEX-SYS-06 · Wiring for the new motions: multi-frame jump/fall/hurt, landing, victory, and the new monster sheets

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`. Codex writes the wiring too, so the art the user picks can go in at once.
- Unit: Builder (code). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/sys-06` (from the latest main).
- Running at the same time:
  - ART-71 (monster art), ART-72 (character motion art) and AUD-01a (sounds), in other clones
  - **You are the only unit running Godot**, so headless runs are yours alone
  - Other Claude sessions may commit to main. Keep diffs small and local.
- Read first:
  - `AGENTS.md`
  - `design/tasks/CODEX-ART-71.md` (the new monster sheet: 6 rows) and `design/tasks/CODEX-ART-72.md` (the new character rows)
  - `characters/common/PlayerBase.gd`: sheet loading, `_update_character_sprite`, the D38 pose clock, the defeat motion `_show_defeat`
  - `scripts/RealmMonster.gd`, `scripts/monsters/MonsterArchetypes.gd`
  - `scripts/ui/FrontendMenu.gd` (results), `scripts/ui/StoryScreens.gd` (`show_story_ending`)
  - `tests/run_all.ps1`

## The rule for every part
**The art is not in the game yet.** Every path must keep today's behaviour exactly when its new row or sheet is absent (one-drawing jump/fall/hurt, no land row, no victory row, old 4-row monster sheets). Test both, the new path with stand-in rows built from existing frames in the test, like `tests/test_defeat_motion.gd` does.

## 1. Fighters (`PlayerBase.gd`)
- `jump`: when the row has more than one drawing, play it once and hold the last while rising.
- `fall`: loop it.
- `hurt`: play it once over the hitstun and hold the last.
- `land` (new row, optional): on touching the floor from the air, play it once (2 drawings at 12 fps). Any move, jump, attack or guard cuts it. No change to movement or timing.
- `victory` (new row, optional): `play_victory()` plays it once and holds the last drawing; falls back to idle without the row.
- None of this may touch the attack pose clock (D38) or the defeat motion.

## 2. Monsters (`RealmMonster.gd`)
- A sheet 6 rows tall (`height == 6 × cell`) uses the new layout:
  - idle 6 · walk 6 · windup 4 · attack 6 · hurt 2 · defeat 4
  - fps and loop as in ART-71
- A 4-row sheet keeps today's layout and code path.
- With the new layout:
  - `windup` plays across the behaviour's wind-up time from `MonsterArchetypes`, holding the last drawing.
  - `attack` plays during the action: looping for charge and swoop, once otherwise.
  - `hurt` plays on a hit.
  - `defeat` plays when it dies, then the monster fades over 0.3 s and is freed.
  - Elites keep their ×1.35 size and aura.
- No change to behaviour, damage, timing or hit boxes.

## 3. Screens
- Results (`FrontendMenu.gd`, wherever the winner is drawn): show the winner animating its `victory` row when its sheet has one. Otherwise keep what is drawn today.
- Story ending (`StoryScreens.gd` `show_story_ending`): the same, for the hero.

## Tests
- New tests for every path above, with stand-in rows. The old paths must be unchanged (assert today's behaviour).
- Add the tests to `tests/run_all.ps1`.
- Run the whole suite (`powershell -ExecutionPolicy Bypass -File tests/run_all.ps1`, after `--headless --import`). It must pass.

## Writable
- `characters/common/PlayerBase.gd`
- `scripts/RealmMonster.gd`, `scripts/monsters/**`
- `scripts/ui/FrontendMenu.gd`, `scripts/ui/StoryScreens.gd`
- `tests/test_*.gd` (new files), `tests/run_all.ps1`
- `reports/codex-sys-06/**`: README in Korean (what changed, how each new row is used, the test list), and `commit.ps1`, which must:
  - not use `git add -f`
  - add no `__pycache__`

Forbidden: art files, other scripts, gameplay numbers, `project.godot`.

Hard stop: 150 minutes.
