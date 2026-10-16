# CODEX-QA-19 · Audit of the character sprites and their effect sprites (debate: blind answer)

- Request: 사용자 2026-10-16 "Codex와 함께 현재 캐릭터 스프라이트와 그에 따라오는 이펙트 스프라이트들을 전체 점검. 의견을 주고받고, 서로 반박을 한 뒤 Claude가 최종 결정."
- Unit: Analyst · Lead (decides, fixes and merges): Claude.
  - This is the **blind** phase of a debate: the lead has written its own audit and withholds it. Do not look for it.
  - Later rounds attack the lead's audit and rebut its replies.
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/qa-19` (from the latest main).
- Read first: `reports/debate-sprite-audit/question.md` (the question, ranked criteria, constraints, files) and everything it lists.
- Running at the same time: no other Codex unit. The lead does its own audit; a skill session may commit gameplay changes to main. **This task does not edit `smash-nine-prototype/` or any art.**

## Writable paths (everything else is read-only)

| Path | For |
| --- | --- |
| `reports/codex-qa-19/**` | the answer (`README.md`), boards, measurement JSON |
| `tests/analysis/codex_qa_19/**` | your measurement and board scripts (Python + Pillow, or headless Godot) |

Forbidden: product code, art files, docs, existing tests, merging, pushing, installing packages, downloads, windowed Godot runs. Use the clips in `art/clips/` for the in-game look.

## Tasks
1. **Inventory**:
   - every row of every sheet (8 forms × base + moves), with the code's row table (frames, fps)
   - every effect file the code draws for these fighters, and where (file:line), at what centre, size, rotation, layer and alpha
2. **Measure**, per form and row:
   - feet line
   - body height
   - head height (art v2 ratios)
   - frame-to-frame body drift in rows that should stand still
   - pixels touching cell edges
   - empty or duplicate frames
   
   Per effect:
   - real frame size vs `AUTHORED_WIDTH` and the frame count in `Vfx.SPECS`
   - where it lands relative to the body centre and to the attack area the code spawns
   - whether it reaches below the floor or hides the body
   - Leave the numbers in JSON.
3. **Look** at every clip pair (fx/nofx) and every sheet:
   - at 1× (as the game shows them) and 3× (for detail)
   - build boards that put the problem next to a good example
4. **Findings**: at most 20, strongest first. Each finding has:
   - an ID (B1, B2…)
   - what and where: file, row and frame, or clip and frame
   - evidence: number, board path, or file:line
   - severity 상/중/하
   - owner: sprite art, effect art, code placement or gameplay
   - action: code fix, redraw candidate or keep, with the cost
   - Mark what is only an opinion.
   - Apply the ownership checklist: say whether the fix belongs in the owner, or would compensate there for a defect elsewhere.
5. **Per-form table**: one line each for the 8 forms (sprites ok / issues, effects ok / issues), and the 3 problems that most hurt the game.

## Output
- `reports/codex-qa-19/README.md` in Korean: tasks 4 and 5 first, then the inventory and method. This is your blind answer.
- `reports/codex-qa-19/boards/*.png`, `reports/codex-qa-19/*.json`.
- `reports/codex-qa-19/commit.ps1` if `.git` is not writable. It must:
  - add only the writable paths
  - not use `git add -f`
  - not add `__pycache__`

Hard stop: 90 minutes. If time runs short, finish the findings and the table first, then list what you did not check.
