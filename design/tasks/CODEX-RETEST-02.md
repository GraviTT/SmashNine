# CODEX-RETEST-02 · Before/after retest of the analyst-01 and tester-01 fixes

- Request: 사용자 "Codex와 함께 토론 후 … 프로토타입 진행" (2026-10-06). Lead fixed the findings of CODEX-ANALYST-01 and CODEX-TESTER-01; this card re-runs the same inputs.
- Units: analyst (branch `codex/analyst-02`) and tester (branch `codex/tester-02`), each in its existing clone, both from the latest main. Lead: Claude.
- Fix commits to test: see `git log --oneline 052cbcb..HEAD` (restart/freeze `2bba7b1`, analyst fixes `17fa35f`, and any balance commit after them).
- Known environment noise: in the Codex sandbox every Godot process prints `ERROR: Failed to read the root certificate store.` (os_windows.cpp). It does not occur outside the sandbox. Count it separately and report every **other** error line; do not hide it in scripts.

## Writable paths

| Unit | Paths |
| --- | --- |
| analyst | `smash-nine-prototype/tests/analysis/**`, `reports/codex-analyst-02/**` |
| tester | `smash-nine-prototype/tests/playtest/**`, `reports/codex-tester-02/**` |

Forbidden: product source, existing tests outside those folders, `design/`, `AGENTS.md`, merging, pushing, installing, downloads.

## Analyst tasks

1. Re-run your `rule_probes.gd` probes (collapse_last_two, freeze after finish, relocation during start-up, mirror pairs, Last Stand stacking, auto_picked) and give a before/after table against `reports/codex-analyst-01`.
2. Re-run the 8-player sweep on seeds 1–30 with `tests/analysis/run_sweep.ps1` and compare with your 30-seed baseline: length P10/median/P90, % under 300 s, phase reach, finish reasons, winner share per character, elimination causes, Yuki card count. `tests/analysis/sweep_summary.ps1 -Jsonl <file>` prints a one-screen summary.
3. Diff review of `052cbcb..HEAD` for new defects (adversarial; ownership checklist).

## Tester tasks

1. Re-run `real_input_restart.gd` with 10 restarts: errors other than the certificate line, node count per start screen, result screen consistency (winner alive, Alive count frozen).
2. Re-run `real_input_core.gd`; also confirm the start screen no longer shows the match HUD through the overlay, and that the opening pair in P1's realm is a different character.
3. Screenshots of the result screen and start screen.

## Done when

- [ ] `reports/codex-<unit>-02/README.md` in Korean with the before/after table, what is still open, what a human should look at
- [ ] Commit, or a commit script that stages only the unit's writable paths (message ends with `Co-Authored-By: Codex <noreply@openai.com>`)
