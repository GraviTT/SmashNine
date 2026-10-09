# Debate log: bot AI (lead replies to Codex's attack round)

Round 1 attack: `attack.md`. Lead = Claude. Each point: accept / partly / reject.

| ID | Verdict | Reply |
| --- | --- | --- |
| D1 | **accept** | Strongest form: a bot standing over a platform spends its only air jump to climb, gets hit sideways mid-air and has no jump to come back; most fighters have one air jump (`PlayerBase.gd:206-208`), so "floor below" does not protect recovery. Change: the climb air jump only when `air_jumps_left >= 2`; route planning's rise limit drops from 185 x JUMP_HEIGHT to 125 x JUMP_HEIGHT (187.5 px, under every fighter's single-jump height 198–234 px from QA-13), so routes never need the air jump. Measure ring-outs on the same 16 seeds. |
| D2 | **accept** | `_try_start_guard()` reads the guard direction from `Input` (`PlayerBase.gd:443-456, 490-499`), so a bot guards toward `facing` and fails against an attacker behind it. Change in the owner (`PlayerBase`): bots pass a guard direction (`ai_controller.guard_aim`) that `_update_guard_direction_from_input()` uses; EnemyAI sets it toward the attacker. Regression test for a guard against an attack from behind. |
| D3 | **partly** | Strongest form: `attack_lock_timer` covers start-up + recovery, and fast moves go active after 0.045–0.05 s, so a 0.14–0.24 s reaction can never block them; the fastest characters become unblockable and fairness suffers. I keep the reactive model on purpose: a human cannot react to a 0.05 s jab either, and exposing `time_to_active` would make bots read the future. Added instead: an **anticipatory guard** (an opponent within its reach, facing us, and we are not attacking: 15% per decision to raise guard for 0.25–0.4 s), which a human does too. Per-character guard chances / success rates go to the round-2 measurement; if a character's attacks are blocked far less, revisit. |
| D4 | **accept** | Correct geometry: the core pulls the target to its centre (`Nova.gd:332-337, 421-426`) and the launch is the orbit's tangent (`Nova.gd:468-472`), so the direction to a pulled target is ~90° off the tangent and the aim condition never holds. Change: if the target is inside the collapse radius of the core, the collapse hits it, and the launch just waits until the tangent points toward the realm's floor centre (a safe landing, within 30°, forced at 0.8 s); otherwise aim at the target as before. |
| D5 | **partly** | The bot already calls `player.skill_one()` directly (it handles the follow-up before the lock check, `PlayerBase.gd:666-670`), not through `_apply_intent`, with `aim_direction` set just before. Added: a regression test that a bot-driven Nova launch redirects toward its target. |
| D6 | **partly** | Agree a fixed chance is not "when it lands", and the score is better. Per-character adjustments added: Luna's ultimate is a 6 s transformation (worth it with HP ≥ 50%: +1), Yuki's ward needs targets that stay (+1 when the target is stunned/swinging already counts), Rio's swords auto-aim at range (reach 900 px already). Not adding more until the measurement shows per-character ultimate hit rates. |
| D7 | **accept** | `air_down` is a committing dive for Nova (meteor kick) and Rio; aiming it at a target below a ledge throws the bot away. Change: in the air, aim down only when there is floor below (`_over_void()` false and `_has_drop_landing`), otherwise sideways. |
| Lead #7 | (Codex agrees with the lead) | Kept the stricter hybrid already written: no retreat when aggression ≥ 0.8 or ≤ 2 fighters alive; otherwise under 30% HP, only toward a stable realm, at most every 10 s. |

Also found by the lead while reading for this debate (not raised by Codex): since attacks doubled, the **engage band's height** went 150 → 300 px (`_is_in_engage_band`), so a target on a lower level counts as "engage", and engage never steps off a ledge (`_terrain_move_intent(..., allow_drop=false)`) — the bot stands on the edge above it (the "monster 200 px below for minutes" symptom). Change: in engage, walk off toward a target below when there is a landing (`_has_drop_landing`).

