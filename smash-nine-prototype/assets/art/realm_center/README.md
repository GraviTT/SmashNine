# Yggdrasil Heart realm art

Godot 4.7용 중앙 렐름 배경/플랫폼/포털 아트 세트다. 모든 최종 PNG는 RGBA이며, 이미지 생성 원본을 Godot `Image` API로 축소·팔레트 제한한 뒤 2배 최근접 확대했다.

## 파일과 그리기 방식

| 파일 | 크기 | 사용법 |
|---|---:|---|
| `bg_far.png` | 1920×1080 | 렐름 로컬 원점 `(0, 0)`에서 1:1 전체 화면으로 그린다. 완전 불투명이다. |
| `bg_mid.png` | 1920×1080 | `bg_far` 위, 플랫폼 아래에 같은 좌표로 알파 합성한다. 중앙 대부분은 투명하다. |
| `platform_main.png` | 236×54 | 3-슬라이스: 왼쪽 54px / 반복 중앙 128px / 오른쪽 54px. 최종 메인 플랫폼은 1500×54다. |
| `platform_sub.png` | 160×32 | 3-슬라이스: 왼쪽 32px / 반복 중앙 96px / 오른쪽 32px. 실제 높이 28/30/32/34px에 최근접 수직 리사이즈한다. |
| `portal.png` | 96×96 | 포털 스탠드 좌표를 이미지 하단 중앙으로 삼아 그린다. 배경은 투명하다. |
| `contact_sheet.png` | 1920×1520 | 위쪽은 RealmCatalog 좌표의 1920×1080 합성 프레임, 아래쪽은 개별 레이어와 스트립 미리보기다. |

Godot에서 `NinePatchRect`를 사용한다면 메인 좌우 패치 마진을 각각 54, 보조 좌우 패치 마진을 각각 32로 두고 가로 축 모드를 `TILE` 또는 `TILE_FIT`으로 둔다. Node2D 기반이라면 중앙 조각만 반복해서 그린 뒤 마지막 반복을 목표 폭에 맞게 잘라 내고 캡을 얹는다. 텍스처 필터는 `NEAREST`, 밉맵은 끄는 편이 의도한 픽셀 그리드를 보존한다.

## 팔레트

후처리에 사용한 24색 RGB 팔레트:

```text
#080611 #0D0A19 #121026 #18132F
#20163A #291B46 #342252 #412A61
#513270 #65417E #79518D #91609A
#A64AA4 #BD5FBA #D47BCE #E79CDD
#29466D #376486 #4F83A0 #68A7B9
#7B633F #A47D4D #C79B61 #E0BD7B
```

투명 자산에는 완전 투명/반투명 알파가 별도로 존재하므로 실제 RGBA 조합 수는 팔레트 수보다 많다.

## 이미지 생성 프롬프트

도구: 내장 `image_gen` 경로. `Concept1.png`, `Concept2.png`는 원경과 중경에서 스타일·팔레트·세계관 참고로만 사용했으며 레이아웃, 로고, 글자, 캐릭터는 복제하지 않도록 제한했다.

### `bg_far.png` 원본

```text
Use case: stylized-concept
Asset type: 2D game environment far-background layer for a 1920x1080 platform-brawler arena
Input images: Image 1 and Image 2 are style, palette, and worldbuilding references only; do not copy their layouts, logos, text, characters, or UI
Primary request: original far background for the central realm "Yggdrasil Heart", the final arena of a fantasy multiverse battle royale
Scene/backdrop: vast dark cosmic indigo sky, distant monumental world-tree silhouette rooted into floating ruins, a restrained glowing magenta-violet heart nested high in the trunk, subtle stars and thin nebula clouds
Style/medium: polished 2D pixel-art environment, coherent limited palette, crisp blocky pixel clusters, atmospheric 2.5D depth; designed large and suitable to reduce to a 960x540 pixel grid then upscale 2x nearest-neighbor
Composition/framing: exact 16:9 landscape; centered symmetrical arena vista; world tree occupies the distant upper half; keep the central fighting band and lower 45 percent calm, dark, low-detail, and low-contrast; no foreground platforms
Lighting/mood: solemn endgame shrine, dark cosmic purple and indigo, restrained cyan rim light and small warm gold accents, no white bloom
Color palette: near-black #090715, deep indigo #15112F, plum #2A1740, muted violet #53346E, restrained magenta #B64FAE, cool cyan #5FA7C8, sparse gold #C79B52
Constraints: fully opaque background; readable behind fighters approximately 64x128 pixels; no bright vertical beam through the combat center; no foreground roots crossing the fight area; no characters; no creatures; no platforms; no UI; no text; no logo; no watermark
Avoid: busy high-frequency texture in the lower half, photorealism, painterly blur, excessive glow, oversaturated neon, pure black void, giant moon, framing borders
```

### `bg_mid.png` 원본

```text
Use case: stylized-concept
Asset type: transparent midground overlay for a 1920x1080 2D pixel-art platform-brawler arena
Input images: Image 1 and Image 2 are style, palette, and worldbuilding references only
Primary request: original sparse midground silhouettes for the central realm "Yggdrasil Heart"
Scene/backdrop: transparent canvas containing only ruined shrine arches at the far left and far right edges, a few dark broken stone spires along the lower sides, and restrained ancient world-tree roots framing the bottom corners
Style/medium: crisp 2D pixel-art environment overlay, limited palette, readable blocky clusters, subtle 2.5D silhouette depth; suitable to reduce to a 960x540 pixel grid and upscale 2x nearest-neighbor
Composition/framing: exact 16:9 landscape; preserve a very large empty transparent center; keep all features behind gameplay platforms; edge-weighted asymmetrical ruins; roots must stay below y=820 equivalent in a 1080 frame and must not cross the central fight space
Lighting/mood: dark indigo and plum silhouettes with very sparse muted violet and cyan rim pixels
Color palette: transparent, #0B0918, #17112A, #261638, #3B2451, sparse #745487 and #4E8194
Constraints: genuinely transparent background everywhere except the isolated ruins and roots; no opaque sky or rectangular backdrop; no world tree canopy; no floating platforms; no gameplay platforms; no characters; no creatures; no portal; no UI; no text; no logo; no watermark
Avoid: bright highlights, center focal point, dense debris, fog filling the canvas, soft painterly edges, semi-transparent full-canvas wash, border frame
```

