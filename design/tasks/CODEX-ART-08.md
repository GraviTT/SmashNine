# CODEX-ART-08 · Hi-res sprite sheets with per-character proportions, main illustrations, face portraits

- Request (2026-10-07, user): "1. 등신대 제안대로 진행. 2. 해상도 제안대로 진행. 3. 초상화는 위에 말 한 대로" — "인게임 초상화는 아예 그 캐릭터의 6~8등신 메인 일러스트를 말 하는 것. 거기서 얼굴만 띄워서 초상화로 쓰고 전신은 캐릭터 선택창(추후 제작)에서 사용할 예정이야." Earlier: "캐릭터 컨셉 아트는 … 큰 틀만 지키고 세부 컨셉은 완전히 새로 만들어도 된다", "여성은 여성체만, 남성일 경우 남성과 여성체 모두".
- Unit: Builder × 2 · Lead (integrates, decides): Claude
- Running at the same time: the other builder of this card; the lead edits product source. **This task does not edit product source.**
- Timeout: given in the prompt. Work character by character in the order of your row; a finished character beats several half-finished ones.

| Unit | Clone | Branch | Characters, in order | Writable paths |
| --- | --- | --- | --- | --- |
| A | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine` | `codex/hires-a` | Frey (female), Nova male, Nova female, Yuki (female) | `smash-nine-prototype/assets/art/{frey,nova,yuki}/**`, `smash-nine-prototype/tests/art_preview/hires_a/**`, `reports/codex-art-08a/**` |
| B | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine` | `codex/hires-b` | Rio male, Rio female, Luna (female) + Brave Luna sheet | `smash-nine-prototype/assets/art/{rio,luna}/**`, `smash-nine-prototype/tests/art_preview/hires_b/**`, `reports/codex-art-08b/**` |

## Keep the accepted designs

The user accepted the current original sprites (`assets/art/<id>/*_sheet.png`, made by CODEX-ART-02/03/06). Keep each character's outfit, palette, hair, weapon and silhouette ideas. What changes is **proportion and detail**: no more 2-head chibi.

## Per character, three deliverables

### 1. Main illustration (defines the character at full detail)

- `<id>_illustration.png` (female-only characters) or `<id>_<body>_illustration.png` (Nova, Rio): 1024x1536, transparent background, full body, **6.5–7.5 heads tall**, dynamic but readable standing pose with the signature weapon or magic. Painted anime-fantasy illustration (not pixel art), same design and colours as the sprites. Male and female variants of the same character share outfit, palette and gear.
- It will be used later, full body, on a character select screen. It is not shipped in the web build for now.

### 2. Face portrait (cut from the illustration)

- `<id>_face.png` / `<id>_<body>_face.png`: 256x256, head and a little of the shoulders, cropped from the illustration (same art, not redrawn), transparent background, face centred and looking slightly to the right. Shown in the in-game HUD at about 64–96 px.

### 3. Hi-res sprite sheet (replaces the current 64 px sheet at the same file name)

| | Old (v1) | **New (v2)** |
| --- | --- | --- |
| Sheet | 384x448 | **768x896** |
| Cells | 6 x 7 of 64x64 | **6 x 7 of 128x128** |
| Drawn in game at | 2x | **1x** (twice the pixel detail) |
| Feet line | y=48 | **y=120**, centre x≈64 in every used frame |

Rows unchanged: 0 idle 4, 1 walk 6, 2 jump 1, 3 fall 1, 4 attack 4, 5 shield 6, 6 hurt 1. Unused cells transparent. Facing right. File names unchanged: `frey_sheet.png`, `yuki_sheet.png`, `nova_male_sheet.png`, `nova_female_sheet.png`, `rio_male_sheet.png`, `rio_female_sheet.png`, `luna_sheet.png`, `luna_brave_sheet.png`.

**Proportions and height (feet to top of head, excluding hair spikes, helmet wings and weapons) in sheet pixels:**

| Character | Heads | Height |
| --- | --- | --- |
| Frey | 3 | 100 px |
| Rio (male / female) | 3 | 98 px / 96 px |
| Nova (male / female) | 2.5 | 92 px / 90 px |
| Yuki | 2.5 | 88 px |
| Luna, Brave Luna | 2.2 | 84 px |

Pixel art, nearest-neighbour, 1 px outline, limited palette per character, readable at 1x on dark backgrounds. Longer limbs are the point: the attack and shield rows must show the move clearly (see `characters/<id>/<Id>.md` and `characters/rio/Rio.md`). Use the new illustration as the design reference so sprite and portrait match. Generate large, reduce with nearest-neighbour, clean and align with Godot's Image API from a script; do not install packages or download files.

## Verification

- Alignment table per sheet (feet row, centre x, measured head height per frame) like `reports/codex-art-02/alignment.csv`.
- A contact sheet per unit: for each character the old v1 sheet at 2x, the new v2 sheet at 1x, the face portrait and a reduced illustration, side by side.
- Report measured facts separately from taste. Taste is the user's call.

## Done when

- [ ] For each character in your row: illustration, face portrait, v2 sheet (Unit B: also `luna_brave_sheet.png` v2; a Brave Luna illustration only if time is left)
- [ ] `reports/codex-art-08a/README.md` or `reports/codex-art-08b/README.md` in Korean: what was made, alignment and height tables, consistency between illustration, face and sprite, what a human must judge, what was not done
- [ ] Commit, or `reports/codex-art-08<a|b>/commit.ps1` staging only your writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`
