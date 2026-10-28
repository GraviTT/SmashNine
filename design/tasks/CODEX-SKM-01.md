# CODEX-SKM-01 · Frey: body rows for skill twists that are designed but not in the game (candidates)

- Request: the user (2026-10-28, through the check session): "Codex에게 스프라이트를 더 만들게 하여 아직 게임에 없는 더 많은 행동 패턴 동작을 생성해볼것. 이후 사용 할수도 있으니 미리 만들어두는 것" — make motions now so they are ready if the skills are built later. **Candidates only**; no skill code changes. Results stay after the checkpoint (`checkpoint-2026-10-25`).
- The skill session's idea is "a plain move plus the character's twist" (e.g. "dash" → "hover in the air, then dash"). Frey is a Valkyrie with a winged helmet, a long sword and a round blue-gold shield, and a blue cape.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-01` (from the checkpoint). SKM-02 (Rio, Nova, Yuki) runs at the same time in `vfx-b`; two image units of another session also run. You share no files.

## Method (the same as CODEX-ART-72; read it and `reports/codex-art-72/README.md` first)
- Anchor: `art/bakeoff/frey/frey-idle-v2.png` (face, costume, palette, detail). Also look at Frey's current move sheet `smash-nine-prototype/assets/art/frey/frey_moves_sheet.png` and `frey_moves_README.md` (rows `dash_strike`, `rising_cleave`, `spike_followup`, `attack_chain`): same cell size and placement.
- One generation per row: one image, green background `#00ff00`, the six poses in one line, no effects, no text. Then `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row matched to the anchor. Copy `reports/codex-art-72/*.py` into `reports/codex-skm-01/` and reuse them.
- 192-px cells, 6 frames, feet on y=152 and body centre x=96 for ground poses; airborne poses sit where `dash_strike` and `rising_cleave` put them.
- Checks per row: face 0.96–1.04 on upright frames (4× crops: eye distance and face width at the eyes; `head_scale.py` too, the face decides); costume exactly as the idle; sword and shield intact, same hands; border clear; 4 px margin; spill 0; detail ≥ 79; no fixed-width slicing (each pose cut from its own blob, never cut by a cell edge). Up to 2 generations per row.

## Rows (in this order)

| Row | For (designed twist) | fps | Loop | Six poses |
| --- | --- | --- | --- | --- |
| `hover_dash` | K: hover in the air, then dash | 14 | no, holds the last | leap up with knees tucked → hover at the top, body level, sword drawn back at the hip, shield forward, cape and hair floating → hover hold, sword point now aimed forward (different from the frame before) → body tilts forward to launch → full forward thrust, body stretched, sword extended → thrust end, held |
| `launch_chase` | L: launch, then follow up with an extra hit | 15 | no, holds the last | low rising upswing → rising with the sword overhead → still rising, body turning → at the top, a second strike: a downward cross slash at head height → follow-through → recovery pose in the air, held |
| `shield_bash` | J third hit: a shield shove | 14 | no | step in with the shield raised → shield arm pulled back, weight on the back foot → shove: shield fully forward, body weight forward → impact hold → recoil → back to the guard stance |
| `sword_plant` | ↓J: plant the sword, a shockwave runs forward | 13 | no | sword raised point-down in both hands → plunging down → sword stuck in the ground in front, one knee bent → pressing down on the hilt → pulling it out → back to the stance |
| `air_hover_swing` | air J: stop in the air and make one big swing | 16 | no, holds the last | airborne, sword at the side → stop and wind up big behind the shoulder → wide horizontal swing, sword at the front → swing finished, body twisted → follow-through → held |

## Output (deliver each row as soon as it is done)
- `art/bakeoff/frey/frey-<row>-v1.png` + `.json`: `note` (Korean, one or two sentences, include the measured face ratio if outside 0.96–1.04), `for` (the designed twist, Korean), `frames`, `fps`, `cell` 192, `feet` [96,152], `loop`, `factor`.
- `reports/codex-skm-01/frey-<row>.png`: a 4× board of the row next to the anchor.
- After **each** row, update `reports/codex-skm-01/README.md` (Korean: rows done, checks, what a human should judge, rows not reached) and `reports/codex-skm-01/commit.ps1` (stage only your files and this card, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`). The run may be stopped at 16:00; finished rows must be complete on disk at all times.
- Raw generations in `art/raw/skm-01/` (git-ignored); `reports/codex-skm-01/prompts.txt`.

## Writable
`art/bakeoff/frey/frey-{hover_dash,launch_chase,shield_bash,sword_plant,air_hover_swing}-v1.*` (new files only), `art/raw/skm-01/**`, `reports/codex-skm-01/**`. Nothing under `smash-nine-prototype/` changes. **Hard stop: 70 minutes.** Deliver rows in order and list the rest.
