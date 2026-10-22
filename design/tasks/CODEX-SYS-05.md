# CODEX-SYS-05 · Sound wiring: audio manager, event hooks, volume options (no sound files yet)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 1 (SYS-05).
- The game has no sound. The sound trial (AUD-01a effects, AUD-02a music; `art/audio_bakeoff/`, listening page `tools/sound_viewer/`) waits for the user to pick a style.
- **This card wires sound without adding any sound file.** The game stays silent until the user picks; then adopting = copying files into `assets/audio/`. Do not copy any candidate from `art/audio_bakeoff/` into the game.
- Unit: Builder (code). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/sys-05` (from the latest main). You write the product code; the lead reviews and merges.
- Running at the same time: image units in other clones (ART-73 fix, ART-74, ART-75, ART-76, ART-77). **You are the only unit running Godot.**
- Other sessions edit `characters/<name>/*.gd` (the skill session) and `scripts/story/**` (the story session). **Do not edit those files.** Hook into the shared code named below instead.

## Read first
- `AGENTS.md`, `design/DECISIONS.md` D41–D43
- `scripts/GameSpeed.gd` and `scripts/Language.gd` (how a setting is saved: a static helper and `user://*.cfg`)
- `scripts/ui/FrontendMenu.gd` (the options screen), `assets/i18n/strings.csv` (D42: every new text goes through the translation table, Korean and English)
- `characters/common/PlayerBase.gd`, `scripts/RealmMonster.gd`, `scripts/realms/RealmHazards.gd`, `scripts/ui/MatchHud.gd`, `scripts/Main.gd`
- `tools/audio_synth/README.md`, `reports/codex-aud-01a/README.md` (the trial sound ids and their loudness)

## 1. The sound list: `design/AUDIO.md` (new)
Write the list of sound ids the game asks for, one table: id, when it plays, where it is hooked (file:function), fallback id, max voices.

Start from this list and change it only where the code shows a better hook; say why in the table:

| Group | Ids |
|---|---|
| Fighters | `swing_light`, `swing_heavy`, `hit_light`, `hit_heavy`, `hit_launch` (a hit that launches), `hurt`, `guard`, `parry`, `jump`, `land`, `dash`, `tumble`, `ko`, `respawn` |
| Skills | `skill_<character>_1`, `skill_<character>_2`, `ult_<character>` for frey, luna, luna_brave, yuki, nova, rio (from `PlayerBase.skill_one()`, `skill_two()`, `ultimate()` when the skill really starts); fallbacks `skill_cast`, `ult_start` |
| Monsters | `monster_windup`, `monster_<archetype>` for the ten D41 archetypes (fallback `monster_attack`), `monster_hurt`, `monster_defeat`, `elite_appear` |
| Realms | `hazard_warning`, `eruption`, `quake`, `beam`, `vines`, `belt_reverse`, `gate_open`, `gate_travel`, `bush_rustle`, `collapse_warning`, `portal` |
| Progress | `soul_pickup`, `card_offer`, `card_pick`, `match_start`, `results`, `victory` |
| Menus and story | `ui_move`, `ui_select`, `ui_cancel`, `story_text`, `story_advance` (story hooks only where `MatchHud` or `FrontendMenu` already sees the event; otherwise list them as "needs a story-session hook") |
| Music | `music_title`, `music_select`, `music_battle`, `music_story`, `music_results` (fallback `music_battle` for in-match tracks) |

The twelve trial ids (`hit_light`, `hit_heavy`, `swing`, `jump`, `land`, `guard`, `parry`, `hurt`, `ko`, `portal`, `ui_select`, `ui_cancel`) must keep their names, or map to them (`swing` → `swing_light`/`swing_heavy` falls back to `swing`).

## 2. The audio manager
- `scripts/audio/AudioManager.gd`: a node the game creates once (no autoload: add it where `Main` and the front end can reach it; say where and why).
- Buses `Music` and `SFX` under `Master` (create them in code if the project has no bus layout; say which).
- `play(id, options)`: loads `res://assets/audio/sfx/<id>.ogg` or `.wav` on first use and caches it. A missing file falls back along the table, then plays nothing, **with no error and no warning spam** (one debug line per missing id at most, off in release).
- Voices: a small pool; at most N of one id at once (from the table), a minimum gap between two of the same id (about 40 ms), a little pitch variation (about ±4%) for repeated hits and swings.
- `play_music(track)`: one music player, loops, a short crossfade (about 0.5 s) on change, nothing when the file is missing.
- Game speed (`GameSpeed`) does not change pitch.
- Web: the first sound plays after the first input; nothing breaks before it.

## 3. Hooks
Hook every id in the table at the one place the code owns that event (the hit is resolved in `apply_hit`, the jump where the jump starts, and so on). No hook in `characters/<name>/` or `scripts/story/`. Keep each hook to one line (`AudioManager` call); no game logic changes. **Hit boxes, damage, timing and AI must not change**: run the existing tests to show it.

## 4. Options
In the options screen: master, music and effects volume (0–100, steps of 10) and a mute toggle, Korean and English through the translation table, saved in `user://audio.cfg` (static helper like `GameSpeed`). Default: master 80, music 60, effects 80. The options screen must still fit both languages (`tests/test_frontend_flow.gd`, the text slot checks of QA-21).

## 5. Tests
- `tests/test_audio.gd`, added to `tests/run_all.ps1`:
  - with no sound files: a full scripted match path asks for sounds and nothing errors
  - with test tones made in code (`AudioStreamWAV`) registered for a few ids: `play` starts a voice on the `SFX` bus; the voice cap and the minimum gap hold; the fallback chain works
  - every id in `design/AUDIO.md` is requested at least once by a scripted run (a probe that records requests; list any that a headless run cannot reach and why)
  - the volume settings save and load, and set the bus volumes
- The full suite `tests/run_all.ps1` passes. Run it once at the end.

## Output
- The code, `design/AUDIO.md`, the tests.
- `reports/codex-sys-05/README.md` (Korean): what is hooked where, what is not and why, the request counts from the probe, the test results.
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no logs.

## Writable
- `smash-nine-prototype/scripts/audio/**` (new)
- one-line hooks in: `characters/common/PlayerBase.gd`, `scripts/RealmMonster.gd`, `scripts/realms/RealmHazards.gd`, `scripts/RealmMonsterSpawner.gd`, `scripts/ui/MatchHud.gd`, `scripts/ui/FrontendMenu.gd`, `scripts/Main.gd`, `scripts/SoulCrystal.gd`
- the options rows in `scripts/ui/FrontendMenu.gd`; new keys in `assets/i18n/strings.csv` (not `story.csv`, which the story session owns) and its imported `.translation` files
- `smash-nine-prototype/default_bus_layout.tres` (if you choose a bus layout file)
- `smash-nine-prototype/tests/test_audio.gd`, `tests/run_all.ps1`
- `design/AUDIO.md`, `reports/codex-sys-05/**`

Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Hard stop: 150 minutes.
