# CODEX-ANALYST-01 · M1 diff review and balance sweep

- Request: 사용자 "Codex와 함께 토론 후 … 프로토타입 진행" (2026-10-06). M1 is implemented; the lead wants independent verification before calling it done.
- Unit: Analyst (diff review adversarial + exploit/balance search) · Lead (fixes, merges): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/analyst-01` (from main `db48b18`)
- Running at the same time: Codex tester unit (`codex/tester-01`) drives a windowed Godot with real input. **Do not start windowed Godot**; headless only. Run at most one Godot process at a time.
- This task does not edit `smash-nine-prototype/scripts/`, `characters/`, `scenes/`, `project.godot`, or existing tests.

## Read first

1. `AGENTS.md` (run commands, Godot path)
2. `design/DECISIONS.md` (D1–D14 + the rule numbers), `design/ROADMAP.md` (M1 done-criteria)
3. `reports/codex-plan-01/README.md` (your earlier review)
4. The M1 diff: `git diff 97130b3 db48b18 -- smash-nine-prototype`
5. Key files: `scripts/match/MatchDirector.gd`, `scripts/match/SoulGrowth.gd`, `scripts/match/SoulCards.gd`, `scripts/Main.gd`, `characters/common/PlayerBase.gd`, `scripts/EnemyAI.gd`, `scripts/realms/*.gd`, `tests/soak_match.gd`

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/tests/analysis/**` | sweep scripts, runners |
| `reports/codex-analyst-01/**` | report, CSV/JSON data |

Forbidden: product source, existing tests, docs in `design/`, `AGENTS.md`, merging, pushing, installing packages, downloads.

## Tasks

1. **Diff review (adversarial).** Real defects only: wrong conditions, missing reset on restart (`get_tree().reload_current_scene()`), callbacks into freed nodes (SceneTreeTimers, `await` in characters, tweens), state leaks between matches, rule mismatches between two code paths (e.g. ring-out vs collapse vs sudden death damage, protection, KO credit), soul thresholds crossing in one call, card effects stacking, ultimate cooldown vs follow-ups (Nova stages, Luna laser), AI using stale realm geometry after a portal/collapse. For each: severity, file:line, evidence/repro, fix, owning component.
2. **Balance and exploit sweep.** Use the real rules: `tests/soak_match.gd` (`--seed`, `--players`, prints `SOAK_RESULT {json}`; same seed = same result). Run at least 30 seeds with 8 players (about 1 min wall each; run them sequentially). Report: match length distribution (P10/median/P90, % ended by last survivor vs final judgment), winner share per character (expected 25% each), elimination causes, first PvP hit, soul pick timing and which cards get taken, ring-outs per life. Find (a) anything abnormally strong and (b) any mechanic that never pays off (a card nobody benefits from, a phase where nothing happens). If a wrapper script helps (e.g. a seed loop writing CSV), put it under `tests/analysis/`.
3. **16-player check.** 5 seeds with `--players=16`: does it finish, wall-time per simulated second (performance signal), any errors.

Rules:
- Call the real rule code; never change the rules. Separate **measured** from **guessed**.
- Every finding: severity, reproduction (seed, time, players), numbers, proposed fix, owning component (ownership checklist: is the fix there or a workaround elsewhere?).
- A Godot run counts as failed if it prints `SCRIPT ERROR`, `ERROR` or `Parse Error`.

## Done when

- [ ] `reports/codex-analyst-01/README.md` in Korean: results table, findings by severity, balance table, what a human must check, what could not be verified
- [ ] Commit on the branch, or, if `.git` is not writable, `reports/codex-analyst-01/commit.ps1` that adds **only** the writable paths and commits with an English message ending in `Co-Authored-By: Codex <noreply@openai.com>`
