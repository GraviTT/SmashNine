# CODEX-ART-80 · Story dialogue: shadow boss portraits (eight forms)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 4 ("그림자 보스도 넣는다").
- In stage 9 each hero meets their own shadow (`design/STORY.md`: "주인공의 그림자, 어두운 색조, 오른쪽"; the shadow speaks "차갑고 짧게"). Today the dialogue box shows the hero's own face tinted purple (`scripts/ui/StoryDialogue.gd`, `Color(0.42, 0.24, 0.62)`), and the shadow fighters in the game are the hero sprites with the same tint (`scripts/story/StorySession.gd` `SHADOW_TINT`).
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/art-80` (from the latest main).
- Running at the same time: SYS-08 (Godot) in analyst. You share no files. Do not run Godot.
- **Candidates only, art only.** Nothing under `smash-nine-prototype/` changes. The wiring comes in another card.

## What to make
For each form, a shadow version of the current neutral face, as an **edit** of it (the ART-73 method: `reports/codex-art-73/README.md`):
- `assets/art/frey/frey_face.png`, `assets/art/luna/luna_face.png`, `assets/art/luna/luna_brave_face.png`, `assets/art/yuki/yuki_face.png`, `assets/art/nova/nova_male_face.png`, `assets/art/nova/nova_female_face.png`, `assets/art/rio/rio_male_face.png`, `assets/art/rio/rio_female_face.png`

The shadow:
- the same person, framing, hair silhouette and costume shapes (it is a copy made by the heart of Yggdrasil)
- dark, cold colours: near-black violet and blue-grey with the purple of the game's shadow tint (0.42, 0.24, 0.62) as the key colour; little or no warm colour
- the eyes glow (one bright cold colour; pick per form so each reads different from the hero's own eye colour); a cold, flat expression
- a faint dark mist or ragged edge at the outer silhouette is allowed; no text, no frame, no background (transparent where the neutral face is transparent)

It must read as "the hero's shadow" at the dialogue size (142×164) next to the hero's own face on the left.

## Checks
- 256×256 RGBA, transparent where the neutral face is transparent, no halo, no checkerboard.
- The same person: overlay at 50% with the neutral; the outline and features line up (a small offset is fine; say it).
- A board per form: `reports/codex-art-80/<stem>-shadow.png` — the neutral, today's tinted face (the neutral multiplied by the tint), and the new shadow, at 1x and at 142×164; plus one mock of the dialogue box with the hero on the left and the shadow on the right.
- Up to 3 tries per form.

## Output
- `art/bakeoff/<folder>/<stem>_face-shadow-v1.png` + `.json` (`note` in Korean, `expression: "shadow"`, `edited_from`).
- `reports/codex-art-80/README.md` (Korean), `prompts.txt`, an overview board of all eight.
- `commit.ps1`: only your files, no `git add -f`, nothing under `art/raw/`, no `__pycache__`, no `run.log`.

## Writable
`art/bakeoff/{frey,luna,yuki,nova,rio}/*_face-shadow-v1.*` (new files), `art/raw/faces-80/**` (git-ignored), `reports/codex-art-80/**`.

Hard stop: 120 minutes. Forms in the order listed above.
