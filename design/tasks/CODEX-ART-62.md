# CODEX-ART-62 · New main art for Rio (male and female)

- Request: 사용자 2026-10-15 "…이후 Rio의 스프라이트 리메이크 진행. 완성 될 때 까지 루틴으로. 단, … 성공한 사례만 따라갈것." Every remade character got new main art (Frey, Luna, Yuki, Nova), so Rio gets it in the same pass, exactly as Nova's `CODEX-ART-53.md` (and `reports/codex-art-53/`). **Candidates only**; the user picks.
- Unit: branch `codex/mainart-62`, clone `SmashNine-units/builder-art/SmashNine`. The Rio row units (`CODEX-ART-61.md`) run at the same time in `builder-frey` and `builder-ui`; keep to your files.

## What to make, for each body (`rio_male`, `rio_female`)
- `rio_<body>_illustration.png`: 1024×1536 RGBA, full body, about 6.5–7.5 heads tall, about 88 % of the height, centred, a 3/4 view turned to the viewer's right. Transparent background, clean anti-aliased edges, no fringe.
- `rio_<body>_face.png`: 256×256 cut from it, framed like the installed `frey_face.png`, `yuki_face.png` and `nova_male_face.png` (eyes at about 40 % height), LANCZOS.
- **Two variants per body**, with different poses and the same design: 4 illustrations.

## Style and design
- **House style = the installed new main art:** `smash-nine-prototype/assets/art/frey/frey_illustration.png`, `luna/luna_illustration.png`, `luna/luna_brave_illustration.png`, `yuki/yuki_illustration.png`, `nova/nova_male_illustration.png`, `nova/nova_female_illustration.png`. Clean anime illustration, crisp line art, cel shading with soft gradients. Rio must look like the same game.
- Design from the new anchors (`art/bakeoff/rio/rio_<body>-idle-v2.png`; the design does not change):
  - black armour with cyan trim lines and small cyan gems
  - a dark cape with a blue inner lining
  - a straight sword with a bright blue blade (no glow halo)
  - blue eyes
  - male: spiky dark-blue hair; female: a long high dark-blue ponytail with a cyan tie
- The current illustrations are face references only.
- A magic-sword assassin from a knight academy (`characters/rio/Rio.md`): one variant in a low forward guard with the sword held out, one mid-blink slash pose with the cape swept back.
- Avoid text, background, glow halos, energy effects, mana waves, runes, afterimages, and cropped feet, hands or blade.

## Checks (a wrong arm in Luna's second variant was missed at mid size)
- Look at every illustration **at full size**: arms, hands (five fingers, the grip on the hilt correct), the sword in one piece, the cape attached, feet. List what you checked.
- Size and alpha, no fringe (count 0), nothing cropped.
- Look at the face crops at 2×.

## Output
- `art/bakeoff/rio/main/rio_<body>_illustration-v1.png`, `-v2.png` and `rio_<body>_face-v1.png`, `-v2.png`.
- `reports/codex-art-62/contact.png`: the 4 illustrations at 25 % with their face crops under them, labelled 「Rio 남 1」「Rio 남 2」「Rio 여 1」「Rio 여 2」, plus the installed Frey and Nova male at 25 % for style.
- `reports/codex-art-62/<body>-v<N>/prompt.txt`.
- `reports/codex-art-62/README.md` (Korean, short) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`, no `__pycache__`).
- Raw generations go to `art/raw/mainart-62/` (git-ignored).

## Writable
`art/bakeoff/rio/main/**`, `art/raw/mainart-62/**`, `reports/codex-art-62/**`. Hard stop 60 minutes.
