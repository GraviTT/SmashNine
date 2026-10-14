# CODEX-ART-47 · New main art for Frey, Luna and Brave Luna (candidates for the user to pick)

- Request: 사용자 2026-10-14 "Luna와 B!Luna 모두 매우 만족스럽다 … 둘의 메인 아트를 새로 만들것." The lead reads "둘" as Frey and Luna (the two redrawn characters). Brave Luna's design changed (D36), so she gets main art too. **Candidates only**; nothing in `smash-nine-prototype/` changes. The user picks and the lead installs.
- Unit: branch `codex/mainart-47`, clone `SmashNine-units/builder-art/SmashNine`. A Yuki sprite unit (`CODEX-ART-48.md`) runs at the same time in `builder-frey`; keep to your files.

## What main art is (D25)
- `<stem>_illustration.png`: 1024×1536 RGBA, a full-body illustration about 6.5–7.5 heads tall. It is used later for character select.
- `<stem>_face.png`: 256×256, the face and shoulders cut from that illustration. It is the portrait on the HUD and on the start and result screens (`scripts/ArtSettings.gd`), and the ultimate cut-in.

## Spec (every illustration)

| Item | Value |
| --- | --- |
| Size | 1024×1536 RGBA, transparent background with clean anti-aliased edges (soft alpha is right here, unlike sprites) and no colour fringe |
| Framing | full body, head to boots, about 88 % of the height, centred, a 3/4 view turned to the viewer's right like the game sprites |
| Style | **one house style for all three**: clean anime illustration, crisp line art, cel shading with soft gradients, saturated but not neon. Frey's and Luna's current illustrations differ in finish; the new ones must look like one game. |
| Must match the new sprites exactly | Frey: `art/bakeoff/frey/frey-idle-v2.png`. Luna: `art/bakeoff/luna/luna-idle-v3.png`. Brave Luna: `art/bakeoff/luna/luna_brave-idle-v4.png` (D36). Same hair, colours, costume parts and emblems; the current illustrations are references for faces only. |
| Avoid | text, logos, background, ground, glow halos, sparkles, light trails or magic effects, cropped feet or weapon, extra fingers or broken hands |

Character notes:
- **Frey:** long blonde hair, blue eyes, silver winged circlet with white wings, silver plate armour with gold trim, blue cape with gold four-point stars, round blue shield with a gold star, sword with a gold crossguard, brown boots. A valiant valkyrie stance.
- **Luna:** long pink hair, magenta eyes, purple bow with a gold star, purple magical-girl dress with white frills and gold stars, star wand, purple boots. Bright and cheerful.
- **Brave Luna (②):** the same face, with a high pink ponytail tied with the purple bow and gold star. Sleeveless top, short skirt over shorts, short scarf in Luna's purples and white. Purple-and-gold armoured gauntlets to the forearm, armoured boots with star knee guards. A confident brawler pose, fists up.

## Variants and face crops
- **Two variants per character**, with different poses and the same design: 6 illustrations.
- From each illustration, cut its 256×256 face the way the current `<stem>_face.png` frames it (eyes at about 40 % height, head and a little of the shoulders), with a LANCZOS downscale.

## Checks
- size and alpha
- no fringe: count pixels within 2 px of transparency whose colour matches the key you removed; report the count, which must be 0
- feet and weapon not cropped
- the design matches the sprite: list each item you checked
- look at every illustration at full size and every face at 2×

## Output
- `art/bakeoff/<id>/main/<stem>_illustration-v<N>.png` and `<stem>_face-v<N>.png`. Stems: `frey`, `luna`, `luna_brave`; N = 1, 2.
- `reports/codex-art-47/contact.png`: all 6 illustrations side by side at 25 % with their face crops under them, labelled 「Frey 1」 … 「Brave Luna 2」. The user picks from this.
- `reports/codex-art-47/<stem>-v<N>/prompt.txt`.
- `reports/codex-art-47/README.md` (Korean): per variant, what pose and what is still wrong.
- `commit.ps1` (no `git add -f`, nothing under `art/raw/`).
- Raw generations go to `art/raw/mainart-47/` (git-ignored).

## Writable
`art/bakeoff/frey/main/**`, `art/bakeoff/luna/main/**`, `art/raw/mainart-47/**`, `reports/codex-art-47/**`. Hard stop 70 minutes.