Factual questions for measurement (round 2, CODEX-QA-14 probe, same seeds): ring-outs per match and recovery success; up/down attack use and hit rates; guard opportunities and success per character; Nova launch timeouts and hit rates; time on unreachable targets; match length.

## Round 2 (Codex: `round-2.md`) — lead replies

| ID | Verdict | Reply |
| --- | --- | --- |
| D5, D6 | closed | Codex conceded (direct `skill_one()` path with a test; the opportunity score replaced the fixed chances). |
| D3 | **accept the implementation bug** | Strongest form: `_new_attack_threat()` was not called while the bot waited or guarded, so a swing that started meanwhile was recorded late and its recovery could later be taken for a new swing (`attack_lock_timer` covers start-up and recovery). Fixed: opponents are watched every frame, also while guarding. The reactive model itself stays; per-character detection → guard → block numbers are the round-2 measurement (QA-14 retest). |
| N1 | **accept** | The guard aim dropped the vertical part, so an attacker straight above or below fell back to `facing` and the cardinal check failed. Fixed: guard along the main axis toward the attacker; test `test_bot_brain` guards an attacker above. |
| N2 | **accept** | A guarding bot returned before applying an intent, so its last `move_input` kept pushing. Fixed: a neutral intent is applied while guarding; test checks `move_input == 0`. |

Still open: D3 (measurement: does any attacker become unblockable, any reaction guard first detected in recovery).

## Round 3 (measurement: Codex QA-14 round 2, `reports/codex-qa-14/round2.md`) — lead decisions

Same seeds 101–112, bots of `34443e3` (before `0aad85c` recovery skills). Better: portal moves 94.3 → 20.9 per match, time on unreachable targets 7.0% → 2.3%, 20 s+ standoffs 5 → 1, ring-outs 143 → 135, zero-jump ring-outs 78.3% → 71.1%, 3,299 up/down attacks (none before), Nova launches aimed 56/56 (75% followed by PvP damage), guards raised 2,008 with 463 blocks or parries. Worse: match median 305.7 → 315.4 s, no-target time 2–3% → 8–11%, target switches 13–15 → 19–21 per minute, central-brawl player targets 86.5% → 75.2%, Rio hit rate 32.7% → 26.7%, Yuki recovery 85.4%.

| ID | Verdict | Decision |
| --- | --- | --- |
| D3 | **closed by measurement, fixed** | At least 26 reaction guards began while the attack was already in recovery (Luna 9, Yuki 11). Two causes in the watcher, not the reaction model: (1) the bot did not watch swings while in hitstun (`update()` returned first), so a swing that began meanwhile looked new afterwards; (2) a fighter not yet a valid candidate (another realm, inactive) was skipped before being recorded. Fixed: swings are watched at the top of `update()` every frame and recorded before any filter; `PlayerBase` exposes what a player sees of a swing (`attack_serial`, `attack_elapsed`, `attack_startup`, the wind-up pose), and a reaction that ends more than 0.1 s past the wind-up raises no guard ("too late to block"). Reading the wind-up is fair (it is on screen); no future timing is read. |
| R1 (Codex top 1) | **accept, root cause found** | The rise in no-target time and switches is a lead bug from round 1: "another level" was judged by the target's height, and jumps are 1.5x higher now, so a target that jumped during a close fight was dropped after 2.5 s without getting closer (it cannot get closer when already in reach), and the route check rejected airborne or launched candidates and ignored them for 5 s. Fixed: levels are judged by where bodies stand (the floor under an airborne one; over the void counts as neither), trading hits counts as progress, and from the central brawl (aggression 1.0) or 4 left, monsters and crystals sort after every player. Tests: a jumping target in a close fight is kept and still chosen (fails on the old brain). |
| R2 (Codex top 2) | **partly** | Yuki kites (retreat 38% of engage time) and the retreat stops at the ledge, where a 1.5x knockback sends it off. Change: a retreating bot with a ledge within 225 px behind it jumps past the opponent instead ("cornered: jumping past"); test included. No Yuki-only recovery policy yet: 0 jumps at ring-out is expected after a failed recovery, so the next measurement looks at Yuki's ring-outs that start at a ledge. Rio's single self ring-out after air-down: kept as a measurement item (one case in 227 dives). |
| R3 (Codex top 3) | **accept in a narrower form** | Guards react to the observable swing start (serial) and wind-up, as above; no separate `became_active` signal, because the wind-up length is what a player sees and the 0.1 s grace covers the active part of every basic. |
| Rio hit rate | **measure** | Rio's attack count rose 4,043 → 5,156 and side basics fell 45.2% → 27.4%. Candidates: basics thrown from up to its 460 px profile range while its slashes reach about 240 px, or more swings at monsters. Round 3 measures Rio's misses by distance and target kind before changing it. |

