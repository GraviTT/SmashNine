# CODEX-QA-21 · Bug hunt in the new systems (menus, story, monsters, realm gimmicks, Korean/English)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 5 (QA lane).
- Unit: Analyst. Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/qa-21` (from the latest main).
- Running at the same time:
  - ART-71, ART-72 and ART-73 (art, in other clones)
  - **You are the only unit running Godot.** The lead may run the test suite briefly.
- **Report only.** You do not change product code; the lead reproduces and fixes.
  - Not in scope: story difficulty and balance (CODEX-QA-20 waits for the user's own play), and skill balance (the skill session).

## Read first
- `AGENTS.md`
- `design/DECISIONS.md` D41–D43
- the run records under `routine/`
- the reports `reports/story-mode-plan-2026-10-22.md` and `reports/codex-sys-0*/`
- `tests/run_all.ps1`

## What to hunt (in this order)
1. **Story mode, stages 1–9**: drive each stage headless with scripted input or bots, through dialogue, fight, exit portal, result and map, and the save/continue path. Look for:
   - softlocks (a stage that cannot be finished or left)
   - lost or duplicated saves
   - a portal or checkpoint that does not work
   - a scene that never ends
   - the HUD showing during scenes
   - the ending not reachable for each of the five heroes
2. **Menus** (`FrontendMenu.gd`): title → character select (every character and body) → options (language switch both ways, game speed) → match → results → restart or back, repeated. Look for:
   - focus or input dead ends
   - a node that stays after leaving a screen (count nodes per cycle, as `test_restart` does)
   - a button that does nothing
3. **Monsters** (D41): every archetype and elite in every realm. Look for:
   - a monster stuck in a wall or off the map
   - a wind-up with no attack after it, or an attack with no wind-up
   - an elite that never respawns
   - spawn counts outside the rules
   - the six-row art path (SYS-06) used with the old sheets by mistake
4. **Realm gimmicks** (moon gates, forge belts): fighters, bots and monsters all use them. Look for:
   - a fighter trapped or teleported out of bounds
   - a bot that loops on a gate
5. **Korean/English**: switch the language on every screen. Look for:
   - a text that does not change (not through the translation table)
   - text cut off or overflowing its box in either language (measure the label against its rect)
   - a missing key shown as the key name
6. **Web build size and first load**: build sizes by file type. Find what makes the first load heavy, and what could be smaller without a visible change. Measure only; do not change the export.

## Every finding
- severity (상/중/하)
- exact repro: a script under `tests/analysis/codex_qa_21/` that shows it, plus the seed and frame or time
- what is measured vs guessed
- the component that owns it, and the likely fix location (file:line)

## Output
- `reports/codex-qa-21/README.md` (Korean): findings strongest first (at most 25), then what you covered and what you could not.
- the scripts
- `commit.ps1`:
  - only your files
  - no `git add -f`
  - no `__pycache__`

## Writable
`tests/analysis/codex_qa_21/**`, `reports/codex-qa-21/**`.

Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Hard stop: 150 minutes.
