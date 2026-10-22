# CODEX-SYS-04 · Story mode stages 5–9: collapse escape, boss, shadows, ending

- Request: user 2026-10-22 "일단 추천대로 시작해볼것" (decision D43, plan `reports/story-mode-plan-2026-10-22.md`, step 3). Step 1 (CODEX-SYS-03) is merged: stages 1–4, story screens, save.
- Unit: Builder (code + UI) · Lead: Claude (reviews, merges, checks the web build)
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-ui/SmashNine`, branch `codex/sys-04` (from the latest main)
- Read first:
  - `reports/codex-sys-03/README.md` (how the skeleton works), the plan's section 3 table (stages 5–9), `design/STORY.md` (the script; every line is already in `assets/i18n/story.csv`)
  - `scripts/story/StoryCatalog.gd`, `StoryDirector.gd`, `StorySession.gd`, `StoryProgress.gd`; `scripts/ui/StoryDialogue.gd` (frame, name plate, scene pictures: a line's third field `{"cg": name}`), `scripts/ui/StoryScreens.gd`; `scripts/Main.gd` story hooks
  - `scripts/RealmMonster.gd` (`setup`, `make_elite`, `apply_hit`: monsters are neutral until a fighter hits them), `scripts/RealmMonsterSpawner.gd` (`_spawn_monster`), `scripts/SoulCrystalSpawner.gd` / `scripts/SoulCrystal.gd` (`setup`, `broken`, `SOUL_REWARD`)
  - `scripts/match/MatchDirector.gd` (warning/collapse states, `warning_ends_at`, `get_warning_seconds_left`, `get_sudden_death_band`, `_apply_sudden_death`), `Main._apply_phase_rules` (draws the band in the central realm), `characters/common/PlayerBase.gd` (`apply_environment_damage`), `scripts/Vfx.gd` (effect strip table)
  - `smash-nine-prototype/assets/art/story/README.md` (the shadow aura: 6 frames of 128×176, 10 fps, feet at y=160)
- Running at the same time: no other unit. The lead may edit `design/` and the script text in `story.csv`; do not rewrite existing `story.csv` lines.
- Timeout: given in the prompt.

## Make

1. **Stage 5 · Vanaheim, the collapse escape.** When combat starts, the stage realm enters the existing collapse warning for 60 s (the warning banner and the portal countdown labels already read the director). Three soul crystals stand at reachable points (one reachable only over a vine bridge). Two monsters that attack on sight. Breaking all three opens the exit (RIGHT → Jotunheim) and stops the warning; the countdown reaching 0 fails the stage ("time up"). Crystals pay their souls as in the battle royale. Objective line: "Soul crystals 1/3 · 0:42".
2. **Monster options** (`scripts/RealmMonster.gd`, `scripts/monsters/`), off by default so the battle royale and its tests stay the same:
   - `hostile`: also turns on the nearest living fighter in its realm within its sight range, not only after being hit.
   - `make_boss()`: size ×2, HP = elite HP × 4, damage ×2, knockback cap about 420, wind-up ×1.2 (readable), no respawn.
3. **Stage 7 · Muspelheim, the boss.** The giant magma boar (Muspelheim's melee skin, `make_boss()`); while it lives, two hostile ember imps every 20 s (at most four alive). The objective is the boss; the rival bar at the top shows its name and HP. Eruptions stay on.
4. **Stages 6 and 8** are 1:1 against Nova and Yuki with the catalog's rival mods (HP ×1.2 + one card; HP ×1.3 + two cards), Jotunheim quakes and Niflheim ice. Make them ready and check them.
5. **Stage 9 · Yggdrasil Heart.**
   - Wave 1: shadows of the four rivals (the other four fighters), HP ×0.6, a free-for-all (they attack each other and the hero).
   - When only the hero is left: heal the hero 30 %, freeze combat and play the mid scene (`story.s09.mid.1` narrator, `story.shadow.{hero}.1` shadow, `story.voice.{hero}.echo` hero, `story.shadow.{hero}.2` shadow), then wave 2: the hero's own shadow (same character and body, HP ×1.5, three random soul cards).
   - From wave 2 the arena shrinks: the sudden-death band from the full width to 20 % over 60 s, 8 HP/s outside it. **The band hurts only the hero** (bots do not know the band; D43). Ring-out 30.
   - The shadow look: the same character with a dark violet tint, name "Shadow <name>" (`tr("Shadow %s")`), the ART-70 aura `assets/art/story/shadow_aura.png` looping behind the body (add a `Vfx.gd` table entry), aggression 1.0. A new dialogue speaker `shadow`: the hero's face tinted the same way, name "Shadow <hero>", on the right.
6. **Ending.** After stage 9's post lines (they already carry the epilogue picture), an ending screen: the hero's main art (`FrontendMenu.illustration`), the three lines `story.ending.{hero}.1–3`, "STORY COMPLETE", buttons Story map / Title. The save marks the hero `done` (the select screen shows CLEAR).
7. All nine stages ready on the map; stage 9 opens after stage 8. Stages 1–4, the dialogue presentation (frame, plate, scene pictures, HUD hidden during scenes) and the battle royale stay as they are.

## Tests and checks

- `test_story_data`: all nine ready; the `shadow` speaker; stage 9's mid lines and the ending IDs exist for all five heroes.
- `test_story_flow`: add stages 5–9 for two heroes (one of them meeting a home stage among 6 and 8), stage 5 time-up failure and success, the boss stage, stage 9 wave 1 → mid scene → wave 2 with the band hurting only the hero, the ending screen and the `done` flag. Keep the existing checks.
- Monster options covered by a test (a hostile monster attacks an approaching fighter without being hit; boss numbers), and `test_monster_ecology` still passes unchanged.
- Whole `tests/run_all.ps1` prints ALL PASSED.
- Captures in Korean (windowed, briefly, one at a time): stage 5 with the warning and crystals, stage 7 with the boss bar, stage 9 wave 1 shadows, wave 2 with the band and the aura, the mid scene with the shadow speaking, the ending screen — in `reports/codex-sys-04/` with a contact sheet.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/scripts/story/**` | story code |
| `smash-nine-prototype/scripts/ui/**` | story screens, dialogue speaker, ending, HUD story parts only |
| `smash-nine-prototype/scripts/Main.gd` | story hooks only |
| `smash-nine-prototype/scripts/RealmMonster.gd`, `smash-nine-prototype/scripts/monsters/**` | the two monster options only |
| `smash-nine-prototype/scripts/Vfx.gd` | one table entry for the aura |
| `smash-nine-prototype/assets/i18n/strings.csv` | new screen words |
| `smash-nine-prototype/tests/test_story_*.gd`, a new monster-option test, `test_language.gd`, `run_all.ps1` | tests |
| `reports/codex-sys-04/**` | report, captures, contact sheet |

Forbidden: `characters/**`, `scripts/EnemyAI.gd`, `scripts/realms/**`, the battle-royale behaviour of `MatchDirector.gd` and the monster spawner, existing `story.csv` lines, art files, the soul-card offer panel and HP bar, `design/**`, `AGENTS.md`, merging, pushing, installing packages, downloads. At most two Godot processes at once.

## Done when

- [ ] Stages 1–9 play from the title to the ending with any hero (home variants included); tests save nothing.
- [ ] `reports/codex-sys-04/README.md` in Korean: what was built, the new options and data, captures, tests, what is not done, notes for the difficulty step (step 4).
- [ ] Commit on the branch, or `reports/codex-sys-04/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