Next: Codex QA-14 round 3 (same probe, same seeds) on the new bots; `decision.md` after it.

## Round 4 (measurement: Codex QA-14 round 3, `reports/codex-qa-14/round3.md`) — lead decisions

Bots of `ce4f0af` (round 3) plus `0aad85c` (Frey/Nova recovery skill). Better than round 2: match median 315.4 → 277.8 s, ring-outs 135 → 114, zero-jump ring-outs 71.1% → 58.8%, recovery 93.8%, hit rate 41.6%, no-target 9.2% → 6.6%, Nova launches followed by PvP damage 85.7%. Worse: no-progress time 2.3% → 3.4% (325 progress drops, 95% monsters and crystals, 146 of them within 300 px or hit in the last 3 s), central-brawl player targets 78.7% (target 90%), blocks and parries 463 → 155, Yuki escapes 701 (22.9% of its engage time; 10 ring-outs within 3 s), Nova and Rio recovery skills reached a floor 3/15 and 2/10.

| ID | Verdict | Decision |
| --- | --- | --- |
| R4-1 progress drops (Codex top 1) | **accept** | Monsters and crystals now remember who hit them last on the physics-frame clock (`last_attacker`, `last_hit_frame`); hitting the target within 3 s counts as progress for every target kind, and a monster that is after us too. A target within 300 px is kept while a route to where it stands exists. |
| R4-2 Yuki escapes (Codex top 2) | **accept** | One escape per 2.5 s, and only with floor 90 px past the opponent to land on; otherwise hold. (After the round-3 measurement, `2811081` already turned escapes toward a target on another level into holding the ledge.) |
| R4-3 recovery skills (Codex top 3) | **accept** | Nova and Rio use the skill once the ledge is within its reach (260 / 290 px) and aim 60 px above it; the last chance near the realm bottom still takes it; Frey (18/19) unchanged. |
| R4-4 guards | **change, against Codex's reading** | Codex judged round 3 fair (every attacker blocked sometimes). The lead's view: the skipped reactions were also the guard that blocks the rest of a combo (73% of reactions skipped; blocks and parries 463 → 155). A reaction past the wind-up now still raises the guard while the attacker stays in reach and faces us; it is skipped when the attacker turned away or left. Measure blocks per attacker again. |
| R4-5 Rio basics from range | **change, Codex advised an A/B first** | Rio's side basics missed 88.5% at 240–360 px and 91.8% beyond; swinging at air reads as a dumb bot. Basics need the target within 240 px (profile `basic_reach`, scaled); otherwise it closes in or uses a skill. Measured in round 4 against Rio's PvP damage per minute (41.8). |
| Frey recover state 12.2% | **measure** | Frey's recover-state time tripled (4.2% → 12.2%) while its ring-outs fell 25 → 14 and recovery is 97%: round 4 reports where Frey enters recovery. |

Next: Codex QA-14 round 4 (same probe, same seeds); then `decision.md`.

## Round 5 (measurement: Codex QA-14 round 4, `reports/codex-qa-14/round4.md`) — lead decisions

