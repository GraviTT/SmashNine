# CODEX-SKM-03 · Frey: body rows for her new kit — wing hover and whirl spin (candidates)

- Request: the user (2026-11-03): Frey's new kit is in the game (D44, `reports/frey-kit-2026-11-03/README.md`) with stand-in art; "Codex로 만들기" — make the art. **Candidates only**: the user picks in the motion viewer, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-03` (from main `d911b52`). VFX-03 (Frey's effects) runs at the same time in `vfx-b`; you share no files.

## The two moves (read `design/SKILLS.md`, Frey section, and `smash-nine-prototype/characters/frey/Frey.gd`)
- **Valkyrie Wings (passive):** in the air she holds jump, **hangs still for 0.3 s**, then dashes a short way in one of eight directions with a thrust. The dash already has its drawing: the `dash_strike` row, frames 3-6 (thrust). What is missing is the **hang**: today it borrows `dash_strike` frames 1-2, which look like standing on the ground. Golden wings are drawn behind her as a separate effect (VFX-03): **do not draw wings on the body**.
- **Whirlwind Wave (K):** **one full spin**, then a sword wave flies ahead (the wave is a separate effect). Today it borrows `spike_followup`. Used on the ground and in the air.

## Method (as CODEX-ART-72 and ART-77; read `design/tasks/CODEX-ART-77.md` and `reports/codex-art-72/README.md`)
- Anchor: `art/bakeoff/frey/frey-idle-v2.png` (face, costume, palette, detail). Also Frey's move sheet `smash-nine-prototype/assets/art/frey/frey_moves_sheet.png` with `frey_moves_README.md`, rows `dash_strike`, `spike_followup`, `rising_cleave`, `attack_chain`: same cell size, placement and look. The last attempt at a hover row (`reports/codex-skm-01/`, held for face size) shows what to avoid.
- One generation per row (six poses in one line on `#00ff00`, no effects, no text), then `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row. Copy `reports/codex-art-72/*.py` into `reports/codex-skm-03/` and reuse them.
- 192-px cells, 6 frames. Ground poses: feet on y=152, body centre x=96. Airborne poses: where `dash_strike` puts them.
- Checks per row: face 0.96–1.04 on upright frames (4× crops: eye distance and face width at the eyes; `head_scale.py` too, the face decides). Deliver a row within 0.95–1.06 with the measured ratio in its note (as ART-77); hold it only beyond that or for a visible error. Costume exactly as the idle (no skirt, the same thigh and knee armour), the silver sword and the round blue-gold shield intact in the same hands, border clear, 4 px margin, spill 0, detail ≥ 79, no fixed-width slicing. Up to 3 generations per row.

## Rows

| Row | fps | Loop | Six poses |
| --- | --- | --- | --- |
| `wing_hover` | 20 | no, holds the last | airborne in all six: (1) rising into the stop, knees tucking; (2) body levels out, cape and hair lifting; (3)-(6) hanging still in the air, knees bent under her, sword drawn back at her side with the point forward, shield in front, cape and hair floating upward, a slight bob (3 and 5 a pixel or two higher than 4 and 6); (6) is the clearest aim pose, ready for the `dash_strike` thrust |
| `whirl_spin` | 14 | no | (1) wind-up, sword pulled back, body turning away; (2) back half-turned, cape flaring; (3) **the release**: the turn completes and the sword sweeps flat across at full reach in front of her (the wave leaves here); (4) follow-through, sword extended forward; (5) recovering; (6) back to the guard stance. Readable on the ground and in the air (feet on y=152 in the drawing) |

## Output (deliver each row as soon as it passes)
- `art/bakeoff/frey/frey-<row>-v1.png` + `.json`: `note` (Korean, one or two sentences, with the face ratio if outside 0.96–1.04), `for` (Korean: "발키리의 날개 정지" / "회오리 검기 회전"), `frames` 6, `fps`, `cell` 192, `feet` [96,152], `loop` false, `factor`.
- `reports/codex-skm-03/frey-<row>.png`: a 4× board of the row next to the anchor. For `wing_hover` also put frame 6 next to `dash_strike` frame 3, so the hand-off to the thrust can be judged.
- After each row update `reports/codex-skm-03/README.md` (Korean: rows done, checks, what a human should judge) and `reports/codex-skm-03/commit.ps1` (only the delivered row files, the boards, the README, the scripts and this card; no attempt folders, nothing under `art/raw/`, no `__pycache__`, no `run.log`).
- Raw generations in `art/raw/skm-03/` (git-ignored); `reports/codex-skm-03/prompts.txt`.

## Writable
`art/bakeoff/frey/frey-{wing_hover,whirl_spin}-v*.*` (new files only), `art/raw/skm-03/**`, `reports/codex-skm-03/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 120 minutes.
