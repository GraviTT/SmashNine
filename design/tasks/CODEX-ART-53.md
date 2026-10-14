# CODEX-ART-53 · New main art for Nova (male and female)

- Request: 사용자 2026-10-14 "다음은 Nova." For each redrawn character so far the user also asked for new main art ("둘의 메인 아트를 새로 만들것", "Yuki의 메인 아트도 새로 그려서 넣을것"), so Nova gets it in the same pass. Same job as `CODEX-ART-47.md` and `CODEX-ART-50.md`: follow their spec table. **Candidates only**; the user picks.
- Unit: branch `codex/mainart-53`, clone `SmashNine-units/builder-art/SmashNine`. The Nova sprite unit (`CODEX-ART-51.md`) runs at the same time in `builder-frey`; keep to your files.

## What to make, for each body (`nova_male`, `nova_female`)
- `nova_<body>_illustration.png`: 1024×1536 RGBA, full body, about 6.5–7.5 heads tall, about 88 % of the height, centred, a 3/4 view turned to the viewer's right. Transparent background, clean anti-aliased edges, no fringe.
- `nova_<body>_face.png`: 256×256 cut from it, framed like the installed `frey_face.png`, `luna_face.png` and `yuki_face.png` (eyes at about 40 % height), LANCZOS.
- **Two variants per body**, with different poses and the same design: 4 illustrations.

## Style and design
- **House style = the installed new main art:** `smash-nine-prototype/assets/art/frey/frey_illustration.png`, `luna/luna_illustration.png`, `luna/luna_brave_illustration.png`, `yuki/yuki_illustration.png`. Clean anime illustration, crisp line art, cel shading with soft gradients. Nova must look like the same game.
- Design from the game sprites (`nova_<body>_sheet.png` idle; the design does not change):
  - a dark navy bodysuit with white-silver chest and shoulder armour plates
  - a cyan core on the chest
  - cyan armoured gauntlets and boots with gold accents
  - teal eyes
  - male: short spiky dark-blue hair; female: longer dark-blue hair, the same suit fitted to her
- The current illustrations are face references only.
- A superhero who turns speed into force (`characters/nova/Nova.md`): one variant in a dynamic forward-leaning fighting stance with fists up, one hovering or landing pose with a fist pulled back.
- Avoid text, background, glow halos, energy effects, afterimages, and cropped feet or fists.

## Checks (a wrong arm in Luna's second variant was missed at mid size)
- Look at every illustration **at full size**: arms, hands (fists closed correctly, five fingers where open), gauntlets joining the forearms, feet. List what you checked.
- Size and alpha, no fringe (count 0), nothing cropped.
- Look at the face crops at 2×.

## Output
- `art/bakeoff/nova/main/nova_<body>_illustration-v1.png`, `-v2.png` and `nova_<body>_face-v1.png`, `-v2.png`.
- `reports/codex-art-53/contact.png`: the 4 illustrations at 25 % with their face crops under them, labelled 「Nova 남 1」「Nova 남 2」「Nova 여 1」「Nova 여 2」, plus the installed Frey and Yuki at 25 % for style.
- `reports/codex-art-53/<body>-v<N>/prompt.txt`.
- `reports/codex-art-53/README.md` (Korean) and `commit.ps1` (no `git add -f`, nothing under `art/raw/`).
- Raw generations go to `art/raw/mainart-53/` (git-ignored).

## Writable
`art/bakeoff/nova/main/**`, `art/raw/mainart-53/**`, `reports/codex-art-53/**`. Hard stop 70 minutes.