Codex's verdicts on round 4: keep the ledge hold, hits-on-monsters progress, close-target keep (with a fix), escape limits, Rio's recovery reach, the combo guard (blocks + parries 155 → 312) and Rio's basic reach (240 px+ starts 501 → 21, side-basic hit rate 56.3% → 75.0%); revert or redesign Nova's recovery reach (floor reached 3/15 → 3/21). Regressions: no-progress time 647.5 → 1,103.5 s, recovery-skill intents asked every frame (Nova 2,200 / Rio 1,148 for 21 / 4 uses), Yuki ring-outs after hits near a ledge 8 → 13, zero-jump ring-outs 58.8% → 65.8% (Luna 25 of 29).

| ID | Verdict | Decision |
| --- | --- | --- |
| R5-1 close-target keep | **accept** | One extra progress window per target, on a fresh route (`_clear_navigation_path()`); after it the target is dropped like any other. Test with a navigation stub. |
| R5-2 Nova recovery reach | **accept (revert)** | Nova uses the skill from anywhere again; Rio keeps the 290 px limit. |
| R5-3 recovery intents | **accept** | Asked once per recovery and only when not attack-locked. |
| R5-4 Yuki at the ledge | **partly** | Holding the ledge while the escape cools down now raises an early guard half the time. No Luna-specific jump rule: a failed recovery spends its jumps, so zero jumps at ring-out alone does not show a bad jump earlier. |

Conclusion: `decision.md`.

## Round 6 (measurement: Codex QA-14 round 5, `reports/codex-qa-14/round5.md`) — lead decisions

Codex kept: recovery asks matched to uses (Frey 13/13, Nova 22/22, Rio 8/8) and the early guard at a ledge (Yuki ledge ring-outs 13 → 8; blocks + parries 312 → 411). It asked to revert or redesign the close-target extension (no-progress 1,103.5 → 1,238.8 s; 20 s+ standoffs 2 → 6, longest 171 s) and Nova's recovery (0/22). New finding by the lead from the same data: "once per recovery" also cut Frey from 18/19 floors reached to 6/13 — Frey and Nova can use their skill again in the air, and the old every-frame asking had let them.

| ID | Verdict | Decision |
| --- | --- | --- |
| R6-1 close-target extension | **remove** (Codex: per-target extension) | A target the bot has a route to but still does not reach in 2.5 s is better dropped: the route exists on paper and the bot fails to follow it. Keeping it (R4) or extending it (R5) only added no-progress time and standoffs. Hits on the target still count as progress, which is what removed the wrong drops (R3 58 recent-hit drops → R4 3). |
| R6-2 recovery asks | **change** | Asked whenever the skill can start (`PlayerBase.can_use_skill_one()`; Rio adds its one blink per airtime): no asks while locked or out of blinks, and again after each use. Nova from anywhere, Rio within 290 px. |
| R6-3 Yuki long throws | **accept** | Basics within 480 px (`basic_reach` 240, scaled). |

Next: Codex QA-14 round 6 on the same seeds; `decision.md` updated with R5 and round 6.

## Round 7 (measurement: Codex QA-14 round 6, `reports/codex-qa-14/round6.md`) — lead decisions

Codex kept: removing the close-target extension (no-progress 1,238.8 → 999.8 s, longest standoff 171.1 → 48.9 s, central-brawl player targets 88.9%) and Yuki's 480 px basics (side-basic hit rate 44.1% → 50.5%, PvP damage per minute 35.4 → 36.3). It asked to redesign "ask whenever it can start": Frey dashed 437 times (416 in two long recoveries; recovery 94.3% → 97.0%), Nova asked 35,321 frames for 27 uses because `can_use_skill_one()` did not know its one shift per airtime. Rio's gate (8/8 uses, 4 floors) stays.

| ID | Verdict | Decision |
| --- | --- | --- |
| R7-1 Nova availability | **accept** | `Nova.can_use_skill_one()` adds `air_vector_shift_available`, like Rio's blink. |
| R7-2 Frey dash spam | **accept** | At most 2 recovery-skill uses per recovery, for every fighter. |
| Progress drops 199 → 318 | **measure** | The extension removal brings back R3-style drops of close targets the bot cannot reach in practice; Codex's suggestion of a per-target retry only when the route improved is left for the next session. |

