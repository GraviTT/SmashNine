# CODEX-PLAN-01 · 로드맵 초안과 설계 결정 토론

- Request: 사용자 "네가 먼저 Codex와 함께 토론 후 일단 알아서 판단해서 프로토타입 진행을 해봐. … 초기 컨셉아트가 폴더 내에 있을테니 그것도 보고 판단 해보고." (2026-10-06)
- Unit: Analyst (plan review + compare/decide + red-team) · Lead (decides, fixes, merges): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/plan-01` (from main `a09e8f2`+draft)
- Sandbox: read-only. Deliverable is the final answer only.
- Running at the same time: the lead is refactoring `smash-nine-prototype/scripts/Main.gd` in the main checkout. This task does not edit anything.

## Read first

1. `design/ROADMAP_DRAFT.md` — the lead's draft and decisions D1–D12 (the subject of this discussion)
2. `smash-nine-prototype/FINAL_GAME_GOAL.md` — newest direction doc (English)
3. `smash-nine/GAME_DESIGN_DOCUMENT.md` — older Korean GDD (lore, roster, systems)
4. `smash-nine/Concept1.png`, `smash-nine/Concept2.png` — concept art (also attached as images)
5. Code, as needed: `smash-nine-prototype/scripts/Main.gd`, `characters/common/PlayerBase.gd`, `scripts/EnemyAI.gd`, `scripts/RealmMonsterSpawner.gd`, `characters/*/*.md`

## Tasks

1. **Compare/decide D1–D12.** For each: agree / disagree / modify, a one-line reason, and the evidence (file:line, doc section, or what the concept art shows). If you disagree, give your concrete alternative with numbers where relevant (times, sizes, counts).
2. **Plan review of M1.** Is the scope right for "a match that ends"? Missing steps, order problems, hidden costs. What must be in M1 to judge whether the game is fun as fast as possible, and what should be cut?
3. **Red-team.** How could the draft fail? Design risks (e.g., 16 players in 9 realms never meeting, bots dominating or idling, collapse killing players unfairly, growth snowball), technical risks (performance, the Main.gd split, timers), scope risks.
4. **Your own proposal.** If you were lead: the ordered task list for M1 (max 10 items) with done-criteria that a headless test or bot simulation can check.

Rules:
- Separate what you **verified in code/docs** from what you **guess**.
- Ownership checklist: when you point at a defect, name the component that owns it and whether your fix belongs there.
- Do not edit any file.

## Done when

- Final answer in Korean, structured as: (1) D1–D12 table, (2) M1 plan review, (3) red-team findings by severity, (4) your M1 task list with done-criteria, (5) what only a human can judge.
