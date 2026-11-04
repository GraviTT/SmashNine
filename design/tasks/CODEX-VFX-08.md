# CODEX-VFX-08 · Frey jump and landing, Luna's J stars and hit afterglow in pixelfx (candidates A and B)

- Request: the user (2026-11-05, night routine): "일단 Codex 사용량 계속 소모해야 하니까 선택 월드컵 계속 할 수 있도록 Frey와 Luna를 차례대로 끝까지 진행해줘." Plan D49 (`reports/debate-pixelfx-basic/decision.md`); the Frey pilot (`reports/pixelfx-frey-pilot-2026-11-04/README.md`, CODEX-VFX-07) is the model.
- **Two units make this card at the same time, blind to each other.** Each unit is told its letter:
  - **A, "the sharp moment"** (unit `vfx-a`): the instant of contact or launch reads crisp and bright: a short flash, sharp radial lines, stars or sparks, mostly gone quickly (jumps and landings about 0.25–0.4 s, launches about 0.2 s). Few lingering particles.
  - **B, "the directional linger"** (unit `vfx-b`): what stays follows the motion's direction: dust, feathers or stardust pushed along the movement (down and out at a takeoff, sideways along the floor at a landing, behind a flying star), softer and longer (about 0.4–0.8 s).
  - Do not open the other letter's folder (`.../a/` if you are B, `.../b/` if you are A) or any file named `*-a.*` / `*-b.*` of the other letter.
- The user judges now / A / B in the pick cup (`tools/pick_cup/`); only the verdict goes into the game. **Candidates only:** nothing under `smash-nine-prototype/` changes.

## Read first
- The plan and rules: `reports/debate-pixelfx-basic/decision.md`; what the user said about every effect so far: `reports/pixelfx-eval-2026-11-03/README.md` sections 11–14, `reports/pixelfx-frey-pilot-2026-11-04/README.md` (the pilot: in each item the losing candidate also lost to "now", so an effect that is worse than nothing loses).
- How the effects in the game are made and baked: `smash-nine-prototype/assets/art/effects/motion/README.md`; the pilot's candidate B sources `art/bakeoff/effects/pixelfx/frey/b/src/` and `bake.mjs` (a working example of an effect module outside the pixelfx copy, importing its core by absolute URL), the pixelfx effects `C:/Users/TH/Documents/AI/GameProject/pixelfx/src/fx/impacts/sn-luna-stardust-land.js`, `sn-frey-step-dust.js`, `arcane/sn-luna-idle-stars.js` (palettes and motifs already in the game). The pixelfx copy is **read-only**.
- The bench helpers: `reports/pixelfx-eval-2026-11-03/bench.mjs` (`bakeStrip`, `art`, `canvas`, `blit`, `drawStrip`, `realm`, `savePNG`, `stripFrame`).
- The game side: `design/SKILLS.md`, `smash-nine-prototype/characters/frey/Frey.gd`, `characters/luna/Luna.gd` (`_fire_star`), `characters/common/PlayerBase.gd` (`_perform_air_jump`, `_handle_landing_state`, `_spawn_hit_effect`), sprites `assets/art/frey/frey_sheet.png`, `assets/art/luna/luna_sheet.png`, the J star art `assets/art/effects/luna_star_shot.png`, `luna_star_big.png`, the hit sparks `assets/art/effects/hit/{frey,luna}_hit.png`.
- Looks: Frey gold/white/warm amber and feathers (a Valkyrie: winged helmet, she has wings in her passive); Luna pink/violet/gold/white stars and stardust.

## Items (strip names end in `-a` or `-b`)

| Strip | When and where in the game | Drawn | Blend |
| --- | --- | --- | --- |
| `frey_jump` | Frey leaves the floor with a jump: at her feet (anchor = feet), once | facing right (the game mirrors it) | your choice: add for light, normal (translucent) for dust |
| `frey_air_jump` | her air jump, in the air: at her feet, once | facing right | same |
| `frey_land` | a landing that fell less than 130 px (a tapped jump falls 50–110 px; stepping up onto a platform): at her feet on the floor, once | facing right | same |
| `frey_land_big` | a landing that fell 130 px or more (a held jump falls about 220 px): at her feet | facing right | same |
| `luna_star_launch` | a small J star leaves the wand: at the star's spawn point (anchor = that point), once | +x = the shot's direction (the game turns it to the aim: level, 60° up or 60° down) | add |
| `luna_star_launch_big` | the big fourth star leaves the wand | same | add |
| `luna_star_trail` | **loops** behind a small star while it flies (1050 px/s for 0.3 s, about 315 px): anchor = the star's centre, the trail behind it toward −x | +x = flight direction; seamless loop | add |
| `luna_star_trail_big` | loops behind the big star (930 px/s, 0.36 s) | same | add |
| `luna_hit_after` | a small star hits a fighter or monster: at the struck body's centre (where the hit spark plays), once | facing right (+x = the shot's direction) | add |
| `luna_hit_after_big` | the big star hits (its burst `luna_comet_burst` also plays there) | same | add |

Sizes: fighters are about 60×95 px (Frey 90×99) at 1 art px = 1 screen px; the star art is 22×22 (small) and 40×40 (big) at 1.5×. Keep each frame no larger than it needs (a landing within about 220×100, a trail within about 200×60).

## Rules
- Clearly visible (the user's v2 level), but nothing round the head and face, and never hide the body (keep the body's middle light; for the star trail keep the star itself readable).
- Visible from the first frame (no empty lead-in). A landing's size follows the drop; the big versions are clearly bigger.
- Each character's own motion, not colour swaps: Frey's feathers, gold dust, steel; Luna's stars, stardust, pink light.
- 1 art px = 1 screen px; never upscale. Additive strips: colour and light premultiplied into RGB, alpha 0/255, light under 40 dropped (`bakeStrip(..., {additive: true, minLight: 40})`); normal strips may be translucent (dust); a 1-px empty border on every frame. A loop must join seamlessly (first frame follows the last).
- pixelfx reserves these option names: `x`, `y`, `flip`, `angle` (radians: it turns the whole painter, gravity included). Name your own direction option something else (e.g. `aim`).
- **Save every text file as UTF-8** (the pilot's README lost all its Korean on save).
- No change to hit areas, damage, timing or hitstop: pictures only.

## How
- Your modules: `art/bakeoff/effects/pixelfx/<frey|luna>/<a|b>/src/sn-<name>-<a|b>.js`; your bake script: `art/bakeoff/effects/pixelfx/<frey|luna>/<a|b>/bake.mjs` (one per character folder is fine) writing `<strip>-<a|b>.png` + `.json` `{"note": "<plain Korean>", "frames": N, "fps": F, "anchor": [x, y], "blend": "add"|"mix", "loop": bool, "attach": "<when and where>", "source": "<module path>"}`.
- Check every strip on the real sprites with the bench at 1x and 4x (every frame), and the trails over a moving star.

## Output
- The strips, json, modules, bake scripts above.
- `reports/codex-vfx-08-<a|b>/`: `board.png` (each strip on the character at game timing, 1x and 4x), `README.md` (Korean, short: what each strip shows, measured duration / first visible frame / peak frame / painted size, what you could not meet), `commit.ps1` (only your files and this card; no `git add -f`; no trailing spaces, no blank lines at the end of committed text files).

## Writable
`art/bakeoff/effects/pixelfx/frey/<your letter>/**`, `art/bakeoff/effects/pixelfx/luna/<your letter>/**`, `reports/codex-vfx-08-<your letter>/**`. Nothing under `smash-nine-prototype/` or the pixelfx copy changes. Hard stop: 75 minutes.
