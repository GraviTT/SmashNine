# CODEX-ART-05 · Monsters, soul crystal, effects and card icons

- Request: 사용자 "더 오래 할수 있도록 아직 구현 안된 부분들을 더 추가하여 계획서를 작성. 특히 캐릭터 스프라이트 좋음." (2026-10-07, 근무 루틴 `routine/2026-10-07-work-2/`, 라운드 3 — 라운드 1·2가 예상보다 빨리 끝나 남는 시간 작업으로 추가)
- Unit: Builder × 2 · Lead (integrates, decides): Claude
- Running at the same time: the other builder of this card, and the lead editing product source. **This task does not edit product source.**
- Timeout: given in the prompt. Deliver finished items in the order below.

| Unit | Clone | Branch | Items, in priority order | Writable paths |
| --- | --- | --- | --- | --- |
| A | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-art/SmashNine` | `codex/monsters-a` | 1 Mossling sheet · 2 Ember Imp sheet · 3 Ember Imp fireball · 4 soul crystal | `smash-nine-prototype/assets/art/monsters/**`, `smash-nine-prototype/assets/art/objects/**`, `smash-nine-prototype/tests/art_preview/monsters_a/**`, `reports/codex-art-05a/**` |
| B | `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine` | `codex/effects-b` | 1 hit spark · 2 projectiles (Yuki talisman, Luna star, Rio mana wave, Rio gem sword, Nova gravity orb) · 3 soul card icons | `smash-nine-prototype/assets/art/effects/**`, `smash-nine-prototype/assets/art/ui/**`, `smash-nine-prototype/tests/art_preview/effects_b/**`, `reports/codex-art-05b/**` |

## Read first

1. The accepted references (the user adopted the original art): `assets/art/frey/frey_sheet.png`, the new sheets in `assets/art/{yuki,luna,nova,rio}/`, `assets/art/realm_center/`. Match their pixel density, outline weight and palette discipline.
2. Unit A: `smash-nine-prototype/scripts/RealmMonster.gd` (two kinds: `mossling` melee 42x44 collision, `ember_imp` ranged 36x52 collision; feet at y=0; neutral until hit, then aggressive). Unit B: `scripts/Projectile.gd`, `scripts/Attack.gd`, `characters/common/PlayerBase.gd` `_spawn_hit_effect`, the character docs `characters/*/*.md` (what each projectile is), `scripts/match/SoulCards.gd` (the six cards).
3. `smash-nine/Concept2.png` (attached) panel 9 (soul crystal, monster) and panel 14 (art style). The concept was rolled at random: keep the broad frame, redesign details freely.

## Deliverables

All PNG RGBA, transparent background, nearest-neighbour pixel art, drawn at scale 2 in game unless noted.

Unit A (`assets/art/monsters/`, `assets/art/objects/`):

| File | Size | Contract |
| --- | --- | --- |
| `monsters/mossling_sheet.png` | 384x256 (6 columns x 4 rows of 64x64) | rows: 0 idle 4 frames, 1 walk 6, 2 attack 4 (a lunging bite or slam), 3 hurt 1. Facing right, feet at y=48, centred x≈32. A small mossy forest critter, friendly-looking but clearly a target |
| `monsters/ember_imp_sheet.png` | same layout | rows as above; attack = throwing a fireball forward. A small fire imp with horns |
| `monsters/ember_fireball.png` | 24x24 | the imp's projectile, facing right |
| `objects/soul_crystal.png` | 192x64 (4 frames of 48x64) | a floating purple soul crystal, 4-frame shimmer loop; bottom of the crystal at y≈56 |
| `objects/soul_crystal_shatter.png` | 192x64 (4 frames of 48x64) | the crystal breaking into shards |

Unit B (`assets/art/effects/`, `assets/art/ui/`):

| File | Size | Contract |
| --- | --- | --- |
| `effects/hit_spark.png` | 192x48 (4 frames of 48x48) | white-gold impact burst, centred, readable on any background |
| `effects/yuki_talisman.png` | 32x16 | paper talisman flying right |
| `effects/luna_star.png` | 24x24 | bright star bolt |
| `effects/rio_mana_wave.png` | 24x56 | crescent blue mana wave flying right (game hitbox 24x54) |
| `effects/rio_gem_sword.png` | 48x16 | small gem sword pointing right, greyscale or white so the game can tint it (six colours) |
| `effects/nova_gravity_orb.png` | 32x32 | teal-to-gold gravity orb |
| `ui/card_<id>.png` | 48x48 each | icons for the soul cards: power, vitality, swiftness, anchor, sky_step, last_stand (see SoulCards.gd) — drawn at scale 1 in the card panel |

## Verification

- A preview script composing every item at its game scale on a dark background next to a fighter sheet for scale; screenshot into the report.
- For sheets: alignment table (feet row and centre x per used frame).
- Report measured facts separately from taste. Taste is the user's call.

## Done when

- [ ] Items in priority order at the exact paths above, `README.md` in each folder you created (prompts, palette, how each file is meant to be drawn)
- [ ] `reports/codex-art-05a/README.md` or `reports/codex-art-05b/README.md` in Korean: what was made, verification, what a human must judge, what was not done
- [ ] Commit, or `reports/codex-art-05<a|b>/commit.ps1` staging only your writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`
