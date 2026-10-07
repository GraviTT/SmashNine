# Smash Nine Realms — agent guide

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

Units never edit product source (`smash-nine-prototype/scripts/`, `characters/`, `scenes/`, `project.godot`). Findings go to the lead.

Away routine (자리 비움 루틴): rules and run logs in `routine/README.md`.

Known sandbox noise: inside the Codex sandbox every Godot process prints `ERROR: Failed to read the root certificate store.` (os_windows.cpp). It does not happen outside the sandbox (lead runs: 0). Report it separately; every other error line still fails a run.
