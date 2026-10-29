# CODEX-SKM-01b · Frey: retry `hover_dash` and `launch_chase` (candidates)

Follow-up of CODEX-SKM-01 (same clone, branch `codex/skm-01b` from `codex/skm-01`). Read `design/tasks/CODEX-SKM-01.md` and `reports/codex-skm-01/README.md` first: same method, same scripts, same checks.

These two rows are the user's own examples ("공중에 머무른 뒤 돌진", "적을 띄우고 추가타"). One more generation each, fixing what held them:
1. `hover_dash`: the sword is Frey's silver long sword with a visible blade in every frame (attempt 1 turned it gold in F4, attempt 2 lost the blade in F4). F2 and F3 must clearly read as hovering in place: body level, legs tucked, cape and hair floating up, the sword drawn back (F2) then aimed forward (F3).
2. `launch_chase`: the face was too small (eye ratio 0.879–0.944). Draw her a little larger in the generation, or keep the raised sword lower in F2 so one row factor fits both the face and the 4 px margin. Costume exactly as the idle (no skirt).

Delivery rule (as CODEX-ART-77): a row within 0.95–1.06 on every measured upright face frame, with no visible error, is delivered as a candidate; if it is outside 0.96–1.04, its `note` says the measured ratio. Output names `art/bakeoff/frey/frey-hover_dash-v1.*`, `frey-launch_chase-v1.*` (the json fields of SKM-01). Boards `reports/codex-skm-01b/frey-<row>.png`.

Deliver `hover_dash` first. After each row, update `reports/codex-skm-01b/README.md` (Korean) and `reports/codex-skm-01b/commit.ps1` (only the delivered row files, the boards, the README, this card; no attempt folders, nothing under `art/raw/`). The run is stopped at 15:58 local time.

## Writable
`art/bakeoff/frey/frey-{hover_dash,launch_chase}-v1.*` (new files only), `art/raw/skm-01b/**`, `reports/codex-skm-01b/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 25 minutes.