Round 7 is this session's last measurement; whatever it shows goes into `decision.md` with the open items.

## Round 8 (measurement: Codex QA-14 round 7, `reports/codex-qa-14/round7.md`) — after the last measurement

Codex kept both round-7 changes (Nova 24 asks for 24 uses; Frey 23 dashes, at most 2 per recovery). Its trace of seed 112's 188.9 s standoff: two Freys 401.2 px apart at the edges of two platforms — 1 px beyond Frey's 400 px attack reach, no landing within the 240 px jump search, so `engage` with no move and no attack; the progress rule counted a same-level target as progress.

| ID | Verdict | Decision |
| --- | --- | --- |
| R8-1 gap dead band | **accept** | Same level counts as progress only while the way toward the target is open: blocked toward it within the last second (`blocked_age`, `blocked_direction` from `_terrain_move_intent`) makes it no-progress, dropped after 2.5 s; blocked away from it does not. Test `_test_gap_dead_band`. Unmeasured by Codex this session. |

Open for the next session: Codex's list at the end of `round7.md` and `decision.md`.

## Round 9 (measurement: Codex QA-14 round 8 at attacks x1.5, `reports/codex-qa-14/round8.md`)

Round 8 (attacks x1.5 + the dead-band fix): seed 112's stall gone (415.9 → 263.1 s), ring-outs 128 → 110, recovery 91.3% → 94.8%, no-progress 845 → 707 s, longest standoff 189 → 90 s, hit rate 45.4% → 49.8%. Zero-jump ring-outs: 69 of 70 spent the last jump in that recovery (no wasted jumps). Frey's second dash shortened the distance ~190 px in both failed recoveries (keep the cap). Basic-reach limits fit the data. Problems: Yuki central-brawl monster targets 8% → 42% (PvP damage per minute 36 → 27); 86 of 88 close drops were routes the movement could not follow (wrong level 51, gap without landing 35); recovery episodes 1,498 → 2,185; two input-less engages (Luna 10 s with a monster 200 px below, Yuki 5.7 s with a crystal).

