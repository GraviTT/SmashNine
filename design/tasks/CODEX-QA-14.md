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

## Round 3 · retest (branch `codex/bot-data-14c`)

The lead changed the bots again after your round 2 (`reports/debate-bot-ai/log.md`, "Round 3"): `ce4f0af` (levels judged by where bodies stand, trading hits counts as progress, players first from the central brawl or 4 left, swings watched every frame with `attack_serial` / `attack_elapsed` / `attack_startup` and no guard more than 0.1 s past the wind-up, a cornered retreat jumps past the opponent) and `0aad85c` (Frey and Nova also use skill 1 to recover; it was not in your round 2). Rerun **the same probe on the same seeds 101–112**; give round 1 / round 2 / round 3 for every metric you reported, plus:
- no-target time, `wander`, target switches per minute, central-brawl target shares (your targets: player ≥ 90%, none ≤ 1%, switches ≤ 16/min); targets dropped by the progress rule (reason `gave up: target out of reach`) and how many of those were within 300 px or had traded hits in the 3 s before;
- per attacking character: reactions detected, reactions that ended as `too late to block`, guards raised, blocks, parries; reactions first detected in recovery (your round-2 check);
- cornered escapes (`cornered: jumping past`) per character and ring-outs within 3 s after one; Yuki ring-outs whose hit landed within 225 px of a ledge;
- misses by distance at the swing (0–120, 120–240, 240–360, 360+ px) and by target kind, per character — Rio first (its side basics fell 45.2% → 27.4%);
- recovery success per character, and skill-1 recoveries (Frey, Nova, Rio): used, reached a floor;
- match length per seed; anything that got worse.

Reading `ai_controller` members per physics frame from the probe is fine (read only). Same writable paths; report in `reports/codex-qa-14/round3.md`.

## Round 4 · final retest (branch `codex/bot-data-14d`)

After your round 3 the lead changed the bots again (`reports/debate-bot-ai/log.md`, "Round 4"): `2811081` (a cornered kiter holds the ledge when the opponent is on another level) and `b4a83d7` (progress counts hits on monsters and crystals via `last_attacker` / `last_hit_frame`, close targets with a route are kept, escapes at most every 2.5 s and only with floor past the opponent, Nova/Rio recovery skill only within reach, a guard still rises against a close attacker facing us, Rio's basics need the target within 240 px). Rerun **the same probe on the same seeds 101–112** and give R1 / R2 / R3 / R4 for every metric, plus:
- progress drops by target kind with your round-3 split (within 300 px, traded hits in the 3 s before);
- guards per attacker: reactions, too late, raised, blocks, parries — and blocks of a combo's 2nd/3rd swing if you can tell them;
- escapes per character and ring-outs within 3 s after one; Yuki side-basic hit rate and misses by distance;
- Rio: side-basic attempts and hit rate by distance, PvP damage per minute (round 3: 41.8), wins;
- recovery skill 1 (Frey, Nova, Rio): used, reached a floor; Frey's recover-state share and where Frey enters recovery (knocked off / walked or dashed off / other);
- central-brawl target shares and recover share; match length per seed; anything worse.

Same writable paths; report in `reports/codex-qa-14/round4.md`; commit script `commit-round4.ps1`. Say plainly for each lead change whether the data supports keeping it.

## Round 5 · confirmation (branch `codex/bot-data-14e`)

The lead's round-5 commit `bbee6b2` (`reports/debate-bot-ai/log.md`, "Round 5") follows your round-4 verdicts: close targets with a route get one extra progress window on a fresh route, Nova's recovery skill is back to "from anywhere" (Rio keeps 290 px), recovery skills are asked once per recovery, and a bot holding a ledge while its escape cools down guards early half the time. Rerun **the same probe on the same seeds 101–112**; give R3 / R4 / R5 for every metric, and say for each round-5 change whether the data supports it. Watch especially: no-progress time (R4 1,103.5 s), recovery-skill asks vs uses and floors reached (Nova, Rio), intent hit rate, Yuki ring-outs after hits near a ledge (R4 13), central-brawl targets, match length, Rio wins. Same writable paths; report `reports/codex-qa-14/round5.md`; commit script `commit-round5.ps1`.

## Round 6 · confirmation (branch `codex/bot-data-14f`)

The lead's round-6 commit `16ae156` (`reports/debate-bot-ai/log.md`, "Round 6"): the close-target extension is removed (hits on the target still count as progress), recovery skills are asked whenever they can start (`PlayerBase.can_use_skill_one()`, Rio's one blink per airtime) instead of once per recovery, and Yuki's basics need the target within 480 px. Rerun **the same probe on the same seeds 101–112**; give R3 / R4 / R5 / R6 for every metric and a keep/revert verdict per change. Watch: no-progress time and 20 s+ standoffs (targets: R3 levels, ≤ 3.4% and ≤ 2), recovery-skill asks vs uses and floors reached for Frey (R3 18/19, R5 6/13), Nova, Rio, ring-outs and recovery success, Yuki side-basic hit rate and PvP damage per minute, match length and range. Same writable paths; report `reports/codex-qa-14/round6.md`; commit script `commit-round6.ps1`.

