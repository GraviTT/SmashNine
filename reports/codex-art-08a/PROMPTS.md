# ImageGen prompt record

Built-in ImageGen을 사용했다. 아래는 최종 생성에 사용한 프롬프트 세트의 핵심 규격이다. 모든 호출은 `transparent_background: true`였고, 각 캐릭터의 기존 `*_generated_source.png`와 `*_sheet.png`를 디자인 참조로 넣었다.

## 공통 메인 일러스트 프롬프트

```text
Use case: stylized-concept
Asset type: full-body character-select illustration for Smash Nine Realms
Scene/backdrop: genuinely transparent, isolated character only
Composition: entire figure visible, dynamic readable standing pose facing slightly right, centered safe margins
Style: premium painted anime fantasy/superhero game key art, crisp silhouette, detailed materials
Constraints: 1024x1536, adult, 6.5–7.5 heads tall, accepted outfit/palette/hair/gear preserved, no text/logo/scenery/cropping/extra limbs
Avoid: chibi, giant head, childlike body, photorealism, pixel art, background filling the canvas
```

- Frey: long golden-blonde hair, silver winged helmet, navy/silver/gold armor, royal-blue cape, broad sword and round star shield.
- Nova male: upswept midnight hair, indigo/silver suit, teal gravity gauntlets/boots, circular chest emblem, athletic masculine build, no cape/weapon.
- Nova female: same Nova equipment and coverage, narrower shoulders, defined waist and slightly wider hips, no sexualized redesign.
- Yuki: black-violet high ponytail, red-white cord and gold clasp, plum/vermilion/ivory shrine coat, talismans, compact red-gold ward.

## 공통 v2 시트 프롬프트

```text
Use case: stylized-concept
Asset type: production pixel-art animation atlas source for Smash Nine Realms
Primary request: strict 6-column by 7-row sprite atlas matching the accepted sprites and new illustration
Scene/backdrop: genuinely transparent
Style: crisp hand-pixelled 2D sprite art, limited palette, one-pixel dark outline at final scale, readable at 1x
Rows: idle 4; run/walk 6; jump 1; fall 1; attack 4; shield 6; hurt 1; remaining cells transparent
Composition: facing right, stable feet baseline, every figure and effect fits its square cell
Constraints: exactly 23 used frames, no grid/text/labels/shadows/scenery, accepted costume unchanged
Avoid: old 2-head chibi proportions, giant head, blurry scaling, checkerboard or white background
```

- Frey: 3-head proportion; attack wind-up/rising cut/active horizontal cut/recovery; shield visibly forward.
- Nova male/female: 2.5-head proportion; momentum punch with teal-to-gold impact; crossed forearms in compact gravity field.
- Yuki: 2.5-head proportion; talisman flick and paper trail; hand sign with red-gold rectangular ward.

## CODEX-ART-08R rework prompts (built-in ImageGen)

각 생성 호출은 기존 `*_v2_source.png`를 편집 대상으로, 승인된 `*_illustration.png`를 디자인/체형 참조로 사용했다. 공통 지시는 다음과 같다.

> Preserve the exact 6-column by 7-row layout and 23 used frames (idle 4, walk 6, jump 1, fall 1, attack 4, shield 6, hurt 1). Redraw the character with longer legs and torso and a smaller, narrower head at the requested 3-head or 2.5-head proportion. Keep costume, palette, weapon or magic, facing direction and animation meaning. Use crisp high-resolution pixel art on a transparent background. Keep every character, weapon and effect inside its own cell with generous transparent padding. No colored matte, fringe, halo, text, grid or watermark.

캐릭터별 추가 조건:

- Frey: 3 heads, winged silver helm, navy/gold armor, cape, sword and round shield.
- Nova 남성: 2.5 heads, swept navy hair, navy/white tech armor, cyan gravity gauntlets and compact energy effects.
- Nova 여성: 2.5 heads, female athletic silhouette, navy hair, shared Nova armor/gauntlets and compact energy effects.
- Yuki: 2.5 heads, long black hair with red ornaments, black/red/ivory robes, paper talismans and compact red-gold ward barriers.

생성 원본은 각각 `frey_v2_source.png`, `nova_male_v2_source.png`, `nova_female_v2_source.png`, `yuki_v2_source.png`에 저장했고, 최종 시트는 Godot `Image` API 후처리 결과다.