| ID | Verdict | Decision |
| --- | --- | --- |
| R9-1 routes vs movement (Codex #2) | **accept** | The planner gets the platform rects (`RealmLayout.get_platform_rects`, `Main.get_ai_platform_rects_for_realm`); links between platforms need a gap the movement crosses (`NAV_GAP_JUMP` = landing search − patch − floor probe ≈ 172 px, drops 300 px); a jump up starts within 165 px of the waypoint's platform. |
| R9-2 Yuki central monsters (Codex #1) | **accept, different fix** | Likely cause: the round-8 blocked-way rule also dropped targets within attack range (a ranged fighter across a gap). The rule now applies only out of attack range. Codex's stronger option (no monsters while a valid player exists) is held until round 9 shows whether this suffices. |
| R9-3 input-less engages (Codex #4) | **accept** | A monster only after us is not progress (Luna/monster stall); no kiting from crystals (Yuki/crystal). |
| R9-4 recovery entries (Codex #3) | **measure** | Round 9 splits recovery entries by cause (walked or dashed off, air-down, knockback). |

## Round 10 (measurement: Codex QA-14 round 9, `reports/codex-qa-14/round9.md`)

All five round-9 changes kept: Yuki central-brawl monster targets 42% → 10%, drops 390 → 304 (gap-caused 229 → 120), ring-outs per match 9.17 → 8.08, recovery 96.2%. New: 1,840 of 2,386 recovery entries (77%) were self-inflicted (walked or dashed off; Nova 667); no-progress 707 → 994 s, standoffs 3 → 6, input-less engages 2 → 4 (Yuki held a monster 607 px away across a 407 px gap for 5 s), no-route cases 14 → 71.

| ID | Verdict | Decision |
| --- | --- | --- |
| R10-1 self-inflicted recoveries (Codex #1) | **accept** | Recovery starts only when no floor lies under the fall path: straight-down probes at 0, 0.25, 0.5 and 0.8 s ahead along the horizontal speed (the straight-down probe called every drop to an offset lower platform a fall into the void, and the recovery spent air jumps). |
| R10-2 in-range but idle (Codex #2) | **accept** | The blocked-way rule spares a bot that attacked within 2.5 s, not one merely in attack range. |
| R10-3 no-route fallback (Codex #3) | **later** | Needs a design for what a bot does when no target is reachable (nearest reachable point, roam, other target). |

## Round 11 (measurement: Codex QA-14 round 10, `reports/codex-qa-14/round10.md`)

Both round-10 changes kept: recovery entries 2,386 → 1,346 (self-inflicted 1,840 → 798), input-less engages 4 → 0, standoffs 6 → 3, no-progress 994 → 724 s, hit rate 52.5%. Regression: ring-outs 97 → 108 and zero-jump ring-outs 57 → 71 — of 332 falls the new probe kept out of recovery, 162 turned into late recoveries, because probing straight down from points ahead also counted floors the arc passes under.

| ID | Verdict | Decision |
| --- | --- | --- |
| R11-1 fall probe safety (Codex #1) | **accept** | The probe follows the fall arc itself (fall gravity 1850 x 1.2 x 1.18, speed cap 980 x 1.3416, horizontal speed kept, 10 steps of 0.1 s) and counts a landing only where the arc meets a floor. Test: a floor the arc passes under (fails on the round-10 brain). |
| R11-2 Nova/Rio zero-jump (Codex #2) | **measure** | Expected to follow from R11-1; round 11 checks. |
| no-route fallback, Frey no-progress, central targets, air-side hits (Codex #3-5) | **later** | Left for the next session with the round-11 numbers. |

## Round 12 (measurement: Codex QA-14 round 11, `reports/codex-qa-14/round11.md`)

Round 11 (the arc with the horizontal speed kept, one point): ring-outs 108 → 94, zero-jump 71 → 63, recovery 95.2%, but too strict — 867 falls round 10 accepted were rejected and 856 of them landed (recovery entries +50%, match median +34 s, no-progress +54%). Codex: revert, or a hybrid with air steering and body width.

| ID | Verdict | Decision |
| --- | --- | --- |
| R12-1 hybrid fall check | **accept (hybrid)** | The arc follows the fighter's current move input with its air acceleration (4300 x 1.2) up to its run speed, gravity and speed cap as before, and casts at both feet and the centre (42 px body); cached for 0.1 s while falling. It accepts steered landings (round 11 did not) and still rejects floors the arc passes under (round 10 accepted them). Tests for both. |

## Round 13 (measurement: Codex QA-14 round 12, `reports/codex-qa-14/round12.md`) — fall check decided

Round 12 (arc steered by the move input, both feet): ring-outs 120 and zero-jump ring-outs 80, the worst of the four fall checks; verdicts flipped without input changes 705 times and 1,014 of 1,367 accepted falls needed a late recovery. Codex: revert; use round 10 as the baseline while a new predictor is built.

Fall checks on the same seeds (ring-outs / recovery entries / no-progress / median): straight down 97 / 2,386 / 994 s / 287 s; straight down from points ahead 108 / 1,346 / 724 s / 276 s; arc 94 / 2,022 / 1,118 s / 310 s; steered arc 120 / 1,559 / 737 s / 296 s.

| ID | Verdict | Decision |
| --- | --- | --- |
| R13-1 fall check | **lead decides: the round-11 arc** (Codex: round 10) | The arc has the fewest self-inflicted deaths (94) and best recovery success (95.2%) and is the only one with matches in the criteria's 5–7 minutes; its cost is no-progress time and extra recovery entries, almost all of which land (856 of 859). The code is back to the measured round-11 state (`84bb424`); a better predictor is the next session's first item. |

## Round 14 (2026-10-09 evening: the next-session list; lead's own analysis while Codex QA-14 round 13 measures)

The user asked to work through `decision.md`'s next-session list. Codex round 13 measures the current (round-11) code with new instrumentation; meanwhile the lead analysed the existing R10–R12 drop rows and measured Nova's shift.

| ID | Verdict | Decision |
| --- | --- | --- |
| R14-1 ultimate reach | **fix** (`f0dc673`) | `ULTIMATE_REACH` was set at attacks x2 and stayed there at x1.5: bots scored a target a third farther than the areas reach as "in reach". Now base x `GameScale.COMBAT`. Found while writing the behaviour summary (`reports/bot-behavior/`). |
| R14-2 no-route drops (open item since R10-3) | **fix** (`a94d3d6`) | R11 drop rows: no route 110, 106 of them on the bot's own level across a gap the gap jump cannot cross — target choice skipped the route check for its own level. A same-level target needs no such gap, or a route, or to be within hitting distance (basic reach, else max range). Prevention rather than a fallback: the unreachable target is ignored for 5 s at choice time and the next one is taken. |
| R14-3 route not followed (gap 98, wrong level 73 in R11) | **fix** (`a94d3d6`) | 77 of the 98 and all 73 were targets on another level with a route: the engage approach walked straight at them. Pursuit and the engage approach now follow the route when walking straight does not get there. |
| R14-4 Nova recovery skill (open item: 21 uses, 5 floors) | **fix** (`114581a`) | Lead's measurement: the shift adds speed to the current fall (straight up: highest point 321 / 274 / 232 / 118 / 22 / 0 px at fall speeds 0 / 300 / 500 / 700 / 900 / 1,100 px/s). Bots used it once below the platform, near full fall speed. Out of jumps with no floor under the fall, Nova shifts while falling slower than 450 px/s. |
| R14-5 short-flash rectangles | **fix part** (`6a3222b`) | Four rectangles drawn on top of existing art removed (Frey ultimate charge/release, Yuki ward end, seal burst); the four without art (parry, landing puff, hit streak, seal break) go to CODEX-ART-20. |
| fall predictor, Luna/Yuki ring-outs, fixtures, no-progress / hit rate | **measure** | Codex round 13 items 2–8; decided from its data. |

## Round 15 (measurement: Codex QA-14 rounds 13–14, `round13.md`, `round14.md`)

Round 13 (current R11 code, reproduced exactly): suppressing recovery on the falls R10 would accept raised ring-outs 94 → 219 — the round-11 arc stays (lead's round-13 call confirmed; Codex had suggested R10). Verdict flips: 41% edge grazes within 12 px. Luna/Yuki zero-jump ring-outs: all spent the last jump in the final recovery, ~900 px below the platform after PvP hits, with no lifting skill — a kit question for the user. Hit-rate "drop" R10 → R11 was mostly counting requests as attacks.

| ID | Verdict | Decision |
| --- | --- | --- |
| R15-1 ultimate reach x COMBAT | **keep** | Full-window ultimate hits 330 / 397 (83%); 0.4 s rate 21.5 → 22.3%. |
| R15-2 target choice across uncrossable gaps | **keep** | No-route drops 110 → 6; no unchecked-after-three choices observed. |
| R15-3 route following in pursuit and the engage walk | **revert** (`bae0c26`) | Drops 171 → 59, but no-progress 1,118 → 1,633 s, recovery entries 2,022 → 2,999 (walked off 881 → 1,522), match median 310 → 280 s, longest standoff 104 s. |
| R15-4 Nova's early shift | **revert** (`bae0c26`) | Floors reached 2 / 17 (R11 5 / 21): some aimed level or down, 12 of 16 still falling 0.5 s later. Redesign needs an upward aim and the apex it would reach. |
| R15-5 counter is no attack; route jump from a ledge; 90 px walkable rise | **keep** | Input-less engages 2 → 0; both fixtures are tests. |
| R15-6 seed-112 fixture without route following | **new, narrow** (`bae0c26`) | Approaching a target on a platform overhead one jump reaches (rise 90–187.5 px, within 165 px), jump to it, from a ledge too. Round 15 measures. |
| edge-graze stabilisation, Yuki ring-outs (R14 24), no-target fallback, new standoff fixtures | **later** | After round 15. |