## Round 7 · last measurement this session (branch `codex/bot-data-14g`)

The lead's round-7 commit `089154d` (`reports/debate-bot-ai/log.md`, "Round 7"): Nova's `can_use_skill_one()` knows its one vector shift per airtime, and every fighter uses its recovery skill at most twice per recovery. Rerun **the same probe on the same seeds 101–112**; give R5 / R6 / R7 for every metric and a keep/revert verdict per change. Watch: recovery-skill asks vs uses and floors reached (Frey R6 437 uses, Nova 35,321 asking frames / 27 uses, Rio 8/8/4), recovery success and ring-outs per character, no-progress time and standoffs, progress drops (R6 318, 98 close or just hit), match length. Same writable paths; report `reports/codex-qa-14/round7.md`; commit script `commit-round7.ps1`. End with the open items you would hand to the next session.

## Round 8 · attacks x1.5 and the next-session items (branch `codex/bot-data-14h`)

Since your round 7: the user played and cut attack reach and effects from x2 to **x1.5** (`GameScale.COMBAT`, commit `c8f5d98`; maps unchanged, bots' fighting distances follow the same constant), and the lead's round-8 dead-band fix (`d5bcea1`: a same-level target counts as progress only while the way toward it is open) is not measured yet. Rerun **the same probe on the same seeds 101–112** and give R7 / R8 for every metric (say which differences the scale change alone can explain), then the items you listed for the next session (`reports/debate-bot-ai/decision.md`):
1. **Dead band:** seed 112 and every seed — engage episodes over 5 s with no move and no attack (positions, gap width, distance); at x1.5 Frey's reach is 300 px, so other distances may form one.
2. **Close or just-hit drops:** split by cause — no route at all, route exists but not followed (stuck, gap with no landing, wrong level reached), target moved away, other.
3. **Frey's failed recoveries:** did the second dash shorten the distance to the ledge?
4. **Zero-jump ring-outs:** where the jumps went before the ring-out (spent in this recovery, spent climbing, spent in combat jumps, knocked off during an air attack, other).
5. **Yuki ledge ring-outs** and **central-brawl monster targets** (R7 13 and 13.3%).
6. **Hit rate by start distance** per character at x1.5 (bins of 60 px), to check the basic-reach limits still fit (Rio 120 × 1.5 = 180 px, Yuki 240 × 1.5 = 360 px).

Same writable paths; report `reports/codex-qa-14/round8.md` (Korean); commit script `commit-round8.ps1`. End with a ranked list of fixes with the numbers behind each.

## Round 9 · routes and targets (branch `codex/bot-data-14i`)

The lead's round-9 commit `1b79472` (`reports/debate-bot-ai/log.md`, "Round 9") follows your round-8 list: the route planner uses the platform rects and only links platforms across gaps the movement can cross (NAV_GAP_JUMP ≈ 172 px, drops 300 px), a jump up starts within 165 px of the waypoint's platform, the blocked-way rule applies only out of attack range, a monster only after us is not progress, and nobody kites from a crystal. Rerun **the same probe on the same seeds 101–112** (attacks x1.5 as in R8) and give R8 / R9 for every metric with a keep/revert verdict per change. Watch: close drops by cause (R8 88: wrong level 51, gap 35) and all drops (390), Yuki's central-brawl targets and PvP damage per minute (R8 42.1% monsters, 27.05), input-less engages over 5 s, stuck time, standoffs, match length, ring-outs and recovery. Also split recovery entries by cause (walked or dashed off a ledge, air-down, knocked off, other; R8 2,185 episodes). Same writable paths; report `reports/codex-qa-14/round9.md` (Korean); commit script `commit-round9.ps1`.

## Round 10 · falls and idle engages (branch `codex/bot-data-14j`)

The lead's round-10 commit `01471d7` (`reports/debate-bot-ai/log.md`, "Round 10"): recovery starts only when no floor lies under the fall path (probes now and 0.25 / 0.5 / 0.8 s ahead along the horizontal speed), and the blocked-way rule spares a bot that attacked within 2.5 s instead of one merely within attack range. Rerun **the same probe on the same seeds 101–112** and give R9 / R10 for every metric with a keep/revert verdict per change. Watch: recovery entries by cause (R9 2,386: self 1,840, knocked 490), air jumps left at ring-outs, ring-outs and recovery success, input-less engages over 5 s (R9 4), standoffs (R9 6), no-progress time (R9 993.5 s), drops by cause, no-route cases (R9 71), match length. Same writable paths; report `reports/codex-qa-14/round10.md` (Korean); commit script `commit-round10.ps1`.

## Round 11 · fall arc (branch `codex/bot-data-14k`)

The lead's round-11 commit `84bb424` (`reports/debate-bot-ai/log.md`, "Round 11"): the fall check follows the arc itself (fall gravity, speed cap, horizontal speed kept, 10 steps of 0.1 s) and counts a landing only where the arc meets a floor. Rerun **the same probe on the same seeds 101–112** and give R10 / R11 for every metric with a keep/revert verdict. Watch: ring-outs (R10 108) and zero-jump ring-outs (R10 71; Nova 28, Rio 6), held-off falls that turned into late recoveries (R10 162 of 332), recovery entries by cause (R10 1,346; self 798), recovery success, input-less engages, standoffs, no-progress time, match length. Same writable paths; report `reports/codex-qa-14/round11.md` (Korean); commit script `commit-round11.ps1`. End with the open items for the next session, ranked, with numbers.

## Round 12 · steered fall check (branch `codex/bot-data-14l`)

The lead's round-12 commit `0af5f57` (`reports/debate-bot-ai/log.md`, "Round 12") answers your round-11 verdict with the hybrid you suggested: the arc follows the fighter's current move input with its air acceleration up to run speed (gravity and speed cap as before) and casts at both feet and the centre, recomputed every 0.1 s. Rerun **the same probe on the same seeds 101–112** and give R10 / R11 / R12 for every metric with a keep/revert verdict; repeat your R10-vs-R11 fall comparison for R12 (accepted falls that landed, rejected falls that landed, accepted falls that did not). Watch: ring-outs and zero-jump ring-outs per character, recovery entries by cause and success, match length, no-progress time, hit rate, input-less engages, standoffs. Same writable paths; report `reports/codex-qa-14/round12.md` (Korean); commit script `commit-round12.ps1`. End with the ranked open items for the next session, with numbers.
