# CODEX-SYS-03 · Story mode skeleton: entry, stages 1–4, dialogue, save

- Request: user 2026-10-22: "SmashNine에 솔로용 간단한 스토리 모드를 만들고 싶다 … 스토리 모드 기획안을 제안해줘" → plan `reports/story-mode-plan-2026-10-22.md` → "일단 추천대로 시작해볼것". Decision D43.
- Unit: Builder (code + UI) · Lead: Claude (reviews, merges, checks the web build)
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-ui/SmashNine`, branch `codex/sys-03` (from the latest main)
- Read first:
  - `reports/story-mode-plan-2026-10-22.md` (Korean; sections 3–7 are the design) and `design/DECISIONS.md` D43, D1, D4, D15, D16, D41, D42
  - `scripts/Main.gd` (`_ready`, `next_screen`, `_create_director`, `_start_match`, `_apply_phase_rules`, `_handle_global_input`, `_handle_portal_input`, `_on_match_finished`, `_freeze_combat`, `_reload_frontend`, `_add_player`, `_on_realm_state_changed`)
  - `scripts/match/MatchDirector.gd` (subclass it), `scripts/match/SoulGrowth.gd`, `scripts/match/SoulCards.gd`
  - `scripts/realms/RealmLayout.gd` (`get_portals`: portals open only to stable/warning neighbours; grid, `find_by_grid`), `scripts/realms/RealmCatalog.gd` (realm order and names)
  - `scripts/RealmMonsterSpawner.gd` (`_spawn_monster` shows how a monster is made), `scripts/RealmMonster.gd` (`setup`, `make_elite`, `defeated`; monsters are neutral until a fighter hits them)
  - `characters/common/PlayerBase.gd` (`setup(data, ...)`, `souls`, `add_souls`, `apply_upgrade`, `incoming_damage_scale`, `ai_aggression`, `defeated`, `cancel_pending_actions`, `grant_protection`), `scripts/PlayerFactory.gd`, `characters/CharacterRegistry.gd`
  - `scripts/ui/FrontendMenu.gd` (screens and helpers), `scripts/ui/MatchHud.gd` (`show_start_screen`, `show_results`, `_set_match_hud_visible`, `set_clock`, cut-in), `scripts/ArtSettings.gd` (`character_portrait`), `scripts/Language.gd`, `scripts/GameSpeed.gd`
  - `assets/i18n/strings.csv`, `tools/font_subset/make_ui_font.py`, tests `test_language.gd`, `test_font_coverage.gd`, `test_frontend_flow.gd`, `test_restart.gd`, `run_all.ps1`
- Running at the same time: no other unit. The lead writes the story script draft in `design/STORY.md` and edits design docs; do not edit `design/`.
- Timeout: given in the prompt.

## Today

There is no story mode. The title has Play / Watch bots / Options / Controls. A match is the battle royale run by `MatchDirector` (wave timeline, last survivor). Realm states decide where portals open. Monster and soul-crystal spawners fill every playable realm by themselves.

## Make (keyboard and mouse; English source strings through `tr()`, Korean in the tables)

1. **Title:** rename "Play" to "Battle Royale" (Korean "배틀로얄"; same action, still the first button so Enter keeps opening the battle-royale select). Add **"Story"** as the second button. Watch bots / Options / Controls follow.
2. **Story character select** (screen name `story_select`, reuse the select layout and helpers): the five fighters, under each portrait the progress (`★ n/9`, or `CLEAR` when done), the selected fighter's main art, name and role, body switch (V / button) for Nova and Rio, **Continue** (only when that fighter has a saved run), **New journey**, **Difficulty: Normal / Easy**, Back. Number keys 1–5 only select here: they must **not** start a battle-royale match (Main's quick start checks the screen name; keep `title` and `select` as they are).
3. **Story map** (screen `story_map`): the 3×3 realm grid as on the minimap, each cell the realm emblem `assets/art/ui/realm_emblems/<name>.png` (32 px, draw ×3 nearest) and its name, path lines in story order, cleared cells bright, the next one pulsing, the rest dim, stages not ready marked "Coming soon". Right panel: stage number, title, realm, objective, the rival's face (or the home guardian), Start, Back. Cleared stages can be replayed.
4. **`scripts/story/StoryCatalog.gd`** (data only, like `RealmCatalog`): all **nine** stages in order with these fields: `id`, `realm` (index), `exit` (direction of the next realm: Vector2i, or none for 8), `title`/`goal`/`tips` (story.csv IDs), `rival` (character id or ""), `home_elite` (the realm's melee skin from `RealmCatalog` "monsters"), `waves`, `rules` (`damage_scale`, `ringout_damage`, `recovery`, `aggression`, `hazards`), `rival_mods` (`hp`, `cards`), `souls_reward`, `dialogue` (`pre`, `post`, `home_pre`, `home_post`: lists of `[speaker, id]`), `ready` (bool).
   - Order, realms, rivals and numbers are the plan's section 3 table. Exits: 1 LEFT, 2 DOWN, 3 DOWN, 4 RIGHT, 5 RIGHT, 6 UP, 7 UP, 8 none (the root to the heart).
   - **Ready now: stages 1–4.** 1 = two waves of two Midgard monsters (melee + ranged skins), recovery 3, ring-out 15, damage scale 0.3. 2, 3, 4 = 1:1 against the rival (Frey, Luna, Rio), damage scale 0.4, ring-out 20, rival HP ×0.8 / ×1.0 / ×1.0. **Home variant:** when the hero is that stage's rival, spawn the realm's melee skin as an elite (`make_elite()`) plus two normal monsters instead, and use the `home_pre`/`home_post` lines. Stages 5–9: full data with `ready: false` (the next card builds the collapse escape, the boss, the shadows).
5. **`scripts/story/StoryDirector.gd`** extends `MatchDirector`. No battle-royale events. The stage realm is stable and every other realm is locked (bots then have no portal to leave by). Rules come from the stage data. The finish follows the objective instead of "last survivor": the hero at HP 0 → `match_finished(null, "stage failed")`; objective done → set the exit realm stable (the real portal toward it appears) and announce "The way opens. Use the portal (Q)."; the hero uses that portal → `match_finished(hero, "stage clear")`. Difficulty: Easy = the hero takes ×0.7 damage, enemies have ×0.8 HP. For a per-combatant damage scale give the director `get_combat_damage_scale_for(combatant)` and have `Main._apply_phase_rules` use it when the director has it (the battle royale stays unchanged).
6. **`scripts/story/StorySession.gd`** (node made by Main in story mode): spawns the hero and the waves (rivals through Main's `_add_player`, monsters like `RealmMonsterSpawner._spawn_monster`, paying `soul_reward` souls to the killer), keeps combat frozen during dialogue (same idea as `_freeze_combat`, undone at the start), counts the objective ("defeat all": every enemy of every wave; the next wave comes when one is cleared), gives the HUD its objective text ("Monsters 2/4", "Defeat Frey", "Use the portal  ←  Q"), adds `souls_reward` (15) to the hero when a rival falls, and handles the exit portal: in story mode the hero's Q on the exit portal ends the stage instead of moving realms. The monster and soul-crystal spawners stay off in story mode (Main must not sync them).
7. **Run state:** souls and soul cards carry from stage to stage (D4/D16 unchanged: thresholds 25/50/75, at most 3 cards). At a stage start restore the checkpoint: set `souls` directly (do not re-fire passed thresholds) and re-apply the cards with `apply_upgrade(SoulCards.find(id))`. HP is full at every stage start. A retry restores that stage's checkpoint.
8. **`scripts/story/StoryProgress.gd`**: save in `user://story.cfg`, per fighter: cleared count, checkpoint per stage (souls, card ids), difficulty, done. Like `Language.gd`, headless and script runs never read or write the real file; tests may pass another path.
9. **Dialogue** (`scripts/ui/StoryDialogue.gd`): a box at the bottom, the speaker's face (`ArtSettings.character_portrait(id, body)`; the hero's chosen body) and name in the character's colour, hero on the left, others on the right, the silent side dimmed; text appears quickly (about 45 characters a second, real time, not slowed by the game-speed setting), J / Enter shows the whole line then goes on, Esc skips the scene. Speakers: `narrator` (no face, centred), `hero`, `rival`, or a character id. IDs may contain `{hero}` / `{rival}` (replaced by character ids before `tr()`); in the text `%s` is the hero's translated name.
10. **Stage start card:** "STAGE n", realm name, stage title, objective, one or two tips; for a rival stage a VS line with both faces over the ultimate cut-in band art (`assets/art/vfx/ult_cutin_band.png`). J / Enter or 2.5 seconds.
11. **HUD in story mode:** the objective line in the clock's place, and a rival HP bar at the top centre (name + bar; the `hp_bar` frame art) while a rival is up. Do not rewrite the soul-card offer panel or the HP bar in `MatchHud.gd`; call them as they are.
12. **Pause (story only):** Esc during a stage → Resume / Retry / Story map / Title (`get_tree().paused`; unpause before any reload).
13. **Stage result:** clear → time, damage taken, cards held; Next / Story map. Failed → Retry / Story map / Title. R retries. After stage 4 (the last ready one) the result says the next stage is coming soon and Next goes to the map.
14. **Flow:** keep Main's pattern (static session state + `reload_current_scene` between screens and stages). The battle royale, Watch bots, every existing key (1–5, V, B, F2, T, F3, F4, H, R) and `test_restart`'s node baseline stay as they are.
15. **Story text table** `assets/i18n/story.csv` (columns `keys,en,ko`; keys are IDs such as `story.s02.pre.1`, `story.voice.frey.challenge`, `story.s01.title`): register it in `project.godot` next to `strings.csv` (both `.translation` files), make `tools/font_subset/make_ui_font.py` read it too, make `tests/test_font_coverage.gd` scan it too, and make `tests/run_all.ps1` import when either table's translation is missing. Write **short placeholder lines** for stages 1–4 (pre 2–3, post 1–2, home pre/post 1–2, one `challenge` and one `victory` voice line per fighter), in simple English and plain Korean; the lead's script replaces them. Screen words (buttons, labels) go in `strings.csv` with English keys as today.
16. If `test_font_coverage` fails because a Korean character is not in the subset font, do not rebuild the font (no packages): reword the line or list the characters in the report — the lead rebuilds it.

