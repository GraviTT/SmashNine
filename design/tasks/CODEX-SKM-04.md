# CODEX-SKM-04 · Luna: body rows for her new kit — Brave cyclone, Brave grab-and-throw, star warp (candidates)

- Request: the user (2026-11-03, night routine `routine/2026-11-03-night/README.md`, the concept is quoted there): Luna gets a new kit "the same way as Frey" — in the game first with stand-in art, then Codex makes the art. **Candidates only**: the user picks in the motion viewer, then the lead puts the picks in the game.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/skm-04` (from main `47f5334c`). VFX-04 (Luna's effects) runs at the same time in `vfx-b`; you share no files.

## The three moves (the lead is putting them in the game tonight; until then read the concept in the routine README)
- **Brave L "별의 회오리" (Star Cyclone):** Brave Luna spins in place for up to 3 s inside a magic whirlwind (a separate effect, VFX-04) and can walk while spinning; then the whirlwind flies off. Today it borrows the `tumble` row (a hurt row). Needs a **looping spin**.
- **Brave K "혜성 붙잡기" (Comet Catch):** she dashes, **grabs** the first fighter she meets, holds them a moment, then **throws** them left, right or up. Today it borrows `comet_drive` (dash) then `luna_breaker` (throw).
- **Normal K "반짝 도약" (Twinkle Warp):** normal Luna vanishes and reappears a short way off in the held direction, and a star burst around her hits whoever is close. Today it borrows `star_comet`.

## Method (as CODEX-SKM-03 / ART-72 / ART-77; read `design/tasks/CODEX-SKM-03.md`, `design/tasks/CODEX-ART-77.md`, `reports/codex-art-72/README.md`, `reports/codex-skm-03/README.md`)
- Anchors: Brave rows `art/bakeoff/luna/luna_brave-idle-v4.png` (face, costume, palette, detail); normal row `art/bakeoff/luna/luna-idle-v3.png`. Also the move sheets `smash-nine-prototype/assets/art/luna/luna_brave_moves_sheet.png` + `luna_brave_moves_README.md` (rows `brave_combo`, `comet_drive`, `luna_breaker`) and `luna_moves_sheet.png` + `luna_moves_README.md` (rows `star_comet`, `moon_ring`, `star_side`): same cell size, placement and look.
- Costume exactly as the idle. Brave: high pink ponytail with the purple bow and gold star, sleeveless top, short skirt over shorts, short scarf, purple-and-gold armoured gauntlets, star knee-guard boots. Normal: as her idle, with her staff in the same hand.
- One generation per row (six poses in one line on `#00ff00`, no effects, no text, nobody else drawn), then `tools/sprite_pipeline` with `--resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`, one factor per row. Copy `reports/codex-skm-03/*.py` into `reports/codex-skm-04/` and reuse them.
- 192-px cells, 6 frames, feet on y=152, body centre x=96.
- Checks per row: face 0.96–1.04 on upright frames (4× crops: eye distance and face width at the eyes; `head_scale.py` too, the face decides). Deliver a row within 0.95–1.06 with the measured ratio in its note; hold it only beyond that or for a visible error. A frame showing her back has no face to measure: say so. Border clear, 4 px margin, spill 0, detail ≥ 79, no fixed-width slicing. Up to 3 generations per row.

## Rows (deliver in this order)

| Row | Sheet | fps | Loop | Six poses |
| --- | --- | --- | --- | --- |
| `brave_cyclone` | Brave | 20 | **yes** | one full turn in place over the six poses, arms spread wide: (1) facing front; (2) three-quarter turning; (3) side; (4) back (ponytail and scarf swinging round); (5) the other side; (6) three-quarter back toward the front, so (6)→(1) loops smoothly. Hair, scarf and skirt flare outward; up on her toes, feet on y=152. No wind drawn |
| `brave_grab` | Brave | 18 | no | (1) lunging dash forward, both gauntlets reaching open; (2) the catch: both fists closed in front at chest height as if gripping someone (nobody drawn); (3) holding, leaning back, the grip pulled in toward her chest; (4) wind-up: hips turning, both arms swung back over the shoulder; (5) the throw: both arms swung forward and up in a big arc, hands opening; (6) follow-through into her fighting stance |
| `star_warp` | Normal | 20 | no | (1) a quick crouch, staff held across her body, about to vanish; (2) staff raised high, body stretched upward (the vanishing pose); (3) the arrival: landing lightly, staff swung out to the side (the star burst comes from her); (4) the staff swung round, skirt flared; (5) recovering; (6) her guard stance, like the idle. Reads both on the ground and in the air (feet on y=152 in the drawing) |

## Output (deliver each row as soon as it passes)
- `art/bakeoff/luna/luna_brave-<row>-v1.png` + `.json` for the Brave rows, `art/bakeoff/luna/luna-star_warp-v1.png` + `.json`: `note` (Korean, one or two sentences, with the face ratio if outside 0.96–1.04), `for` (Korean: "브레이브 L 별의 회오리 회전" / "브레이브 K 혜성 붙잡기" / "노말 K 반짝 도약"), `frames` 6, `fps`, `cell` 192, `feet` [96,152], `loop`, `factor`.
- `reports/codex-skm-04/<form>-<row>.png`: a 4× board of the row next to its anchor. For `brave_cyclone` also show (6) next to (1) so the loop can be judged.
- After each row update `reports/codex-skm-04/README.md` (Korean: rows done, checks, what a human should judge) and `reports/codex-skm-04/commit.ps1` (only the delivered row files, the boards, the README, the scripts and this card; no attempt folders, nothing under `art/raw/`, no `__pycache__`, no `run.log`). Make sure no line in a committed text file ends with spaces (the lead's commit check rejects trailing whitespace).
- Raw generations in `art/raw/skm-04/` (git-ignored); `reports/codex-skm-04/prompts.txt`.

## Writable
`art/bakeoff/luna/luna_brave-{brave_cyclone,brave_grab}-v*.*`, `art/bakeoff/luna/luna-star_warp-v*.*` (new files only), `art/raw/skm-04/**`, `reports/codex-skm-04/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 95 minutes.
