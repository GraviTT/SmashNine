# CODEX-QA-22 · Retest QA-21, and measure the sound wiring in real matches

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 5 (QA lane).
- Since QA-21 the lead fixed the moon gate exits (`c52d784`: `RealmCatalog` spots on platform tops) and the ultimate cut-in over story dialogue (`21a7629`), and merged the sound wiring (SYS-05, `7035d83`: `scripts/audio/`, 71 sound ids, only the watched realm is heard, `design/AUDIO.md`) and the projectile strip wiring (SYS-07).
- No sound files are in the game yet (the user has not picked a style), so nothing is audible. The sound code still runs: every request is counted. That lets us measure what the player **would** hear.
- Unit: Analyst. Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/qa-22` (from the latest main). **You are the only unit running Godot.**
- **Report only.** You do not change product code; the lead fixes.

## 1. Retest QA-21 with the same inputs
Run your QA-21 repros again (`tests/analysis/codex_qa_21/gate_geometry.gd`, `story_cutin.gd`, and the gate soak seeds 2105/2106) on the latest main. A before/after table per finding: the QA-21 numbers, the numbers now. Say plainly if anything is not fixed.

## 2. What the player would hear (the sound wiring)
Use the manager's probe (`probe_enabled`, request counts, `world_probe`) with a recorder of your own (a script under `tests/analysis/codex_qa_22/`, no product edits). Runs: 8 bots × 3 seeds (battle royale, the camera spectating as in `soak_match.gd`), and story stages 1, 5 and 9 driven as in QA-21.
- Per second of match time, for the **watched realm only** (requests that would play): the count per id, the peak number at once, the busiest 5 seconds of each run.
- Ids that would fire more than 8 times in one second, or more than 3 voices of one id at once: name them with the moment (seed, time) — the lead tunes the caps.
- Ids that never fire in a whole run, and why (a hook that cannot be reached, or an event that did not happen).
- Requests from other realms that were filtered, per run; `no_realm` must be 0.
- Music: which track is asked for on each screen (title, select, battle, story, results) and whether it changes when it should.
- Errors: any `SCRIPT ERROR` or audio warning in the logs.

## 3. Regression
- The full suite `tests/run_all.ps1` once.
- The soak stats against QA-21 (match length, defeats, NaN positions, node counts, monster hits). Flag any change bigger than the seed-to-seed spread.

## Every finding
- severity (상/중/하), exact repro (script, seed, time), measured vs guessed, the owning component and the likely fix location (file:line).

## Output
- `reports/codex-qa-22/README.md` (Korean): the retest table first, then the sound measurements (tables, and one chart of requests per second over a match for one seed), then the regression.
- The scripts under `tests/analysis/codex_qa_22/`.
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no logs over 1 MB.

## Writable
`smash-nine-prototype/tests/analysis/codex_qa_22/**`, `reports/codex-qa-22/**`.

Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Hard stop: 150 minutes.
