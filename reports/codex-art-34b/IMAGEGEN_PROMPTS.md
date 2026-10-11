# CODEX-ART-34B ImageGen 프롬프트

모드: 내장 `image_gen`, `transparent_background=true`. 각 자산은 해당 런타임 시트 한 장만
정체성·의상·얼굴·팔레트·픽셀 화풍·배율 참조로 사용했다. Luna와 Brave Luna는 1회 생성 후
1차 후보를 채택했다. Nova female은 2회 생성 후 2차 후보, Nova male은 최대 3회 생성 후
3차 후보를 채택했다. 모든 출력은 2172×724 RGBA였다.

## 공통 프롬프트

```text
Use case: stylized-concept
Asset type: production source strip for a Godot 2D pixel-art fighter walk cycle
Primary request: Create exactly seven separate full-body drawings of the same character from the reference sheet in one horizontal image: first the canonical standing idle scale anchor, then six consecutive side-view walk frames in this precise loop order: right-foot contact, down, passing, left-foot contact, down, passing.
Input images: Image 1 is the canonical character sheet and the sole identity, costume, face, palette, pixel-art, and scale reference.
Motion: unmistakable normal walking rather than running or flying; legs alternate clearly with large readable forward/back separation; both boots visible; knees bend in down poses; passing leg crosses under the torso; small vertical body bob; arms counter-swing where the kit allows.
Style/medium: crisp hard-edged hand-drawn pixel art matching Image 1 exactly; every frame is one newly drawn whole character.
Composition/framing: seven non-overlapping sprites evenly spaced left-to-right on a genuinely transparent background; identical ground line; full body visible; generous clear gaps; same scale in all seven drawings.
Constraints: preserve character identity, costume, face, proportions, palette and right-facing direction; one head and one body per frame; face visible in every frame; no pasted or repeated heads or body parts; no attack effects, text, labels, grid, border, floor, shadow, extra objects, duplicate figures, watermark; loop frame 6 naturally back to frame 1.
```

## 자산별 Subject / Motion 추가

- Nova male: `short upswept midnight hair, midnight-indigo fitted suit, pale-silver armor panels, circular chest emblem, teal gauntlets and boots, no cape, no weapon`; relaxed fists counter-swing.
- Nova female: same cosmic-guard costume with `narrower shoulders, defined waist and subtly wider hips`; no cape or weapon.
- Luna: `long hot-pink hair, large midnight-purple bow, short cape/skirt outfit, five-point cyan-and-gold star wand`; free arm counter-swings, wand stays forward/high and clear of legs, hair/cape behind legs; no magic trails or stars.
- Brave Luna: transformed magical brawler with `glowing cyan-violet orb gauntlets on both hands, no staff`; guarded relaxed counter-swing, hair/cape behind legs; no attack effects.

## 보정 라운드

Nova female 2차에는 공통 프롬프트에 다음 요구를 추가했다.

```text
Correction: redraw the same seven-figure strip with a compact chibi body about 2.5 heads tall,
matching the idle anchor's total body height. Keep the head size, identity and costume unchanged;
shorten only the torso and legs, use a small walk bob, and preserve the six-pose order.
```

Nova male 2차에는 같은 짧은 체형 보정을 요청했지만 발 실루엣 변화가 42.5%로 기준에
미달했다. 마지막 3차에는 다음 요구를 추가해 보폭을 넓혔다.

```text
Final correction: keep the compact chibi proportions and anchor-sized head, but make every
successive feet silhouette unmistakably different. Widen both contact poses, show a narrow
under-body passing pose, alternate the leading boot clearly, keep both boots visible, and retain
the exact contact/down/passing/contact/down/passing order without running or attack effects.
```

저장한 원본은 `smash-nine-prototype/tests/art_preview/walk_34/b/*_walk_source.png`이다.

## 리드 재검수 뒤 Nova male 재생성

모드: 내장 `image_gen`, `transparent_background=true`. Image 1은
`before_nova_male_sheet.png`(정체성·팔레트·머리 배율 기준), Image 2는 기존
`nova_male_walk_source.png`(자세 순서·간격 참고)였다.

1차 프롬프트:

```text
Use case: stylized-concept
Asset type: production source strip for a Godot 2D pixel-art fighter walk cycle
Primary request: Regenerate exactly seven separate full-body drawings of the same Nova male
character in one horizontal image: canonical standing idle scale anchor, then six consecutive
right-facing walk frames in this exact order: right-foot contact, down, passing, left-foot
contact, down, passing.
Subject: male gravity superhero; short upswept DARK MIDNIGHT-NAVY HAIR,
BLACK/MIDNIGHT-INDIGO fitted suit, PALE-SILVER armor panels, ELECTRIC-CYAN/TEAL trim only on
gauntlets, boots and small accents, small gold details, circular chest emblem; no cape or weapon.
Motion: unmistakable normal walking, not running or flying; large readable alternating leg
separation; both boots visible; small vertical bob; relaxed fists counter-swing.
Style/medium: crisp hard-edged detailed pixel art matching Image 1. Preserve the idle frame's
line density and facial detail. Every frame is one newly drawn whole character.
Constraints: palette balance must match Image 1 in every frame—hair remains dark navy, suit
remains black/midnight indigo, skin stays localized to face, cyan/teal is trim only and must
never replace hair or suit. One head and one body per frame. No pasted parts, detached pixels,
effects, text, labels, grid, border, floor, shadow, extra objects, duplicates, or watermark.
```

1차 결과는 오른쪽 마지막 전신이 캔버스 끝에 닿아 폐기했다. 2차는 한 가지만 수정했다.

```text
Use case: precise-object-edit
Primary request: Re-render the same seven Nova male full-body pixel-art drawings with identical
identity, palette, detail, proportions and walk-pose order, but fix only the layout safety margins.
Composition/framing: exactly seven separate full-body sprites in one horizontal strip; scale
each figure slightly smaller only if needed so every hair tip, fist and boot is fully visible.
Leave at least 80 transparent pixels at the left and right canvas edges and clear transparent
gaps between every figure. Same ground line.
Constraints: preserve dark midnight-navy hair, black/midnight-indigo suit, pale-silver armor,
cyan/teal trim-only balance, face and crisp line density. Keep exact order: idle, right contact,
down, passing, left contact, down, passing. Change no design or motion. No cropping, overlap,
detached pixels, effects, labels, grid, floor, shadow or watermark.
```

2차 결과를 최종 `nova_male_walk_source.png`로 저장했다. 프로젝트 자산은 내장 도구의 기본
저장 위치에만 남기지 않고 위 workspace 경로로 복사했다.
