# Debate: audit of the character sprites and their effect sprites (2026-10-16)

User (2026-10-16): "Codex와 함께 현재 캐릭터 스프라이트와 그에 따라오는 이펙트 스프라이트들을 전체 점검. 의견을 주고받고, 서로 반박을 한 뒤 Claude가 최종 결정. … 점검 보고서는 알기 쉽게 Codex에게 이미지로 만들어 설명 하게 할 것."

## Question
What is wrong with the current character sprites and the effect sprites that come with them? For each problem:
- how bad it is in the game
- who owns it
- what to do

The answer ranks the problems. Each one gets one action:
- **code fix**: position, scale, layer, alpha, rotation, frame range or playback, in the code that draws it
- **redraw candidate**: new art the user picks from; only picks go into the game
- **keep**: not worth changing now

## Scope
- 5 characters, 8 forms: Frey, Luna, Brave Luna, Nova (male/female), Rio (male/female), Yuki.
- Sprites: the base sheets (`assets/art/<char>/<form>_sheet.png`, 128-px cells, feet at y=120) and the move sheets (`*_moves_sheet.png`, 192-px cells).
- Effects: every effect file the code draws for these fighters, from their J attacks, skills (K/L), ultimate (I) and passives, plus the shared ones (guard, parry, hit, landing, status icons). `design/SKILLS.md` lists them per move.
- How they look in the game: `art/clips/<form>/<scene>-fx.webp` and `-nofx.webp` (windowed captures at 30 fps; manifest `art/clips/manifest.json`).

## Criteria, ranked
1. **Reads right in the game.** Things to check:
   - feet on the floor, and no clipping at cell edges
   - frame count and layout that match the code's row table
   - each effect where the code means it, relative to the body and the hit area: size, direction, rotation, layer
   - nothing hidden by another drawing, nothing doubled, nothing below the floor
2. **Readable in motion.** Things to check:
   - the strike drawing is clear, and it lands with the hit (D38 pose clock)
   - the body does not jump between frames
   - effects do not hide the body
   - contrast on the dark arenas
3. **One cast.** The 8 forms and their effects look like one game:
   - outline weight, palette, shading and detail level
   - head ratio and body height (art v2, D33–D36)
   - the effects at the level of the new sprites (ART-66/67)
4. **Cost.** A code fix is cheaper than a redraw. A redraw needs a candidate round and the user's pick.

## Constraints
- Gameplay is the skill session's: do not propose changing hit areas, damage or timing.
  - The start-ups were just lengthened (commits 2188e54, bd8f240, D39 table).
- Art changes only as candidates the user picks (D35 method: one character at a time, grey mannequin for walks, fixed reference frame).
- Recent changes to take as the current state:
  - motion speeds the user adopted (D39, `characters/common/MotionSpeeds.gd`)
  - Yuki's ultimate shows the adopted seal (bceb21f)
  - the guard arc moved from (0,-32) to ahead of the body, centre (24,-58), so it no longer cuts through the body or into the floor (lead fix 2026-10-16)
- Measure where you can (PIL on the sheets and clip frames, the numbers in the code). Mark what is only an opinion.

## Read
- `AGENTS.md`
- `design/DECISIONS.md` D31–D39
- `design/SKILLS.md` (moves, rows, effect files, "이펙트가 따라야 할 값")
- `tools/motion_viewer/README.md`
- `smash-nine-prototype/scripts/Vfx.gd`: `SPECS`, `AUTHORED_WIDTH`, how `spawn` sizes and centres a strip
- `characters/common/PlayerBase.gd`: sheet loading, the pose clock, the guard visual, `_draw_skill_art`
- each character script where it spawns effects
- the sheets and effect files under `smash-nine-prototype/assets/art/`
- the clips under `art/clips/`
