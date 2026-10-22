# CODEX-ART-73 · Story dialogue portraits: three more expressions per form

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 4.
- Story dialogue shows each speaker's face (`scripts/ui/StoryDialogue.gd`, via `ArtSettings.character_portrait`) with one expression for every line.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/art-73` (from the latest main).
- Running at the same time: ART-71 (monsters), ART-72 (character motions), SYS-06 (wiring) in other clones. You share no files.
- **Candidates only, art only.** Nothing under `smash-nine-prototype/` changes. The story code belongs to the story session; wiring comes later.

## The faces
The current faces are 256×256 RGBA, one per form, and are the neutral expression:
- `assets/art/frey/frey_face.png`
- `assets/art/luna/luna_face.png`, `assets/art/luna/luna_brave_face.png`
- `assets/art/yuki/yuki_face.png`
- `assets/art/nova/nova_male_face.png`, `assets/art/nova/nova_female_face.png`
- `assets/art/rio/rio_male_face.png`, `assets/art/rio/rio_female_face.png`

Make three more per form, as **edits of the current face**:
- `happy`: a warm smile, eyes bright or closed in a smile
- `angry`: brows down, a determined or furious glare, mouth set or shouting
- `hurt`: pained or sad, eyes narrowed, a sweat drop or a small scratch allowed

**Edit, don't regenerate.** Load the face with view_image and change only the expression: eyes, brows, mouth, at most a small head tilt.
- Keep exactly: the canvas, the framing, the hair silhouette, the outline weight, the palette, the light and the costume. Only the expression changes.
- If an edit drifts (another face, another style, a different crop), redo it. Up to 3 tries per image.

## Checks (each image)
- 256×256 RGBA, transparent where the neutral face is transparent. No halo, no checkerboard.
- The same person: the eyes, hair parts and accessories line up with the neutral.
  - Make a difference board: the neutral and the new face overlaid at 50%, plus the difference.
  - Outside the face area, almost nothing may differ.
- Readable at the game's display size: shown at 142×164 in the dialogue box. Check a downscaled copy.

## Output
- `art/bakeoff/<folder>/<stem>_face-<expression>-v1.png` + `.json` (`note` in Korean, `expression`, `edited_from`).
- A board per form: `reports/codex-art-73/<stem>-faces.png`, with neutral, happy, angry and hurt at 1× and at display size.
- `reports/codex-art-73/README.md` (Korean), `prompts.txt`.
- `commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
`art/bakeoff/{frey,luna,yuki,nova,rio}/*_face-*-v1.*` (new files only), `art/raw/faces-73/**` (git-ignored), `reports/codex-art-73/**`.

Hard stop: 120 minutes. Forms in the order listed above.
