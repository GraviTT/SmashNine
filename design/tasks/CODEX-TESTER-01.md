# CODEX-TESTER-01 · Real-input playtest of the M1 match flow

- Request: 사용자 "Codex와 함께 토론 후 … 프로토타입 진행" (2026-10-06). M1 is implemented; the lead wants the flow verified the way a player experiences it.
- Unit: Tester · Lead (fixes, merges): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/tester/SmashNine`, branch `codex/tester-01` (from main `db48b18`)
- Running at the same time: Codex analyst unit runs headless Godot soaks (CPU heavy). Run **one windowed Godot at a time**, and keep each run short.
- This task does not edit `smash-nine-prototype/scripts/`, `characters/`, `scenes/`, `project.godot`, or existing tests.

## Read first

1. `AGENTS.md` (run commands, Godot path)
2. `design/DECISIONS.md`, `design/ROADMAP.md` (M1 done-criteria, D14 flow)
3. `smash-nine-prototype/scripts/Main.gd` (input routing), `scripts/ui/MatchHud.gd`, `project.godot` `[input]` section (key bindings)
4. `smash-nine-prototype/tests/capture_screens.gd` (how to save a screenshot from a script)
5. `reports/screens-m1/` (the lead's own screenshots)

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `smash-nine-prototype/tests/playtest/**` | playtest driver scripts |
| `reports/codex-tester-01/**` | report, screenshots, logs |

Forbidden: product source, existing tests, docs in `design/`, `AGENTS.md`, merging, pushing, installing packages, downloads.

## Tasks

Drive the game through **real input**: `Input.parse_input_event()` with `InputEventKey` (physical keycodes from `project.godot`), pressed and released over real frames. Do not set match/player state directly to force an outcome. Reading state for assertions and measurements is fine.

1. **Start screen:** each of keys 1–4 starts a match as Frey/Yuki/Luna/Nova (P1 marker, HUD, correct realm view); key B starts a bots-only match with a spectating camera.
2. **Controls in a real match:** move, jump (W), drop through a sub platform (S S), guard (Space), J/K/L/I. Confirm the ultimate is refused during its 30 s cooldown and works again after.
3. **Portal:** walk P1 onto a portal with A/D/W and press Q. Measure the arrival point, the camera switching realm, and that no input is needed twice.
4. **Soul card:** play with a scripted input policy (e.g. approach the nearest monster and press J) until a card offer appears; choose with 1/2/3 and check the chosen card is applied; also let one offer time out (5 s auto-pick).
5. **Collapse and elimination:** stay in a corner realm through 2:30 (you may let the match run in real time or use Engine.time_scale; say which) and record what happens to P1; after P1 is eliminated, confirm the camera spectates a living fighter.
6. **Result and restart:** reach the result screen (bots-only is fine), press R, and repeat 3 times. Record node count (`Performance.OBJECT_NODE_COUNT`) at each start screen and any errors from callbacks into the previous match.
7. Screenshots at each step into `reports/codex-tester-01/`.

Rules:
- Measure before you conclude; mark guesses as guesses.
- Every finding: severity, reproduction (keys, timing, seed), numbers, screenshot, proposed fix, owning component.
- A Godot run counts as failed if it prints `SCRIPT ERROR`, `ERROR` or `Parse Error`.

## Done when

- [ ] `reports/codex-tester-01/README.md` in Korean: pass/fail per task, findings by severity, screenshots, what a human must check (feel, fun, readability), what could not be done
- [ ] Commit on the branch, or, if `.git` is not writable, `reports/codex-tester-01/commit.ps1` that adds **only** the writable paths and commits with an English message ending in `Co-Authored-By: Codex <noreply@openai.com>`
