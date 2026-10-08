# Built-in ImageGen prompts

참조 이미지 `smash-nine/Concept2.png`는 세 프롬프트 모두에서 세계관·픽셀 아트 톤 참고용으로만 사용했습니다. 출력은 실제 게임 파일이 아니라 Godot `Image` API 후처리용 원화입니다.

## Quake source

```text
Use case: stylized-concept
Asset type: source animation sheet for a Godot 4.7 2D pixel-art platform-brawler hazard
Input images: Image 1 is broad worldbuilding and pixel-art tone reference only.
Primary request: create a clean source sheet containing two side-view earthquake hazard animations, arranged in two widely separated horizontal rows. Top row: four consecutive frames of a thin cracking-ground warning pulse, glowing amber-gold fissures traveling across a dark stone platform top, low profile and horizontally tileable rhythm. Bottom row: six consecutive frames of a dust-and-rock impact burst that erupts upward from the floor, readable anticipation-to-peak-to-settle sequence, every burst rooted at the same bottom-center point.
Style/medium: polished 16-bit pixel art, limited palette, chunky intentional pixels, crisp silhouettes, hand-pixeled clusters.
Composition/framing: exact frame boxes visually aligned; generous transparent gutters; no overlap; bottom-center contact point consistent across impact frames.
Color palette: Jotunheim slate navy, cold stone blue-gray, warm amber warning, pale beige dust.
Constraints: genuine transparent background; no scenery; no characters; no labels; no text; no UI; no watermark; each animation fully visible.
Avoid: gradients, smooth painterly blur, anti-aliased edges, photorealism, cropped particles.
```

## Modular hazards source

```text
Use case: stylized-concept
Asset type: source sprite sheet for Godot 4.7 environmental hazards
Input images: Image 1 is broad worldbuilding and pixel-art tone reference only.
Primary request: create three separate side-view fantasy hazards on a single transparent source sheet with very large empty gutters. Left: a long Vanaheim temporary bridge made from braided living vines and roots, flat walkable top, distinct readable curled end caps, tiny buds, and a bright yellow-green 1–2 pixel top rim. Center: an Asgard vertical holy-light column modular set with separate floor impact base, six subtly different straight middle strips, and a sky-fading top cap; white-gold core with pale cyan and navy rune-edge accents; every middle strip has a constant width and vertically repeating visual rhythm. Right: a Muspelheim vertical fire-pillar modular set with separate glowing lava floor base, six subtly different straight middle strips, and a flame-tip top cap; pale yellow core, orange-red flame, dark plum outline; constant width and vertically repeating rhythm.
Style/medium: polished limited-palette 16-bit pixel art, chunky intentional pixels, crisp silhouette, orthographic side view, game-ready VFX source.
Composition/framing: bridge horizontal; columns vertical; isolate every module with transparent space and fully show all pieces.
Constraints: genuine transparent background; no scenery; no characters; no labels; no text; no UI; no watermark.
Avoid: smooth gradients, painterly blur, anti-aliasing, perspective, stretched-looking columns, cropped sprites.
```

## Yuki seal source

```text
Use case: stylized-concept
Asset type: source animation sheet for a planted binding talisman in a Godot 4.7 pixel-art platform-brawler
Input images: Image 1 is broad worldbuilding and pixel-art tone reference only.
Primary request: create four consecutive animation frames of one small floating Japanese paper binding seal waiting in place. Cream rectangular ofuda paper, vermilion brush sigil, dark indigo ink edges, tiny red cord and two small cyan-violet spirit wisps. The paper gently rises and falls while a faint diamond-shaped magic pulse expands and fades behind it; subtle calm idle, not an attack.
Style/medium: polished 16-bit pixel art, limited palette, chunky intentional pixels, crisp silhouette, readable at 64x64.
Composition/framing: four equal square frame boxes in one horizontal row; talisman centered at a consistent bottom-center anchor; wide transparent gutters; no overlap.
Constraints: genuine transparent background; fully visible; no scene; no character; no readable words; no UI; no watermark.
Avoid: placeholder rectangle, oversized shrine gate, smooth gradients, painterly blur, anti-aliasing, cropped wisps.
```
