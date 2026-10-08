# CODEX-QA-13 · Independent review of the combat and realm scale change

- Request: routine 2026-10-08 work. 사용자: "캐릭터들의 공격 범위와 이펙트들이 지금보다 최소 2배씩은 더 넓어야 할 것으로 보인다 … 그렇게 넓어지면 맵도 조금 더 늘려야 할 것" · "루틴으로 시작하고, 맵 1.5배로."
- Unit: Analyst · Lead (decides and fixes): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/scale-review-13`
- **This task does not edit product source or existing tests.** It reads, measures, and reports.
- Timeout: given in the prompt.

## What changed (read `git log --oneline 9271339..HEAD` and the diffs)

`smash-nine-prototype/scripts/GameScale.gd` holds every scale: COMBAT 2.0 (attack reach and hit areas measured from the body's centre, projectiles' size and speed, special attack areas, hit and ultimate effects, bots' fighting distances), WORLD 1.5 (realm layouts through `RealmCatalog.scaled_maps()`, blast lines, hazards, bot navigation, monster distances, recovery moves), MOVE 1.2 (run speed, accelerations), jumps 1.5x higher under 1.2x gravity (JUMP_SPEED 1.3416), KNOCKBACK 1.5 (speed and decay). Fighters keep their size (1x art, 42x64 hurtbox). Realms no longer fit the view, so the camera follows and an arrow marks off-screen fighters in the same realm.

## Tasks

1. **Missed distances.** Find numbers that should have scaled and did not (or scaled twice): attack geometry built outside the shared helpers, effects that no longer match their hit area, pixel distances in bots, monsters, hazards, soul crystals, portals, spawn logic, camera, tests. For each: file:line, what it should be, and how you know (a probe that prints the mismatch is best). Note numbers that are fine as they are because they belong to the fighter's size.
2. **Reachability.** For every realm, can a fighter reach every standable platform with its jumps (ground jump + air jumps) and is every rise under the bots' `NAV_JUMP_RISE`? Write a headless probe (layout data + the fighters' jump speeds and gravity) and list any platform that became unreachable or awkward.
3. **Independent measurement.** Run `smash-nine-prototype/tests/analysis/run_sweep.ps1` on seeds 9–16 (`-FirstSeed 9 -SeedCount 8`, output under your writable path) and summarise with `sweep_summary.ps1`. The lead's baseline before the change (seeds 1–8): length median 274 s, first PvP hit median 5.9 s, eliminations player 47 / environment 3 / monster 6, wins Frey 50% Nova 38% Rio 13% Luna 0% Yuki 0%. Say what moved and whether anything looks broken (e.g. far fewer ring-outs, bots stuck, matches timing out).
4. **Feel from captures** (optional, if time): `routine/2026-10-08-work/results/screens_after*/`, `ultimates_after*/` — effects or attacks that now hide fighters or look wrong at the new size.

## Writable paths

`reports/codex-qa-13/**`, `smash-nine-prototype/tests/analysis/codex_qa_13/**`. Everything else is read-only.

## Report (`reports/codex-qa-13/README.md`, Korean)

Findings ranked (bug / balance / feel) with evidence and a suggested fix (text only), the reachability table, the measurement table next to the lead's baseline, what you could not check. Commit, or `reports/codex-qa-13/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