## Tests and checks

- New `tests/test_story_data.gd`: nine stages in the plan's order and realms; every exit points at the next stage's realm (grid neighbours; 8 → 9 is the root); every ID the catalog uses (titles, goals, tips, dialogue with `{hero}`/`{rival}` expanded for all five fighters) exists in `story.csv` with non-empty `en` and `ko` and the same `%s` placeholders; ready stages have at least one wave.
- New `tests/test_story_flow.gd`: real key/mouse input through title → Story → story select → map → stage 1 (dialogue advanced with J, start card) → defeat the monsters (hits through the public `apply_hit` are fine) → the exit portal appears and Q on it clears the stage → result → Next → stage 2 starts against Frey (with the hero not Frey) and the hero home variant (hero Frey) spawns the elite instead → the hero falls → failed → Retry restores the checkpoint (souls, cards) → back to the title; number keys on `story_select` do not start a match; no save file written; node count back to the baseline after the round trip (like `test_restart`).
- Update `test_language` (the "Play" rename, story screens in Korean fit their boxes with `_check_menu_fit`) and `test_frontend_flow` (title order) as needed. Add the two new tests to `run_all.ps1` before `test_restart`.
- Whole `tests/run_all.ps1` prints ALL PASSED (the certificate-store ERROR is known sandbox noise).
- Captures (windowed, briefly, one at a time) in Korean: title, story select, map, stage start card, dialogue, stage 1 with the objective line, stage 2 with the rival bar, result — saved to `reports/codex-sys-03/` with a contact sheet.

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/scripts/story/**` | new story code |
| `smash-nine-prototype/scripts/ui/**` | story screens, dialogue, title entry, HUD objective line and rival bar |
| `smash-nine-prototype/scripts/Main.gd` | mode switch and flow hooks only |
| `smash-nine-prototype/assets/i18n/strings.csv`, `smash-nine-prototype/assets/i18n/story.csv` (+ their `.import`) | text |
| `smash-nine-prototype/project.godot` | **only** the translations list |
| `tools/font_subset/make_ui_font.py` | the source list only |
| `smash-nine-prototype/tests/test_story_data.gd`, `test_story_flow.gd` (new), `test_language.gd`, `test_font_coverage.gd`, `test_frontend_flow.gd`, `run_all.ps1` | tests |
| `reports/codex-sys-03/**` | report, captures, contact sheet |

Forbidden: `characters/**`, `scripts/EnemyAI.gd`, `scripts/RealmMonster*.gd`, `scripts/monsters/**`, `scripts/realms/**`, the battle-royale behaviour of `MatchDirector.gd` (subclass it instead), the soul-card offer panel and HP bar, `design/**`, `AGENTS.md`, merging, pushing, installing packages, downloads. At most two Godot processes at once.

## Done when

- [ ] Stages 1–4 play from the title to the result with any of the five fighters (home variant included), Continue / New journey / replay work, nothing is saved by tests.
- [ ] `reports/codex-sys-03/README.md` in Korean: what was built, the data format (catalog fields, speakers, ID scheme), the input map, captures, tests, what is not done, notes for the next card (stages 5–9).
- [ ] Commit on the branch, or `reports/codex-sys-03/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
