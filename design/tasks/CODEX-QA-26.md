# CODEX-QA-26 · Full regression at the checkpoint

- Request (2026-10-25, relayed by the check session): one full regression run on tag `checkpoint-2026-10-25` (`main` `c51a417f`), the state the user is checking now. **Report only.**
- Base, folder, Godot, neighbours: as in `CODEX-QA-24.md` (folder `qa-b`, after QA-25). Run it with no other Godot process of yours running.

## Run
- `powershell -ExecutionPolicy Bypass -File smash-nine-prototype/tests/run_all.ps1` once (default soak: 8 bots, seed 1001), from `smash-nine-prototype/` as the script expects. Note the wall time and what else was running on the PC (`tasklist` for Godot/codex processes at start and end).
- If a test fails, run that test alone once more and say whether it fails again (flaky vs broken), with the failure lines.
- Compare the soak result with the earlier runs on the same seed: QA-22 (`reports/codex-qa-22/suite-summary.log`), SYS-09 (`reports/codex-sys-09/full-suite.log`): match length, winner, defeats, NaN positions, node count, pvp/monster hits. Flag changes bigger than seed-to-seed spread.

## Report
`reports/codex-qa-26/README.md` (Korean): pass/fail table (every test), the soak comparison, every engine error line other than the known sandbox certificate-store noise. Full output in `reports/codex-qa-26/suite.log` (trim to under 1 MB), `reports/codex-qa-26/files.txt`.

## Writable
`reports/codex-qa-26/**`.

Hard stop: 40 minutes.
