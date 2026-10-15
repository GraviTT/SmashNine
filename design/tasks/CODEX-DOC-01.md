# CODEX-DOC-01 · Skill descriptions for every character, with each skill's effect art (`design/SKILLS.md`)

- Request: 사용자 2026-10-15 "각 캐릭터별 스킬 설명을 써주고 이후로 스킬별 이펙트 스프라이트 작업으로 넘어갈 준비를 해줘. 실제 스킬 성능 수정은 다른 세션에서 진행 할 예정이니까 스킬이 바뀌면 스프라이트도 바꿔야 해."
- Unit: an analyst. Branch `codex/doc-01`, clone `SmashNine-units/analyst/SmashNine`. A Rio art unit runs in `builder-frey`; you share nothing.
- **Read only.** You write one document and a small report. Nothing under `smash-nine-prototype/` changes.

## What to write: `design/SKILLS.md` (Korean, plain words)
This is a living document. The skill-balance session will keep it up to date, and the effect-sprite work reads it. So every line must match the **code** today; where a `characters/<id>/<Id>.md` disagrees with the code, the code wins, and you list the disagreement in your report.

Write one section per character, in this order: Frey, Luna (with Brave Luna's form), Yuki, Nova, Rio. Each section has:
1. One line: role and play style (from the `.md`).
2. **A table of every move**, including ground and air variants, the dash, the passives and the ultimate:

   | Column | Content |
   | --- | --- |
   | 입력 | e.g. `J`, `↑J`, `공중 ↓J`, `K`, `L`, `I` |
   | 기술 | the name in the game or `.md` |
   | 하는 일 | 1–2 plain sentences: what the player sees and what it does |
   | 주요 수치 | damage, range or hitbox size, active time, cooldown, knockback; from the constants, with the constant names in brackets |
   | 몸 동작 | the sprite row(s) it plays, and frame ranges where the code picks them, e.g. `attack_chain` 1–2 |
   | 이펙트 지금 | what is drawn besides the body: art files (`assets/art/effects/...`) and procedural shapes (`Vfx`, `Line2D`, `ColorRect`, `draw_*`), with the script function that draws them |
   | 이펙트 상태 | `그림` (dedicated art), `도형` (procedural shapes only), `없음`, or `공용` (shared generic art) |
   | 이펙트가 따라야 할 값 | the gameplay values the effect's look must match: shape, size (the hitbox), duration, direction, colour per character |

3. Short notes on special states: Luna's Brave form and the transformation, Yuki's seals, Nova's momentum, Rio's runes and overdrive swords.

Then three closing sections:
- **이펙트 스프라이트 작업 목록 (준비)**: every move whose effect is `도형`, `없음` or `공용`, plus `그림` effects that no longer match their values. For each one: the character, the move, what the art must show, its size and frames, and which values it depends on. Order them by how often a player sees them: basic attacks first, then skills, the ultimate, passives, then hits.
- **스킬을 바꿀 때 (다른 세션용 규칙)**:
  - Change the move's row here in the same commit.
  - If a value in "이펙트가 따라야 할 값" changes, mark that effect `다시 그림` in the work list.
  - Do not edit effect art in a balance commit.
- **출처**: the files and functions you read.

## Checks
- Every move the code can play appears in the table. List the input-handling functions you followed (e.g. `perform_basic_attack`, `perform_skill_one/two`, `perform_ultimate`, dash, air variants) and confirm each branch has a row.
- Every effect file under `assets/art/effects/` is either named in some row or listed in the report as unused.
- Spot-check 5 numbers per character against the code, and name them in the report.

## Output
- `design/SKILLS.md`
- `reports/codex-doc-01/README.md` (Korean, short): code/doc disagreements, unused effect files, spot checks, anything unclear
- `reports/codex-doc-01/commit.ps1`: no `git add -f`, no `__pycache__`

## Writable
`design/SKILLS.md`, `reports/codex-doc-01/**`. Hard stop: 75 minutes.
