You are the same Codex builder unit, continuing CODEX-SYS-05 (sound wiring) in this clone, branch `codex/sys-05`. Your work so far is uncommitted here; keep it. Read `design/tasks/CODEX-SYS-05.md` and your `reports/codex-sys-05/README.md` again.

## The lead's review
The manager, the catalog, the options and the tests are good. Five things must change before the merge.

### 1. Only the realm the player watches is heard (the big one)
Every sound now plays everywhere: a match has eight fighters and about thirty monsters spread over nine realms, all far off camera, and the player would hear every one of them. Realms are not hidden, only off camera, so visibility does not help.

- The watched realm is `Main.current_map_index` (the camera's realm: the human's, or the spectated fighter's). Main gives it to the manager (a callable, or a value Main updates when the map changes; your choice, say why).
- Mark the world groups in the catalog (`world: true`): fighters, skills, monsters, realms. A world sound plays only when its realm is the watched realm.
  - Fighters and monsters: `source.realm_index`.
  - `RealmHazards`: pass the realm explicitly (`{"realm": realm_index}`) from `_start_warning`, `_start_active` and `_carry_through_gates`; the node itself has no realm.
  - A world request with no realm found: play it, and count it in the probe as `no_realm`, so the report shows none are left.
- Not filtered: menus, music, `match_start`, `results`, `victory`, `card_offer`, `collapse_warning`.
- Story mode has one realm at a time; it must work there too (the story code is not yours to edit: use what `Main` knows).
- Test (in `tests/test_audio.gd`): two fighters in different realms; a hit in the watched realm plays, the same hit in another realm is requested but plays nothing. The same for a monster attack and a hazard warning. Changing the watched realm changes what is heard.

### 2. The human's progress only
`card_pick` (`apply_upgrade`) and `soul_pickup` (`add_souls`) play for every bot too. Play them only for the human player (bots pick cards automatically and gain souls all match long). Find the human the way the code already does (`is_human`), not by a new rule.

### 3. `ui_move` on the player's own navigation only
`focus_entered` also fires when a screen opens and `_finish()` gives the first button focus, so every screen change plays `ui_select` and `ui_move` together. Play `ui_move` only when the player moves the focus (keys or mouse), not on the screen's own first focus.

### 4. The class doc comments
In `Main.gd`, `RealmHazards.gd`, `MatchHud.gd`, `RealmMonsterSpawner.gd` and `FrontendMenu.gd` you put `const AUDIO := preload(...)` between `extends` and the `##` class description, which detaches it. Put the `const` with the other constants, below the class description, as the files do for their other preloads.

### 5. The full suite
Your report says the full suite ran once with 51/52 and you fixed the HUD failure but did not rerun it. Run `smash-nine-prototype/tests/run_all.ps1` once at the end, after these changes, and report its last lines.

## Output
- the changes, with the tests
- update `design/AUDIO.md` (the `world` column, the human-only ids) and `reports/codex-sys-05/README.md` (Korean): what changed in this pass, the probe counts (`no_realm` must be 0), the full suite result
- write `commit.ps1` again (only your files, include this prompt file, no `git add -f`, no `__pycache__`, no logs). Do not run it.

## Rules
- Write only the card's writable paths. Never edit `characters/<name>/` or `scripts/story/`.
- No game logic changes: hit boxes, damage, timing, AI and saves stay exactly as they are.
- Running at the same time in other clones: image units and a viewer unit. You are the only unit running Godot.
- Hard stop: 90 minutes.
- Final answer in Korean, short: the five points (done or not, how verified) and the full suite result.
