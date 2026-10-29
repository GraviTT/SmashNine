# CODEX-SKM-02 · Rio, Nova, Yuki: body rows for skill twists that are designed but not in the game (candidates)

- Request: the user (2026-10-28, through the check session): "Codex에게 스프라이트를 더 만들게 하여 아직 게임에 없는 더 많은 행동 패턴 동작을 생성해볼것. 이후 사용 할수도 있으니 미리 만들어두는 것" — make motions now so they are ready if the skills are built later. **Candidates only**; no skill code changes. Results stay after the checkpoint (`checkpoint-2026-10-25`).
- The designs come from `reports/skill-design-2026-10-15/README.md` section 7: Rio's dimension link (J → K blink through the foe → J), Rio's bounce (a downward stab that springs him back up), Nova's zero-gravity up J (the foe floats), Yuki's link line (a line between her two seals).
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/skm-02` (from the checkpoint). SKM-01 (Frey) runs at the same time in `vfx-a`; two image units of another session also run. You share no files.

## Method (the same as CODEX-ART-72 and ART-77; read `design/tasks/CODEX-ART-77.md` and `reports/codex-art-72/README.md` first)
- Anchors (face, costume, palette, detail): Rio male `art/bakeoff/rio/rio_male-idle-v2.png`, Rio female `art/bakeoff/rio/rio_female-idle-v2.png`, Nova male `art/bakeoff/nova/nova_male-idle-v2.png`, Nova female `art/bakeoff/nova/nova_female-idle-v2.png`, Yuki `art/bakeoff/yuki/yuki-idle-v2.png`. Also each one's current move sheet in `smash-nine-prototype/assets/art/<id>/` and its moves README: same cell size and placement.
- One generation per row: one image, green background `#00ff00`, the six poses in one line, no effects, no text. Then `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row matched to the anchor. Copy `reports/codex-art-72/*.py` into `reports/codex-skm-02/` and reuse them.
- 192-px cells, 6 frames, feet on y=152 and body centre x=96 for ground poses; airborne poses sit where the current airborne move rows put them.
- Checks per row: face 0.96–1.04 on upright frames (4× crops: eye distance and face width at the eyes; `head_scale.py` too, the face decides); costume exactly as the idle; weapons intact, same hands; Rio's long sword and cape and Yuki's sleeves inside the 4 px margin; border clear; spill 0; detail ≥ 79; no fixed-width slicing (each pose cut from its own blob, never cut by a cell edge). Up to 2 generations per row.

## Rows (in this order)

| # | Form | Row | For (designed twist) | fps | Loop | Six poses |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | Rio male | `dimension_link` | dimension link J → K → J | 15 | no | forward slash follow-through → crouch low, sword drawn back along the body, cape wrapping (blink-out) → low dash-through pose, body almost level, sword trailing → plant the front foot and pivot → spinning back slash, the blade sweeping round → settle into the stance |
| 2 | Rio male | `pogo_bounce` | bounce: downward stab, spring back up | 15 | no, holds the last | airborne, sword reversed pointing down under the feet → stabbing down, knees bent over the blade → impact, crouched on the point → legs push, springing up → rising tuck → rising with the sword back in guard |
| 3 | Nova male | `zero_gravity` | up J: the foe loses gravity | 13 | no | step in → palm drawn back at the hip → both palms thrust upward → hold, hair and cape floating upward (no effect drawn) → arms lowering → back to the stance |
| 4 | Yuki | `seal_link` | link line between her two seals | 12 | no, holds the last | a talisman in each hand → arms thrown out to both sides → arms spread wide, hands empty → one hand makes a seal sign, the other pulls an invisible thread across → both hands meet in a seal sign → held |
| 5 | Rio female | `dimension_link` | as row 1 | 15 | no | as row 1, her ponytail trailing |
| 6 | Rio female | `pogo_bounce` | as row 2 | 15 | no, holds the last | as row 2 |
| 7 | Nova female | `zero_gravity` | as row 3 | 13 | no | as row 3 |

## Output (deliver each row as soon as it is done)
- `art/bakeoff/<id>/<stem>-<row>-v1.png` + `.json` (`<stem>`: `rio_male`, `rio_female`, `nova_male`, `nova_female`, `yuki`): `note` (Korean, one or two sentences, include the measured face ratio if outside 0.96–1.04), `for` (the designed twist, Korean), `frames`, `fps`, `cell` 192, `feet` [96,152], `loop`, `factor`.
- `reports/codex-skm-02/<stem>-<row>.png`: a 4× board of the row next to its anchor.
- After **each** row, update `reports/codex-skm-02/README.md` (Korean: rows done, checks, what a human should judge, rows not reached) and `reports/codex-skm-02/commit.ps1` (stage only your files and this card, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`). The run may be stopped at 16:00; finished rows must be complete on disk at all times.
- Raw generations in `art/raw/skm-02/` (git-ignored); `reports/codex-skm-02/prompts.txt`.

## Writable
New files only: `art/bakeoff/rio/rio_{male,female}-{dimension_link,pogo_bounce}-v1.*`, `art/bakeoff/nova/nova_{male,female}-zero_gravity-v1.*`, `art/bakeoff/yuki/yuki-seal_link-v1.*`; `art/raw/skm-02/**`; `reports/codex-skm-02/**`. Nothing under `smash-nine-prototype/` changes. **Hard stop: 70 minutes.** Deliver rows in order and list the rest.
