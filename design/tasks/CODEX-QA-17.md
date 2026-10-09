# CODEX-QA-17 · Frey and Luna against the seven finishing criteria

- Request: 사용자 2026-10-10 (취침 루틴): finishing criteria for every character — "캐릭터의 컨셉이 외형과 성능, 스킬에 잘 녹아 들었는지 / 스프라이트의 완성도를 각 스프라이트 1프레임씩 자세히 확인하여 끌어 올렸는지 / 스킬들이 플레이어가 사용했을 때 확실하게 어떤 스킬이다 라는 것을 인지 할 수 있는지 / 고유한 움직임으로 콤보가 제대로 들어가 손맛이 살아나는지 / 다른 캐릭터와 확연히 차별화 할 수 있는 특징이 있는지 / 봇이 그 특징대로 캐릭터를 운용하며, 실제 사람들이 플레이 해도 똑같을지 / 약점과 강점이 명확하면서도 실력으로 그것을 커버 할 수 있는지". "먼저 Frey와 Luna의 완성도를 더 높인다. 위 사항들을 고려 하면서, 스킬들을 개선하고, 고유 패시브를 추가한다."
- Unit: Analyst (and tester with scripted input) · Lead (decides and implements): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/char-qa-17`
- Read first: `characters/frey/Frey.md`, `characters/luna/Luna.md`, `characters/frey/Frey.gd`, `characters/luna/Luna.gd`, `characters/common/PlayerBase.gd` (combo steps, hitstun, knockback, guard, `apply_hit`), `smash-nine-prototype/FINAL_GAME_GOAL.md`, `design/BOT_TUNING.md` (sections 3 and 6), `reports/bot-behavior/README.md`, the other characters' docs for comparison.
- Running at the same time: Codex builder `codex/sprite-review-21` (Frey/Luna sprites) and the lead (adding a short super armor after every ultimate starts, then designing and implementing Frey/Luna changes). **This task does not edit product source or existing tests.**
- Timeout: given in the prompt.

## Round 1 · diagnosis and blind proposals

1. **Blind proposals first** (before any lead design exists): for Frey and for Luna, write
   - how the concept (role, look, story) shows today in appearance, numbers and moves, and where it does not;
   - 2–3 **unique passive** options each: the rule with numbers, how a player sees it on screen, how a bot would use it, the counterplay, and the balance risk (Frey is already the strongest bot in sweeps; her balance is on hold, so a Frey passive should add identity more than power);
   - skill improvements per move (J chain and directions, K, L, ultimate; Luna normal and Brave): readability, its role in a combo, how it differs from other characters. Rank everything.
2. **Measure (headless, scripted input, `--fixed-fps 60`)** against a training dummy, then a moving bot:
   - **Combo connects:** Frey J1→J2→J3 at contact, 60 and 120 px; L rising cleave → spike re-press window; L → air J; K → J; up J → air up J. Luna J (trail hit then bloom); J → K comet; L moon ring at its sweet spot; Brave J chain; Brave up J → air up J; Brave K → J; Brave L. For each: connect rate, frames between the target leaving hitstun and the next hit becoming active (negative = true combo), knockback distance.
   - **Readability:** windowed captures of each move at its key frames (start, active, end) with its effect art, one contact sheet per character; note moves that look alike (they all play the same 4-frame attack row today).
   - **Bot usage:** from `reports/codex-qa-14/round16-*` (raw data in this clone, variant `s0` = the current bot code): per-move activations and hit rates for Frey and Luna; how often Luna transforms, how long Brave lasts, how often the heart laser fires; how often Frey re-presses L for the spike.
   - **Ultimate interruptions (baseline for the lead's super armor):** in the same data or a fresh 12-match run of the current main, how many ultimates were interrupted by a hit within 1 s of the cast, per character (and what the interruption cost: Nova launch cancelled, Frey dive stopped, Luna transformation still on, etc.).
   - **Differentiation:** one table of all five characters — speed, reach, mobility, combo route, unique mechanic — and where Frey and Luna overlap with others.
3. **Score** each of the seven criteria 1–5 for Frey and for Luna with the evidence, and list the top five fixes per character.

Writable: `reports/codex-qa-17/**`, `smash-nine-prototype/tests/analysis/codex_qa_17/**`. Report `reports/codex-qa-17/README.md` (Korean): the proposals, the measurements, the scorecards, the ranked fixes. Commit, or `reports/codex-qa-17/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`. Keep large raw data out of the commit.

## Round 2 · retest after the lead's changes (2026-10-10 night)

The lead changed Frey and Luna after Round 1 (commits `be8b14c`, `a2ff0bc` and the Luna echo / armor commit on top; read `characters/frey/Frey.md` and `characters/luna/Luna.md`, sections "Passive" and "2026-10-10 개선"):
- every ultimate: 0.6 s super armor after the cast and after each follow-up press that starts a new stage (Nova orbit/launch, Luna heart laser; mashing the key renews nothing) — damage only, no knockback/hitstun/cancel; gold flash;
- Frey: passive "발키리의 추격" (a landed launcher marks the target for 1 s; airborne Frey moves ×1.15 toward it), the spike re-press now cancels the rising cleave's recovery (window 0.18 s after the cleave lands), Frey bots re-press it, J1/J2 cancel their recovery on hit (true combo), per-move sprite frames;
- Luna: passive "별빛 충전" (precise echo / comet burst / moon ring hit = a star, five cut the ultimate cooldown by 6 s), the side echo's bloom opens on the body the trail struck (75 px or farther ahead), Brave jab/body kick cancel their recovery on hit, per-move frames.

Re-run **the same inputs as Round 1** on the new main and report before → after:
1. **Combos:** `combo_probe.gd`, same routes, trials and distances. Fixes to the probe itself: the Brave routes must start after the transformation burst is over (it launched the dummy in Round 1: wait until the target has landed and left hitstun, or place the target after the burst), and `L-spike` must press L again while `rising_followup_timer > 0` without waiting for `_can_start_attack()` (the spike now cancels the recovery). Add Frey J1-J2-J3 push distance after the third hit (it is larger now) and L → air J / up J → air up J with the pursuit speed (does the pursuit make them connect?).
2. **Passives in matches:** per match and per character: Frey marks made, seconds spent pursuing; Luna stars by source (echo, comet, ring), full charges, seconds of cooldown cut, ultimate casts per match against Round 16 S0.
3. **Bot use:** Frey spike re-presses per opportunity (Round 1: 0 of 10) and spike hits; Frey L and Luna J hit events per use against Round 16 S0.
4. **Ultimate interruptions:** `match_probe.gd`, seeds 301–312, 90 s, same as Round 1: casts, hit within 1 s, "likely cancelled", plus how many hits the armor absorbed.
5. **Readability:** `capture_moves.gd` again, new contact sheets; say whether Frey J1/J2/J3 and Brave jab/body kick/spin kick now read as different moves, and whether the spike ring, the pursuit wings and Luna's star orbit can be seen.
6. **Sweep:** 12 matches, seeds 101–112, 8 bots, 480 s, current bot code (= Round 16 S0) with `bot_behavior_probe_round16.gd` (variant `current`): win rate, ring-outs, damage per minute for all five, against Round 16 S0. Frey's balance is on hold: report, do not propose numbers for her unless something is broken.
7. **Scorecards:** the seven criteria again for Frey and Luna (Round 1 → Round 2 with evidence) and the top remaining fixes.

Order if time runs short: 1, 4, 3, 2, 6, 5, 7 (always write 7 with what you have). Run at most two Godot processes at once (a Codex art builder runs at the same time).

Writable: `reports/codex-qa-17/round-2/**`, `smash-nine-prototype/tests/analysis/codex_qa_17/**` (new files or `_r2` copies; keep Round 1 files as they are). Report `reports/codex-qa-17/round-2/README.md` (Korean). Commit, or `reports/codex-qa-17/round-2/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`. Keep large raw data out of the commit.
