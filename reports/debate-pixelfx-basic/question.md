# Debate: a plan to reinforce the player characters' basic effects with pixelfx (2026-11-04)

User (2026-11-04): "플레이어 캐릭터들의 기본 이펙트들의 pixelfx 스킬을 통한 보강 계획을 진행 할 예정이니 테스트의 과정과 결과를 보면서 Codex와 상의 해볼 것."
(The user will run a plan to reinforce the player characters' basic effects with the pixelfx skill; consult Codex, looking at how the test went and what it showed.)

## Question
What should that plan be? Answer:
- **scope**: which effects count as "basic" and are worth reinforcing, per character form;
- **order**: what first, and in what batches (by character, by effect kind, or otherwise);
- **method**: pixelfx alone, Codex sprite art, or both layered, per kind of effect; who writes the effects;
- **candidates and judging**: how many candidates per item, how they differ, how they are shown to the user;
- **rules** every effect must meet, and the **checks** before the user sees a batch;
- **risks**, and what to measure first.

## What the test showed (read these)
All paths are absolute. The lead's repo is `C:/Users/TH/Documents/AI/GameProject/SmashNine` (main at `0ec77253`).
- `reports/pixelfx-eval-2026-11-03/README.md` — the whole evaluation: sections 1–10 (where pixelfx fits in SmashNine, examples: Nova's gravity beam C (not adopted, Codex A won), hits, body-following status, particles, weather), 11 (Luna/Frey motion test), 12 (v1 "too timid" → v2), 12's user verdict (Luna idle head too sparkly → v3), 13 (all four in the game).
- Stills of the comparisons: `reports/pixelfx-eval-2026-11-03/out/motion-*.png` (now | v1 | v2 or now | v2 | v3) and `out/game-*.png` (in-game capture, camera 2x). Also `out/hits.png`, `hits-mix.png`, `status.png`, `dust.png`, `weather.png`, `beam-*.png` (sections 4–7).
- The bench: `reports/pixelfx-eval-2026-11-03/bench.mjs`, `motions.mjs` (how candidates are rendered in game timing and baked to strips).
- The pixelfx custom effects: `C:/Users/TH/Documents/AI/GameProject/pixelfx/src/fx/**/sn-*.js` (pinned copy, read only).
- The skill's rules and past verdicts: `C:/Users/TH/.claude/skills/dot-effect/SKILL.md`, `references/decisions-log.md`, `references/projects.md` (SmashNine section).
- In the game: `smash-nine-prototype/scripts/Vfx.gd` (SPECS), `characters/common/PlayerBase.gd` (`get_motion_overlays`, `get_motion_frame_effects`, `character_landing_effect`, `_spawn_landing_puff`, `_draw_attack_art`, `_spawn_hit_effect`), `characters/frey/Frey.gd`, `characters/luna/Luna.gd`, `assets/art/effects/motion/README.md`, `tests/test_motion_fx.gd`.
- Every move and the effect art it draws today: `design/SKILLS.md`. Decisions: `design/DECISIONS.md` (D30/D31 characters first, D40 effect drawing rules, D46 play styles, D48 this work).

## User verdicts so far (they bind the plan)
- 11-04: "이런 식으로 이펙트를 추가하니까 더욱 좋다 … 이 스킬을 적극적으로 사용해도 될 것 같다. 다만 이펙트를 너무 소극적으로 넣은 것 같으니 … 조금 더 잘 보이도록" → v2 strength is the baseline.
- 11-04: Luna's idle v2 had "머리 쪽에 너무 반짝임이 과한" → keep sparkles off the head and face.
- 11-04 (after seeing them in the game): "착지 별가루 빈도는 큰 점프에서 가장 최신의 뚜렷한 버전을, 작은 점프에서 이전의 작은 버전을 사용. 발걸음 먼지는 Frey의 발걸음 속도에 맞춰서 나오게."
  The lead measured the dust: it spawns on every footfall, but its strip is nearly empty on frame 0 and peaks 0.2–0.3 s later, when she is already on the next step; it lasts 0.69 s against a 0.35 s step.
- 11-04: candidates will be judged in a new, simpler pairwise viewer ("XX 선택 월드컵"): two candidates side by side, pick the better or call a draw, 3+ candidates play a round-robin league on points, a note per match on what each side does better; afterwards the AI reads the records and decides. The old motion viewer got too complex from the sheer number of items.

## Criteria, ranked
1. **Feel and readability in a real match**: the match camera (zoom 0.85, 1280x720) with up to 8 fighters, monsters and realm art. Effects read at a glance, never hide a body, and it stays clear whose effect is whose.
2. **Fits the user's verdicts above** (strength, head/face, timing to the motion, size by the event).
3. **One cast**: the 6 effect sets (Frey, Luna, Brave Luna, Yuki, Nova, Rio) look like one game with each other and with the existing Codex art.
4. **Cost**: the user's judging time, production time, and Claude/Codex tokens.
5. **Web performance**: the web build must stay smooth in a crowded fight.

## Constraints
- Presentation only: no change to hit areas, damage, timing or hitstop (hitstop is a gameplay change).
- 1 art px = 1 screen px (world 1x); no upscaled pixelfx output next to the fine sprites.
- Godot does not run JS: pixelfx effects are baked into Vfx strips; anything that must follow the body's colour or outline needs a shader (not yet tried in the game).
- pixelfx pinned copy, new files only with the `sn-` prefix, never run `tools/index.mjs`.
- Only what the judging picks goes into the game. Codex units never edit product source (the lead wires).
- Skills (K/L/U) and ultimates (I) keep their Codex art; this plan is about the basic effects.