### `platform_main.png` 원본

```text
Use case: stylized-concept
Asset type: transparent 2D pixel-art game platform source asset
Primary request: a single long main ground platform for the fantasy arena "Yggdrasil Heart"
Subject: heavy ancient dark-stone platform with a perfectly flat horizontal walkable top, beveled side caps, restrained world-tree root motifs and small inset violet crystal seams; designed to become left cap + repeatable middle tile + right cap
Style/medium: crisp side-view 2D pixel-art sprite, limited palette, clean blocky clusters, game-ready silhouette, no anti-aliased painterly blur
Composition/framing: one isolated horizontal platform only, centered, approximately 5:1 width-to-height, orthographic side elevation, fully visible with generous transparent margin; visually symmetric left and right caps; long low-detail middle section
Lighting/mood: subtle top rim light, dark indigo-plum stone, sparse muted magenta and cyan glints
Color palette: #0D0B18, #1A1427, #2B1C38, #463053, #735180, sparse #B15AAE and #5B91A4
Materials/textures: large readable stone blocks, shallow cracks, a few root ridges, clean flat top edge
Constraints: genuinely transparent background; exactly one platform; straight top and bottom alignment; no perspective; no floating debris; no pillars; no characters; no UI; no text; no logo; no watermark; keep fine detail restrained because final height is 54 pixels
Avoid: grass, lava, ice, gold trim, bright glow, ornate center emblem, uneven walkable top, isometric angle, multiple sprite variants
```

### `platform_sub.png` 원본

```text
Use case: stylized-concept
Asset type: transparent 2D pixel-art game one-way platform source asset
Primary request: a single thin floating sub-platform for the fantasy arena "Yggdrasil Heart"
Subject: light ancient dark-stone slab with a perfectly flat horizontal walkable top, small beveled end caps, restrained carved root-vine motif, and only two or three dim violet crystal pixels; designed to become left cap + repeatable middle tile + right cap
Style/medium: crisp side-view 2D pixel-art sprite, limited palette, clean blocky clusters, game-ready silhouette, visibly thinner and simpler than a main ground platform
Composition/framing: one isolated horizontal platform only, centered, approximately 7:1 width-to-height, orthographic side elevation, fully visible with generous transparent margin; symmetric ends; long low-detail repeatable middle
Lighting/mood: subtle top rim light, dark indigo-plum stone, very sparse muted magenta and cyan accents
Color palette: #0D0B18, #1A1427, #2B1C38, #463053, #735180, sparse #A956A7 and #56899A
Materials/textures: simple stone slab blocks, shallow cracks, sparse root-vine line, crisp underside
Constraints: genuinely transparent background; exactly one platform; straight top and bottom alignment; no perspective; no floating debris; no pillars; no characters; no UI; no text; no logo; no watermark; keep detail restrained because final height is 32 pixels
Avoid: thick wall, grass, lava, ice, gold trim, bright glow, center emblem, uneven walkable top, isometric angle, multiple sprite variants
```

### `portal.png` 원본

```text
Use case: stylized-concept
Asset type: transparent 2D pixel-art portal sprite for a platform-brawler
Primary request: original "Yggdrasil Heart" realm portal, a compact ancient stone-and-root arch holding a vertical oval cosmic rift
Subject: squat symmetrical dark stone arch entwined with two roots, centered magenta-violet oval vortex, tiny cyan star motes, clear grounded base
Style/medium: crisp front-facing 2D pixel-art game sprite, limited palette, strong readable silhouette, designed for final display at exactly 96x96 pixels
Composition/framing: single centered portal, square canvas, full object visible with 6-8 pixels equivalent transparent padding, no cast shadow beyond the base
Lighting/mood: restrained magical violet core, dark indigo frame, sparse cyan rim pixels, no large bloom
Color palette: #0B0915, #1C1430, #35204B, #684080, #B24DB4, #E58AE3, sparse #64B4CA
Constraints: genuinely transparent background; one portal only; no separate floor platform; no characters; no text; no UI; no logo; no watermark; opaque readable frame with controlled semi-transparent energy only inside the oval
Avoid: circular button icon, photorealism, painterly blur, huge glow halo, white center, busy particles, multiple portal variants
```

## 후처리

`tests/art_preview/realm/build_assets.gd`가 생성 원본을 불러 다음을 수행했다.

1. 배경을 16:9로 중앙 크롭하고 960×540으로 축소
2. 위 24색 팔레트로 가장 가까운 색에 매핑
3. 투명 자산의 알파를 0/0.5/1 단계로 정리
4. 모든 최종 아트를 2배 최근접 확대
5. 플랫폼 원본을 캡/중앙/캡으로 잘라 중앙 타일 양 끝 픽셀 열을 동일하게 보정
6. RealmCatalog의 실제 플랫폼/포털 좌표로 합성 프레임과 컨택트 시트 생성

생성 원본은 Codex 이미지 생성 저장소에 남아 있으며 프로젝트에는 최종 아트만 포함한다.
