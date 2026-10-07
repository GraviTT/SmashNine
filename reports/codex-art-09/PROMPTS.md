# CODEX-ART-09 ImageGen 기록

도구: Codex built-in ImageGen (`transparent_background: true`). CLI/API, 외부 다운로드, 패키지 설치는 사용하지 않았다.

참조 이미지:

- `review_contacts/frey_review_4x.png`
- `review_contacts/nova_female_review_4x.png`
- `review_contacts/luna_brave_review_4x.png`
- `review_contacts/rio_male_review_4x.png`

최종 프롬프트:

```text
Use case: stylized-concept
Asset type: production pixel-art VFX repair source for a 2D platform-brawler sprite sheet
Input images: Image 1 Frey enlarged sprite contact; Image 2 Nova female enlarged sprite contact; Image 3 Brave Luna enlarged sprite contact; Image 4 Rio male enlarged sprite contact. Use them only as palette and pixel-style references.
Primary request: Create one clean transparent atlas of sixteen isolated compact motion-effect sprites arranged as four evenly spaced rows of four. Row 1: Frey white/silver sword streaks with pale-blue edge and tiny gold accent. Row 2: Nova cyan/teal gravity punch crescents with small warm-yellow impact cores. Row 3: Luna/Brave Luna pink-purple-blue star crescents and small starbursts. Row 4: Rio cyan-blue sword crescents and small rune shield sparks.
Style/medium: crisp hand-pixelled 2D game effects, limited palette, dark one-pixel outline where useful, readable when reduced to roughly 24–44 pixels.
Composition/framing: every effect is fully isolated, centered in its own imaginary square cell, generous transparent space between effects and around the entire atlas. Natural curved or pointed taper at every endpoint.
Constraints: genuinely transparent background; effects only, no characters, no weapons, no text, no grid, no labels, no scenery, no shadows; every effect fully inside canvas with large margin; no vertical or horizontal flat cut edges; no neighboring fragments; no color halo; four distinct animation-progress shapes per row from small startup to active arc to fading recovery.
Avoid: cropped effects, checkerboard painted into the image, blurred glow clouds, photorealism, anti-aliased matte, duplicated characters, watermark.
```

생성 원본은 `sprite_effect_fix_source.png`로 저장했다. 최종 적용 시 Godot `Image` API에서 셀 추출, 최근접 축소, 알파 이진화, 캐릭터별 제한 팔레트 스냅을 수행했다. 생성 원본의 큰 글로우나 매트는 그대로 사용하지 않았다.

