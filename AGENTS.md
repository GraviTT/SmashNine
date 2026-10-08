# Smash Nine Realms — agent guide

("Smash Nine Realms" / SmashNine is a working title.)

2D pixel platform-brawler battle royale prototype in Godot 4.7 (GDScript).
Claude is the lead: it owns the product code, decides, fixes and merges.
Codex runs as units (tester, analyst, builder) in its own clones and writes only the paths its task card allows.

## Read first

1. `design/DECISIONS.md` — current decisions and the numbers behind them (wins over every other doc)
2. `design/ROADMAP.md` — milestones and done-criteria
3. `smash-nine-prototype/FINAL_GAME_GOAL.md` — what the game must feel like
4. `smash-nine/Concept1.png`, `smash-nine/Concept2.png` — concept art (realm map, timeline, growth, art tone)
5. `smash-nine/GAME_DESIGN_DOCUMENT.md` — older GDD; lore and roster reference only

## Layout

| Path | What |
|---|---|
| `smash-nine-prototype/` | the Godot project (open this folder in Godot) |
| `smash-nine-prototype/scripts/Main.gd` | match scene root: spawning, camera, wiring; bot hooks `get_ai_*` |
| `smash-nine-prototype/scripts/match/` | `MatchDirector` (timeline, realm states, rules), `SoulGrowth` + `SoulCards` |
| `smash-nine-prototype/scripts/realms/` | `RealmCatalog` (data), `RealmLayout` (geometry), `RealmWorld` (nodes) |
| `smash-nine-prototype/scripts/ui/` | HUD and overlays |
| `smash-nine-prototype/characters/` | `common/PlayerBase.gd` + one folder per character (see `characters/README.md`) |
| `smash-nine-prototype/scripts/EnemyAI.gd` | bot brain |
| `smash-nine-prototype/tests/` | headless tests, `soak_match.gd`, `run_all.ps1` |
| `smash-nine/` | archived starter project, GDD and concept art |
| `design/` | decisions, roadmap, Codex task cards (`design/tasks/`) |
| `reports/` | Codex unit reports |

## Run

Godot is not on PATH. Console binary:
`C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe` (override with `GODOT_BIN`).

From `smash-nine-prototype/`:

- All tests + one full bot match soak: `powershell -ExecutionPolicy Bypass -File tests/run_all.ps1 [-SoakRuns 3]`
- One test: `<godot> --headless --path . -s tests/<name>.gd`
- Bot soak with telemetry: `<godot> --headless --path . --fixed-fps 60 -s tests/soak_match.gd -- --seconds=480 --seed=7 --players=8`
  (prints `[soak]` status lines and one `SOAK_RESULT {json}` line; the same seed replays the same match)
- Screenshots (windowed, not headless): `<godot> --path . -s tests/capture_screens.gd -- --out=../reports/screens`
- Web build (from repo root): `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`; serve with `node tools/serve_web.js build/web 8060`; publish with `tools/deploy_pages.ps1` (lead only: it pushes `gh-pages`)

A run fails if Godot prints `SCRIPT ERROR`, `ERROR` or `Parse Error`, even with exit code 0.

## Code conventions

- GDScript with tabs, typed variables, `preload` constants instead of `class_name`.
- LF line endings (`.gitattributes`); keep `core.autocrlf=false` in clones.
- Rules live in the component that owns them (match rules in `MatchDirector`, combat in `PlayerBase`/character scripts, geometry in `RealmLayout`). Do not patch a rule from the outside.
- Every reproduced bug gets a regression test that fails without the fix.

## Codex units

