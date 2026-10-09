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
