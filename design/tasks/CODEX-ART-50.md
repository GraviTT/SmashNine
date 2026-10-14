# CODEX-ART-50 · New main art for Yuki

- Request: 사용자 2026-10-14 "Yuki의 메인 아트도 새로 그려서 넣을것." Same job as `CODEX-ART-47.md` (Frey, Luna, Brave Luna): read its spec table and follow it. **Candidates only**; the lead installs the better one after a full-size check and shows the user both.
- Unit: branch `codex/mainart-50`, clone `SmashNine-units/builder-art/SmashNine`. No other unit runs.

## What to make
- `yuki_illustration.png`: 1024×1536 RGBA, full body, about 6.5–7.5 heads tall, about 88 % of the height, centred, a 3/4 view turned to the viewer's right. Transparent background with clean anti-aliased edges and no fringe.
- `yuki_face.png`: 256×256, cut from it the way the faces in `smash-nine-prototype/assets/art/frey/frey_face.png` and `luna_face.png` are framed (eyes at about 40 % height, head and a little shoulder), with a LANCZOS downscale.
- **Two variants**, with different poses and the same design.

## Style and design
- **The house style is the installed new main art.** Look at `smash-nine-prototype/assets/art/frey/frey_illustration.png`, `luna_illustration.png` and `luna_brave_illustration.png`: clean anime illustration, crisp line art, cel shading with soft gradients. Yuki must look like the same game.
- The design matches the new sprite `art/bakeoff/yuki/yuki-idle-v2.png`, now in the game:
  - long black hair with a violet sheen
  - a red bow with white dots and a gold bell ornament
  - red eyes
  - a red-and-black onmyoji outfit with long white sleeves
  - red paper talismans with gold marks, a fan of them in one hand
  - dark boots
- The current `yuki_illustration.png` is a face reference only.
- A calm, poised onmyoji controller, as in `characters/yuki/Yuki.md`: one variant holding the talisman fan ready, the other with a talisman raised between two fingers.
- Avoid text, background, glow, magic effects, flying talismans away from her hands, and cropped feet or sleeves.

## Checks (Luna's second variant had a wrong arm that a mid-size look missed)
- Look at every illustration **at full size**: arms, hands (five fingers, a natural grip on the talismans), sleeves joining the arms, feet. List what you checked.
- Size and alpha, no fringe (count 0), nothing cropped.
- Look at the face crops at 2×.

## Output
- `art/bakeoff/yuki/main/yuki_illustration-v1.png`, `-v2.png` and `yuki_face-v1.png`, `-v2.png`.
- `reports/codex-art-50/contact.png`: both illustrations at 25 % with their face crops under them, labelled 「Yuki 1」「Yuki 2」, next to the installed Frey and Luna illustrations at 25 % for style.
- `reports/codex-art-50/<v1|v2>/prompt.txt`.
- `reports/codex-art-50/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).
- Raw generations go to `art/raw/mainart-50/` (git-ignored).

## Writable
`art/bakeoff/yuki/main/**`, `art/raw/mainart-50/**`, `reports/codex-art-50/**`. Hard stop 50 minutes.
