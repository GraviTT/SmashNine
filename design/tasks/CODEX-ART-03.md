# CODEX-ART-03 · Original character sheets (Yuki, Luna, Nova, Rio)

- Request: 사용자 "원본으로 가고(기존은 애초에 프로토타입), 일단은 기본값으로 설정. 프레이 변경도 좋아. … 특히 캐릭터 스프라이트 좋음." and "캐릭터 컨셉 아트는 어디까지나 처음 정할때 랜덤으로 정해진 것이라 큰 틀만 지키고 세부 컨셉은 완전히 새로 만들어도 된다. 그리고 캐릭터들은 여성은 여성체만, 남성일 경우 남성과 여성체 모두 만들것." (2026-10-07, 근무 루틴 `routine/2026-10-07-work-2/`)
- Unit: Builder × 2 · Lead (integrates, decides): Claude
- Running at the same time: the other builder of this card, and the lead editing product source (Rio is being implemented in `characters/rio/` right now). **This task does not edit product source.**
- Timeout: 75 minutes. Deliver whatever is finished before then, in the priority order below.

| Unit | Clone | Branch | Sheets, in priority order | Writable paths |
| --- | --- | --- | --- | --- |
| A | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine` | `codex/chars-a` | 1 `yuki/yuki_sheet.png` · 2 `nova/nova_male_sheet.png` · 3 `nova/nova_female_sheet.png` | `smash-nine-prototype/assets/art/yuki/**`, `smash-nine-prototype/assets/art/nova/**`, `smash-nine-prototype/tests/art_preview/chars_a/**`, `reports/codex-art-03a/**` |
| B | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine` | `codex/chars-b` | 1 `luna/luna_sheet.png` · 2 `rio/rio_male_sheet.png` · 3 `rio/rio_female_sheet.png` | `smash-nine-prototype/assets/art/luna/**`, `smash-nine-prototype/assets/art/rio/**`, `smash-nine-prototype/tests/art_preview/chars_b/**`, `reports/codex-art-03b/**` |

All sheet paths are under `smash-nine-prototype/assets/art/`. Everything outside your row's writable paths is read-only.

## Read first

1. `AGENTS.md`; `smash-nine-prototype/assets/art/frey/README.md` and `frey_sheet.png` — **the accepted reference**: the user adopted this sheet as the game's art. Match its pixel density, outline weight, figure height and proportions so all fighters read as one roster.
2. Your characters' docs: `smash-nine-prototype/characters/<id>/<Id>.md` (Rio: `design/CHARACTER-05.md`, plan A). They describe what each move does, so the attack and shield rows should look like that character's own moves.
3. `smash-nine/Concept1.png`, `Concept2.png` (attached): panel 8 roster and panel 14 art style. **The concept art was rolled at random at the start. Keep only the broad frame (class, role, world, the gist of the look); you may redesign every detail** (outfit, colours, hair, weapon shape).
4. `tests/art_preview/frey/` (from CODEX-ART-02): how the Frey sheet was cut, cleaned and verified. Reuse the approach.

## Characters (broad frame to keep · gender)

| Id | Frame to keep | Body | Attack row should read as | Shield row should read as |
| --- | --- | --- | --- | --- |
| yuki | Eastern-myth onmyoji (yin-yang mage), controller who throws paper talismans and lays seal wards; slight, nimble | female only | flicking / throwing a talisman forward | a held ward sign, small barrier in front |
| nova | Superhero, "cosmic guard" who turns speed into gravity strikes; sleek suit, teal-to-gold gravity accents | **male and female** (same character: same costume design, palette and emblem; different body) | momentum punch or strike with a gravity streak | forearms crossed in a gravity field |
| luna | Magical girl, star mage with a jewel wand; bright, star motifs; her ultimate turns her into a melee striker | female only | wand swing that draws a star trail | wand raised, small star shield |
| rio | Western-fantasy spellblade assassin, academy prodigy knight; fast sword, blue geometric rune shield, gem swords | **male and female** (same rules as nova) | fast diagonal sword slash with a mana edge | blue geometric rune shield raised |

Give every character a silhouette and palette that differ clearly from Frey (gold/steel Valkyrie) and from each other, so eight small fighters stay readable on dark backgrounds.

## Sheet contract (same as Frey)

| Row (6 columns, 64x64 cells, sheet 384x448 RGBA) | Frames |
| --- | --- |
| 0 idle | 4 |
| 1 walk | 6 |
| 2 jump | 1 |
| 3 fall | 1 |
| 4 attack | 4 (clear wind-up → active → recovery) |
| 5 shield | 6 (frames may repeat) |
| 6 hurt | 1 |

Unused cells transparent. Facing right. Feet at y=48 and body centred at x≈32 in every used frame (the game draws the cell at position (0,-32), scale 2, nearest filter, so feet land on the collision origin). Generate larger and reduce to the 64x64 grid with nearest-neighbour; clean with Godot's Image API from a script; do not install packages or download files.

If all three sheets are done with time left: a 64x64 **portrait** per sheet (`<id>_portrait.png`, or `<id>_male_portrait.png` / `<id>_female_portrait.png`; head and shoulders, same palette, transparent background) for the start screen.

## Verification

- A preview script that cuts each sheet the way `characters/frey/Frey.gd` `configure_character_sprite()` cuts Frey's and screenshots every animation at 2x on a dark background, next to Frey's sheet for scale.
- An alignment table per sheet (feet row and centre x per used frame), like `reports/codex-art-02/alignment.csv`.
- A contact sheet with all your sheets and Frey's side by side.
- Report measured facts separately from taste. Taste is the user's call.

## Done when

- [ ] Sheets in priority order at the exact paths above, each 384x448
- [ ] `<id>/README.md` per character folder (design notes: what was kept from the frame, what was redesigned, palette)
- [ ] `reports/codex-art-03a/README.md` or `reports/codex-art-03b/README.md` in Korean: what was made, alignment tables, consistency issues (especially male vs female variant of the same character), what a human must judge, what was not done
- [ ] Commit, or `reports/codex-art-03<a|b>/commit.ps1` staging only your writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`
