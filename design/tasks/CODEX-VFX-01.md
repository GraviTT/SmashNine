# CODEX-VFX-01 · Rio's extra air jump: a small effect at his feet (candidates)

- Request: the user (2026-10-25, through the check session "게임 상태 점검 및 정리"): Codex usage was reset; spend it on image work that needs no user decision. Results stay **candidates** after the checkpoint (`checkpoint-2026-10-25`, `c51a417f`) and are checked and applied later.
- Why this effect: the sprite audit (D40, `reports/debate-sprite-audit/decision.md`, item B8) found that Rio's two extra air jumps show nothing. `design/SKILLS.md` lists it as effect work item 4 ("Rio 공중 추가 점프"): show that one extra jump was spent. It must not look like his K blink trail.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-a/SmashNine`, branch `codex/vfx-01` (from the checkpoint). Another image unit (VFX-02, skill icons) runs at the same time in `vfx-b`; you share no files.

## Read first
- `design/SKILLS.md`: the Rio section (row "자동 · 공중 2회 추가 점프"), the effect work list (item 4), and the reading notes (scales).
- `smash-nine-prototype/assets/art/effects/README.md`: strip contract, palette and drawing rules (transparent, hard alpha 0/1, NEAREST, 1-px border clear).
- `smash-nine-prototype/characters/common/PlayerBase.gd` around `air_jumps_left -= 1` (the air jump: `velocity.y = jump_velocity × 0.86`), and `_spawn_landing_puff` (how a small strip effect is spawned at the feet with `EFFECT_STRIPS.spawn`).
- Rio's adopted effects, for palette and level: `smash-nine-prototype/assets/art/effects/skill/rio_blink_trail.png` (K: must look different), `effects/skill/rio_rune_guard.png` and `rio_rune_burst.png` (L: must look different), `effects/rio_mana_wave.png`, `effects/hit/rio_hit.png`.
- Rio's sheets: `smash-nine-prototype/assets/art/rio/rio_male_sheet.png` and `rio_female_sheet.png` (128-px cells, feet at y=120, rows idle 6, walk 8, jump 1, fall 1, attack 6, shield 6, hurt 1; read the README beside them for the current row list).

## Spec

| Item | Value |
| --- | --- |
| What it shows | One extra air jump was spent: a small burst **under his feet**, as if he stepped on the air. |
| Variants | 3 clearly different ideas, for example (a) a thin mana step plate that flashes and breaks downward, (b) a burst of small gem shards kicked downward, (c) a short blue-cyan ripple ring flattened under the soles. Not a hexagon (that is the rune shield), not a long streak (that is the blink trail). |
| Two states per variant | `-1`: the first extra jump. `-2`: the last one (no jumps left), brighter or with a different accent, so a player reads "that was the last". Same canvas, frames and anchor. |
| Frame | about 64×64 per frame (a wider 96×48 is fine if the shape is flat), 4 or 5 frames in one horizontal strip |
| Anchor | bottom centre at the soles: the strip is spawned at Rio's `global_position` (his feet) |
| Playback | one-shot, 0.10–0.14 s in total (write the fps in the json) |
| Body | must not cover Rio: everything stays below his ankles, at most a few pixels above the soles |
| Colours | Rio's blues and cyan from the files above; a light accent is fine. No text, no glow halo outside the shape |
| Pixels | transparent background, alpha 0/1, nearest, 1-px border of every frame empty |

## Output
- `art/bakeoff/effects/rio/rio_air_step-<a|b|c>-<1|2>-v1.png`, each with a `.json` `{"note": "<plain Korean, one or two sentences>", "replaces": "smash-nine-prototype/assets/art/effects/skill/rio_air_step.png", "frames": N, "fps": F}`. `replaces` names a new file: nothing like it exists yet.
- `reports/codex-vfx-01/board.png`: for each variant and state, every frame at 4× under Rio's jump frame (male and female sheets), on a dark background like a realm, plus the strip at 1×.
- `reports/codex-vfx-01/README.md` (Korean, short): variants, measurements (size, frames, alpha, border, how far above the soles), what a human should judge.
- `reports/codex-vfx-01/prompts.txt`; raw generations in `art/raw/vfx-01/` (git-ignored).
- `reports/codex-vfx-01/commit.ps1`: stage only your files and this card, no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
`art/bakeoff/effects/rio/rio_air_step-*`, `art/raw/vfx-01/**`, `reports/codex-vfx-01/**`. Nothing under `smash-nine-prototype/` changes. No game code. Hard stop: 90 minutes.
