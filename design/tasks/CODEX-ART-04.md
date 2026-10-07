# CODEX-ART-04 · Original art for the eight outer realms

- Request: 사용자 "원본으로 가고(기존은 애초에 프로토타입), 일단은 기본값으로 설정." and "더 오래 할수 있도록 아직 구현 안된 부분들을 더 추가하여 계획서를 작성." (2026-10-07, 근무 루틴 `routine/2026-10-07-work-2/`, 라운드 2)
- Unit: Builder × 2 · Lead (integrates, decides): Claude
- Running at the same time: the other builder of this card, and the lead editing product source. **This task does not edit product source.**
- Timeout: given in the prompt (about 50 minutes). Deliver finished realms in the order below; a realm with only `bg_far` + `platform_*` done is still useful.

| Unit | Clone | Branch | Realms, in priority order | Writable paths |
| --- | --- | --- | --- | --- |
| A | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine` | `codex/realms-a` | Asgard, Midgard, Niflheim, Alfheim | `smash-nine-prototype/assets/art/realm_{asgard,midgard,niflheim,alfheim}/**`, `smash-nine-prototype/tests/art_preview/realms_a/**`, `reports/codex-art-04a/**` |
| B | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine` | `codex/realms-b` | Muspelheim, Svartalfheim, Vanaheim, Jotunheim | `smash-nine-prototype/assets/art/realm_{muspelheim,svartalfheim,vanaheim,jotunheim}/**`, `smash-nine-prototype/tests/art_preview/realms_b/**`, `reports/codex-art-04b/**` |

## Read first

1. `smash-nine-prototype/assets/art/realm_center/README.md` and its files — **the accepted reference** (center realm, adopted by the user). Same pixel scale, palette discipline and 3-slice platform format.
2. `smash-nine-prototype/scripts/realms/RealmCatalog.gd`: each realm's name, subtitle, theme, identity, background and accent colours, and platform rectangles (outer realms are 1280x720). `scripts/realms/RealmWorld.gd` `_add_painted_backdrop` / `_paint_platform` show exactly how the files are drawn (backgrounds stretched over the realm; platforms as NinePatch with left/right caps and a tiled middle; an accent edge line stays on top).
3. `smash-nine/Concept2.png` (attached) panel 12: Muspelheim (fire), Niflheim (ice), Jotunheim (giants), Vanaheim (nature). The concept was rolled at random at the start: keep each realm's broad identity, redesign details freely.
4. Hazards already in the game (keep the art compatible): Niflheim floors are icy (a frost sheen is drawn over them), Muspelheim has glowing fire vents on platforms, Jotunheim has quakes. Midgard will get **bushes** fighters can hide in.

## Deliverables per realm (PNG RGBA, in `smash-nine-prototype/assets/art/realm_<lowercase name>/`)

| File | Size | Use |
| --- | --- | --- |
| `bg_far.png` | 1280x720, opaque | sky / distance |
| `bg_mid.png` | 1280x720, transparent where empty | silhouettes drawn over bg_far, behind platforms |
| `platform_main.png` | 3-slice strip (left cap, repeatable middle, right cap), height = the realm's tallest main platform (46–54 px) | ground platforms |
| `platform_sub.png` | same format, 32 px tall | thin one-way platforms |
| `README.md` | — | prompts, cap widths in px for both strips, palette, notes |

Unit A only, after its four realms: `realm_midgard/bush.png`, about 160x72, transparent, a dense hedge/bush clump that hides a fighter's lower body when drawn in front of them.

Backgrounds must stay quiet behind the play area (centre band y 150–650): fighters are about 64x128 px on screen and must stay readable. Each realm needs a clearly different dominant hue so a player knows where they are at a glance (use the catalog accent colours as a guide).

## Verification

- A preview script that composes each finished realm at 1280x720 with its real platform rectangles from `RealmCatalog.gd` and a fighter sheet for scale (`assets/art/frey/frey_sheet.png`), screenshotted into the report.
- A contact sheet of all your realms side by side.
- Report measured facts separately from taste. Taste is the user's call.

## Done when

- [ ] Finished realms at the exact paths above
- [ ] `reports/codex-art-04a/README.md` or `reports/codex-art-04b/README.md` in Korean: what was made, cap widths per realm, readability concerns, what a human must judge, what was not done
- [ ] Commit, or `reports/codex-art-04<a|b>/commit.ps1` staging only your writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`
