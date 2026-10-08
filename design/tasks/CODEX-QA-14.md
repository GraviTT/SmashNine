# CODEX-QA-14 · Bot behaviour data and a debate on making bots smarter

- Request: 사용자 2026-10-08 "봇 문제는 현재 밝혀진 것들을 Codex와 토론하여 해결하고, 더 똑똑하게 만들어 볼것." · "Codex에게 데이터를 모으게 할것."
- Unit: Analyst · Lead (decides and implements): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/bot-data-14`
- Running at the same time: three Codex art builders. **This task does not edit product source or existing tests.** You measure, argue, and report; the lead decides and changes the bots, then you measure again in a second round.
- Timeout: given in the prompt.

## Where things stand

- Bot brain: `smash-nine-prototype/scripts/EnemyAI.gd` (states wander / pursue / engage / portal / recover; engage actions approach / retreat / cross / jump_in / hold; attack choice in `_choose_attack`; targeting in `_find_target`; navigation graph and `_terrain_move_intent`). Fighters: `characters/common/PlayerBase.gd` + one folder per character.
- New today: `EnemyAI.debug_snapshot(player)` returns state, engage action, target (kind, name, offset), last intent (move, jump, attack), stuck timer, portal destination and a short reason. The in-game panel (F4) shows it live. **Use it for your data.**
- Scales changed today (`scripts/GameScale.gd`, decision D27): attacks x2, realms x1.5, run x1.2, jumps 1.5x higher, knockback 1.5x. A frozen-bot bug after collapse relocation was fixed (`19be834`).
- Lead's 16-match sweep after the change (`routine/2026-10-08-work/results/sweep_after_16_summary.txt`): length median 307 s, first PvP 6.4 s, ring-outs 11.9 per match (9.3 before), wins Frey 25 / Rio 31 / Nova 19 / Luna 13 / Yuki 13 %.

## Known problems and the lead's proposed fixes (argue with these)

| # | Problem (evidence) | Lead's proposal |
| --- | --- | --- |
| 1 | Bots only aim attacks horizontally: `PlayerBase._get_attack_direction()` uses `facing` for bots (y = 0), so they never use up / down / air-up / air-down attacks even when the target is right above or below; skills read `ai_controller.aim_direction`, which the bot sets only while recovering. | Bots set `aim` toward the target every attack (choose up/down/side by the target's offset and the move's reach), and skills aim at the target. |
| 2 | Bots never guard or parry (no guard intent at all). | Guard when an opponent in reach is starting an attack (its `attack_lock_timer` just started) with a reaction chance and delay; parry window is 0.1 s (`GUARD_PARRY_WINDOW`). |
| 3 | Since the air-jump climb was added (`7112be5`), ring-outs rose 9.3 → 11.9 per match: bots spend air jumps on rises and then cannot recover. | Climb with an air jump only when at least one air jump stays in reserve, or only when the rise cannot be reached otherwise. |
| 4 | Bots keep chasing a target on another level they cannot reach (seen: a bot "engaging" a monster 200 px below for minutes); early-phase penalty (`PASSIVE_PLAYER_PENALTY`) makes them farm monsters. | Drop a target after N s without progress (distance not shrinking, or another level) and ignore it for M s; when few fighters remain, prefer players. |
| 5 | Nova's ultimate slingshot launch direction is never aimed by bots (the launch flies along the orbit tangent; the redirect is skill-one during the launch). | Launch when the tangent points at the target, or redirect toward it. |
| 6 | Ultimates are used at random (45% when an attack fires in range). | Use when it will hit: target in its area, more than one target, or the target is low. |
| 7 | Low-HP bots leave through portals (`_should_disengage`); with bigger realms this may drag fights or save them. | Keep, unless the data says it mostly drags matches. |

## Tasks

1. **Collect data.** Write a headless probe under your writable path that runs bot matches (same setup as `tests/analysis/analysis_soak.gd`; `--fixed-fps 60`) and samples every bot's `debug_snapshot()` every 0.25 s plus damage / ring-out / elimination events (the `damaged`, `defeated` signals; ring-outs via `damaged` with source "environment"). At least 12 matches (seeds 101–112), one run at a time. Report per character and per match phase:
   - share of time in each state and engage action; time "stuck" (stuck timer ≥ 0.5 s while moving) and where (realm, position) — list the worst spots;
   - target kind shares (player / monster / crystal) by phase; target switches per minute; time spent on targets that never got closer (another level, unreachable);
   - attack usage by type and its hit rate (attacks that dealt damage within 0.4 s), damage per minute;
   - ring-outs: who was knocked, whether they had air jumps left, recovery success rate;
   - portal use, collapse escapes vs relocations, low-HP disengages and what followed;
   - standoffs: two or more fighters alive in the same realm with no damage between them for 20 s+.
2. **Debate.** For each of the 7 proposals: agree / disagree / change, with evidence from your data or a precise trace through the code, and the expected effect. Add up to 5 problems or fixes the lead missed, ranked by impact on how smart and fun the bots are. Be concrete (thresholds, which function, which signal).
3. **Leave the probe reusable**: one command that prints the same summary for a second round after the lead's changes.

## Writable paths

`reports/codex-qa-14/**`, `smash-nine-prototype/tests/analysis/codex_qa_14/**`. Everything else is read-only.

## Report (`reports/codex-qa-14/README.md`, Korean)

Data tables first, then the debate (one row per proposal: verdict, evidence, suggested change), then your extra findings, then how to rerun the probe. Commit, or `reports/codex-qa-14/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.

## Round 2 · retest (branch `codex/bot-data-14b`)

The lead changed the bots after your round 1 and the debate (`reports/debate-bot-ai/`): commits `8277419`, `021c649`, `41e8f94` (Yuki talisman engine error), `34443e3` (portal stays, retreat only to empty realms, gated skills, players first from 4 left). Rerun **the same probe on the same seeds 101–112** and give a before/after table for every metric of round 1, plus:
- per attacking character: guard reactions triggered, guards raised, blocks/parries achieved, and any reaction guard first detected while the attacker was already in recovery (debate D3);
- up/down/air-up/air-down attack use and hit rates per character; self ring-outs right after an air-down;
- Nova ultimate: launches forced at the time limit vs aimed, redirects, hit rate;
- ring-outs with 0 air jumps left, recovery success per character;
- portal moves per match and why (escape, roam, retreat, off-screen hop);
- anything that got worse. Same writable paths; report in `reports/codex-qa-14/round2.md`.