| Unit | Card | Writable paths | Status |
|---|---|---|---|
| analyst | `design/tasks/CODEX-PLAN-01.md` | none (read-only) | done — `reports/codex-plan-01/` |
| analyst | `design/tasks/CODEX-ANALYST-01.md` | `smash-nine-prototype/tests/analysis/`, `reports/codex-analyst-01/` | done — merged `052cbcb` |
| tester | `design/tasks/CODEX-TESTER-01.md` | `smash-nine-prototype/tests/playtest/`, `reports/codex-tester-01/` | done — merged `47f7158` |
| analyst + tester | `design/tasks/CODEX-RETEST-02.md` | `tests/analysis/` + `reports/codex-analyst-02/`; `tests/playtest/` + `reports/codex-tester-02/` | done — merged `379cf08`, `0378a11` |
| builder | `design/tasks/CODEX-ART-01.md` | `assets/art/realm_center/`, `tests/art_preview/realm/`, `reports/codex-art-01/` | done — merged `bb0cbe0` |
| builder | `design/tasks/CODEX-ART-02.md` | `assets/art/frey/`, `tests/art_preview/frey/`, `reports/codex-art-02/` | done — merged `bb8aa88` |
| builder × 2 | `design/tasks/CODEX-ART-03.md` | `assets/art/{yuki,nova}` / `{luna,rio}`, `tests/art_preview/chars_{a,b}/`, `reports/codex-art-03{a,b}/` | done — merged `1bb2801`, `05d7360` |
| builder × 2 | `design/tasks/CODEX-ART-04.md` | `assets/art/realm_*` (8 outer realms), `tests/art_preview/realms_{a,b}/`, `reports/codex-art-04{a,b}/` | done — merged `a2ef42d`, `8566f0f` |
| builder × 2 | `design/tasks/CODEX-ART-05.md` | `assets/art/{monsters,objects}` / `{effects,ui}`, `reports/codex-art-05{a,b}/` | done — merged `180d148`, `4186bb0` |
| builder | `design/tasks/CODEX-ART-06.md` | `assets/art/luna/luna_brave_*`, `assets/art/ui/title_logo*`, `reports/codex-art-06/` | done — merged `a1150a7` |
| builder | `design/tasks/CODEX-ART-07.md` | `assets/art/hazards/`, `reports/codex-art-07/` | done — merged `64a1df7` |
| builder × 2 | `design/tasks/CODEX-ART-08.md`, `CODEX-ART-08R.md` | `assets/art/{frey,nova,yuki}` / `{rio,luna}`, `tests/art_preview/hires_{a,b}/`, `reports/codex-art-08{a,b}/` | done — merged `7a9ab85`, `f770854`; rework `7f8f117`, `ac5ca94` |
| analyst | `design/tasks/CODEX-ANALYST-03.md` | `tests/analysis/review03/`, `reports/codex-analyst-03/` | done — merged `e0af6bf`; P1 crystal hits fixed `30043dc` |
| builder | `design/tasks/CODEX-ART-09.md` | 8 fighter sheets, `tests/art_preview/sprite_fix_a/`, `reports/codex-art-09/` | done — merged `f0f606d` (31 frames; the lead re-extracted 35 more, `bbfd473`) |
| builder | `design/tasks/CODEX-ART-10.md` | `assets/art/vfx/`, `tests/art_preview/ult_vfx_b/`, `reports/codex-art-10/` | done — merged `2685c54` |
| builder | `design/tasks/CODEX-ART-11.md` | `assets/art/{monsters,objects}/`, `tests/art_preview/monsters_v2_b/`, `reports/codex-art-11/` | done — merged `093ecba` |
| builder | `design/tasks/CODEX-ART-12.md` | 4 fighter sheets, `tests/art_preview/sprite_fix_a{2,3}/`, `reports/codex-art-12/` | done — merged `21b3682` (cells pasted), `6c09768` |
| analyst | `design/tasks/CODEX-QA-12.md` | `tests/analysis/codex_qa_12/`, `reports/codex-qa-12/` | done — merged `3821cb3`; P1 ×2, P2 fixed `906b014` |
| builder | `design/tasks/CODEX-ART-13.md` | `assets/art/attack_vfx/`, `tests/art_preview/attack_vfx_a/`, `reports/codex-art-13/` | done — merged `b171919`, in game `8eb19a6` |
| builder | `design/tasks/CODEX-ART-14.md` | `assets/art/effects/`, `assets/art/vfx/`, `tests/art_preview/fx_1x_b/`, `reports/codex-art-14/` | done — merged `ace17e1` (effects and ultimate art at 1x for the 2x combat scale) |
| builder | `design/tasks/CODEX-ART-15.md` | `assets/art/realm_*/bg_*.png`, `tests/art_preview/realm_bg_c/`, `reports/codex-art-15/` | done — merged `c9bf67e` (realm backgrounds at 1.5x) |
| builder | `design/tasks/CODEX-ART-16.md` | `assets/art/attack_vfx/`, Rio sheets, Frey sheet, `tests/art_preview/attack_vfx_2x_a/`, `reports/codex-art-16/` | done — merged `863c4e2` (attack art at 2x, Rio attack/guard rows, Frey attack 4 shield) |
| analyst | `design/tasks/CODEX-QA-14.md` | `tests/analysis/codex_qa_14/`, `reports/codex-qa-14/` | round 1 merged `d7f0c64`, round 2 retest `2729819`; round 3 retest running (`codex/bot-data-14c`) |
| analyst (debate) | `reports/debate-bot-ai/` | none (read-only, ephemeral rounds) | rounds 1–2 done, round 3 decided from the QA-14 data (`log.md`); changes `8277419`, `021c649`, `34443e3`, `ce4f0af` |
| tester | `design/tasks/CODEX-QA-15.md` | `tests/analysis/codex_qa_15/`, `reports/codex-qa-15/` | done — merged `352c244`; HUD fixes `391c555`, `2f1bfff`; art → ART-17 |
| builder | `design/tasks/CODEX-ART-17.md` | `assets/art/hazards/`, monster sheets, `assets/art/effects/yuki_seal_idle.png`, `tests/art_preview/hazard_art_17/`, `reports/codex-art-17/` | done — merged `f1092c7`, round 2 `e608d6f`; in game `5128e39` |
| analyst | `design/tasks/CODEX-QA-13.md` | `tests/analysis/codex_qa_13/`, `reports/codex-qa-13/` | done — merged `f102677`; findings fixed (see run log 2026-10-08 work) |

Units never edit product source (`smash-nine-prototype/scripts/`, `characters/`, `scenes/`, `project.godot`). Findings go to the lead.

Away routine (자리 비움 루틴): rules and run logs in `routine/README.md`.

Known sandbox noise: inside the Codex sandbox every Godot process prints `ERROR: Failed to read the root certificate store.` (os_windows.cpp). It does not happen outside the sandbox (lead runs: 0). Report it separately; every other error line still fails a run.
