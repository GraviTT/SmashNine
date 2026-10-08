# Decision: making the bots smarter (2026-10-08)

User: "봇 문제는 현재 밝혀진 것들을 Codex와 토론하여 해결하고, 더 똑똑하게 만들어 볼것." · "Codex에게 데이터를 모으게 할것."

Lead: Claude (decides, implements). Opponent and measurer: Codex. Question and ranked criteria: `question.md`. Log of every round: `log.md`.

## How it was decided

1. Round 1: Codex answered blind (`blind.md`), then attacked the lead's sealed position with 7 points (`attack.md`). The lead accepted D1, D2, D4, D7, partly D3, D5, D6 (`log.md`).
2. Round 2: Codex rebutted with new evidence only (`round-2.md`): it conceded D5 and D6 and found two new defects (N1, N2) and a bug in the D3 implementation; all fixed.
3. Factual disagreements became measurements: Codex QA-14 probe (`smash-nine-prototype/tests/analysis/codex_qa_14/`, `run_probe.ps1`) on the same 12 seeds (101–112, 8 bots, `--fixed-fps 60`), run before the changes (R1) and after each round of changes (R2, R3, R4). Rounds 3 and 4 of `log.md` are the lead's decisions on that data.
4. Two decisions went against Codex's reading, each with its reason and then measured: guards for combo follow-ups (Codex judged R3 fair; R4 doubled blocks and parries, 155 → 312) and Rio's basics only within reach (Codex advised an A/B first; R4 Rio side-basic hit rate 56.3% → 75.0%, wins 5 → 6, PvP damage per minute 41.8 → 35.9).

## What the bots do now (`scripts/EnemyAI.gd`, decision D28)

| Area | Rule | Round |
| --- | --- | --- |
| Aiming | basics aim up / down at a steep target (48 px, slope 0.65); no air-down over the void; skills aim at the target; dash skills stay level | 1 |
| Guarding | sees a swing start (watched every frame, also in hitstun; `attack_serial`) → 55%, 0.14–0.24 s later, toward the attacker on the main axis; skipped when the attacker turned away or left, kept when it stays close (combo follow-ups); 15% guard ahead in engage, 50% at a ledge while the escape cools down | 1–5 |
| Air jumps | the climb keeps the last air jump; routes need only one jump | 1 |
| Targets | levels judged by where bodies stand; hitting the target (fighters, monsters, crystals) within 3 s is progress; a target on another level that does not get 90 px closer in 2.5 s is ignored 5 s (one extra window on a fresh route when it is within 300 px); from the central brawl or 4 left, players before monsters | 1, 3, 4, 5 |
| Portals and retreat | 8 s stay after any portal move; roam only after 4 s with no target; low HP retreats only to an empty stable realm, else backs off 4 s | 2 |
| Ledges | a kiting bot does not back off a ledge: it jumps past an opponent on its level (every 2.5 s at most, only with floor to land on) and holds against one below | 3–4 |
| Recovery | air jumps when below the ledge and falling; out of jumps, Frey / Nova / Rio use their directional skill once per recovery (Rio only within 290 px, aimed above the ledge) | 2–5 |
| Ultimates | opportunity score (target in reach, low, stunned, another opponent near); Nova's slingshot launches at the target or toward safe floor and redirects | 1 |
| Skills | Nova's vector shift only to close distance; Yuki's binding talisman close and on its level; Rio's rune shield only against a swing; Rio's basics within 240 px | 2, 4 |

## Measured result (same seeds; R1 before any change)

| Metric | R1 | R2 | R3 | R4 |
| --- | ---: | ---: | ---: | ---: |
| Match length, median | 305.7 s | 315.4 s | 277.8 s | 293.1 s |
| Portal moves per match | 94.3 | 20.9 | 21.0 | 19.7 |
| Ring-outs (12 matches) | 143 | 135 | 114 | 117 |
| Recovery success | 91.2% | 92.6% | 93.8% | 92.6% |
| Up / down / air-up / air-down attacks | 0 | 3,299 | used by all | used by all |
| Guards: blocks + parries | 0 | 463 | 155 | 312 |
| No-target time | 2.5% | 9.2% | 6.6% | 5.5% |
| Wrong drops (close or just hit) | — | — | 146 | 4 |
| Central brawl: player targets | 86.5% | 75.2% | 78.7% | 84.4% |
| 20 s+ standoffs (longest) | 5 (90.9 s) | 1 (56.6 s) | 3 (42.0 s) | 2 (68.9 s) |
| Nova launches followed by PvP damage | — | 75.0% | 85.7% | 88.4% |

Reports: `reports/codex-qa-14/README.md` (R1), `round2.md`, `round3.md`, `round4.md`.

## After R4 (round 5, `log.md`)

R4 showed three measured problems; fixed without a new design:
- no-progress time 647 → 1,104 s: keeping close targets with a route every time → now one extra window per target on a fresh route;
- Nova's recovery skill with a reach limit reached a floor 3 of 21 times (3 of 15 without) → reverted for Nova; Rio keeps it (2 of 10 → 2 of 4);
- recovery skills asked every frame (Nova 2,200 asks, 21 uses; this also pulled the intent hit rate down to 35.4%) → asked once per recovery.

Codex QA-14 round 5 measures these on the same seeds (`round5.md`, if run).

## Open — for the user

- **How the bots feel to fight** (only a person can judge): guards now block combo follow-ups; bots aim up and down, recover with skills and stop chasing what they cannot reach.
- **Rio won 6 of 12 matches in R4** (5 in R3): a character balance question, not a bot one; a larger sweep before deciding.
- **Low-HP retreat is still useless when it happens** (R4: 8 retreats, all re-engaged and hit again within 10 s): rare now; remove or keep is a design call.
- Match length is back near the 5-minute floor of the criteria (R4 median 293 s; range 259–319 s).
