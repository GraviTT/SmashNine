# 스토리 연출 아트 · ART-70

2026-10-22. 내장 image_gen으로 14개 원본을 만들고 Pillow로 규격을 맞췄다. 이 폴더에는 선택본 6개와 각각의 수정하지 않은 *_source.png만 둔다. 게임 연결은 리드가 한다.

| 파일 | 규격 | 사용 위치 / 선택 이유 |
|---|---|---|
| cg_prologue.png | 1600×900 RGB | 1안: 심장 균열·수평 충격파와 왼쪽 두 섬의 실제 충돌이 가장 빠르게 읽힌다. |
| cg_root.png | 1600×900 RGB | 3안: 얼음 뿌리의 S자 하강, 크게 끊어진 봉인 고리와 바깥으로 흩어지는 부적이 명확하다. 하단도 가장 어둡다. |
| cg_epilogue.png | 1600×900 RGB | 1안: 온전한 밝은 심장, 수평으로 안정된 섬, 끊기지 않은 폭포와 따뜻한 새벽으로 전후 대비가 명확하다. |
| dialogue_frame.png | 480×120 RGBA / 9-slice 24px | 1안: 기존 result_panel의 날개·금색 장식과 작은 푸른 마름모가 가장 잘 이어진다. |
| name_plate.png | 192×36 RGBA / 9-slice 12px | 1안: 대화 틀의 마름모 보석과 맞고, 이름을 넣는 중앙이 완전히 평평하다. |
| shadow_aura.png | 768×176 RGBA / 128×176 ×6, 10fps | 2안: 넓은 연무가 그림자임을 구분하며 중앙은 얇다. 6→1 변화량이 일반 전환과 비슷해 1안의 유사 중복 프레임에 의한 머뭇거림을 피한다. |

## 사용 정보

- cg_prologue: story.s01.pre.* 프롤로그 해설 뒤.
- cg_root: story.s08.post.* / story.s08.home.post.* 봉인 개방 대사 뒤.
- cg_epilogue: story.s09.post.* 마지막 해설 뒤. 생성 때 선택한 cg_prologue.png를 첫 참조로 사용했다.
- 장면은 16:9, 하단 25%가 대화 가림 영역이다. 장면 그림에는 글자·캐릭터를 넣지 않았다.
- dialogue_frame: 9-slice L/T/R/B = 24/24/24/24px. 중앙 alpha=0. 어두운 대화 배경은 게임이 따로 그린다. 1160×170 검토본을 보고서에 제공한다.
- name_plate: 9-slice L/T/R/B = 12/12/12/12px. 중앙 RGBA=(16,24,39,235), 직선부 금색 테두리 2px. 보석과 받침은 x<12 또는 x>=180 안에 있다. 220×40 검토본을 제공한다.
- shadow_aura: 가로 6칸, 각128×176, 10fps, loop=true, pivot=(64,160). 0.6초 루프. 캐릭터 뒤에 일반 alpha 혼합으로 그리는 것을 권장한다(additive=false). 발은 y=160, 몸 중심은 x=64다. 모든 칸에 최소4px 이상의 빈 여백이 있다.
- 오라 2안: 실제 빈 여백 최소 L16/T10/R16/B16px. 6→1 premultiplied RGBA 평균 절대차13.2700/255, 보통 전환 중앙값 대비0.9643배. 시간의 자연스러움은 GIF와 실제 캐릭터 위에서 사람이 최종 판단한다.

## 원본과 가공

- 장면 8종 모두 원본1672×941. 중앙 (4,2)-(1668,938)을 잘라1664×936(16:9)으로 만든 뒤1600×900으로 LANCZOS 축소했다. 확대·합성·보정·문자 삭제는 하지 않았다.
- 프레임: 선택 원본1983×793의 좌상단(12,14)-(188,190) 장식을22×22로 최근접 축소, 팔레트와 이진 alpha로 마감하고 다른 코너에 대칭 배치했다. 정확한480×120 캔버스에 늘어나는 이중 직선을 Pillow로 그렸다.
- 이름판: 선택 원본2048×768의 보석(72,350)-(139,417)을7×7로 최근접 축소했다. 정확한192×36 캔버스에 alpha235 남색판·2px 금색 테두리·작은 보석 받침을 Pillow로 그렸다. 원본의 외곽 금빛 번짐은 사용하지 않았다.
- 오라: 선택 원본2126×740을 round(width*i/6) 기준으로6칸 분리. alpha<64 잡점을 버리고 공통 y범위와 배율0.2873563로 최근접 축소했다. x=64에 각각 중심 배치, 캔버스 기준 아래쪽160에 맞췄다. 원래 alpha를 유지하되32단계로 정리하고 지정 보라5색으로 매핑했다. 원본에 그려진 연무를 사용했으며 새 도형으로 대체하지 않았다.
- 모든 칸의 crop·resize·paste 좌표는 reports/codex-art-70/processing-v2.json에 있다. 확대하지 않았다.

## 확인

- 전체14변형의 픽셀 검사84/84 통과. 이는 게임 실행 검사가 아니다.
- 모든 장면을1600×900에서 육안 확인했다. 읽을 수 있는 글자·인물·생물·워터마크·반복 이음매를 발견하지 못했다. 이 판단은 OCR 자동 증명이 아니다.
- 다른 Godot 프로세스가 실행 중이라 이번 유닛은 Godot를 실행하지 않았다. 리드의 통합 후 PNG import와 실제 대화/그림자 화면 확인이 남는다.

## 프롬프트

정확한 최종 및 전체14개 프롬프트, 순서가 있는 참조 목록과 원본 SHA-256은 [PROMPTS.md](../../../../reports/codex-art-70/PROMPTS.md)에 있다. 선택본 프롬프트를 아래에도 그대로 둔다.

### cg_prologue

참조: ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. Create variant 1 of a game story scene, opaque landscape 16:9, largest available resolution at least 1600x900 (prefer 2048x1152). Reference 1 is the painted pixel-art style and eight realm islands, reference 2 the exact Yggdrasil tree and pink heart identity. Central broad world tree occupies x32-68%, canopy y8-32%, heart centre x50% y45%. The heart-shaped pink core inside the trunk is visibly CRACKING AND BURSTING, jagged white-pink cracks across the heart, brilliant white-pink flash, ONE expanding elliptical ring shockwave and flying light shards. Eight distinctive surrounding floating realm islands: gold castle, green-roof town, ice castle, purple moon grove, red lava fortress, brass clockwork city, green forest temple, grey horned ruins; all visibly tilted and drifting. On the left middle, the gold castle island and green-roof town island physically collide, jagged rubble between them and severed waterfalls. Galaxies in navy cosmos tinted red-violet by the eruption. Composition take A: symmetrical vast cosmic disaster panorama, shockwave horizontal. Bottom 25 percent only dark clouds and rocks with little detail, important story action entirely above y75%. Crisp painted pixel clusters like reference, no smooth airbrush. Palette #0b1030 #3b1d5e #7a3fc0 #ff4fd8 #ffd6f5 #f3cd7c. Absolutely no people, creatures, figures, letters, text, logos, UI, border, frame, watermark, photographic textures.
~~~

### cg_root

참조: ui/title_bg.png → realm_niflheim/bg_far.png

~~~text
Use case: illustration-story. Game story scene cg_root variant 3, opaque landscape 16:9 at largest available resolution, at least 1600px wide preferably 2048x1152. Reference 1: painted pixel-art style of game. Reference 2: ice cavern palette and aurora. An immense ancient woody root of Yggdrasil, distinctly bark NOT snake or creature, frost and long icicles encrusting it, spirals downward through a circular opening into an immense abyss INSIDE AN ICE CAVERN. Around the root opening at x50% y48%, a circular ward seal: a clearly visible broken ring of pale-cyan magical light carrying plain rectangular paper talismans. Each paper has ONLY a single abstract red spiral brush swirl, absolutely no writing or readable glyphs. The ring is breaking into separated arcs; papers drift outward. Deep below, pink magenta heart light rises along the spiralling bark. Aurora green light enters through a distant narrow opening far above. Take C composition: wide side view across cavern, great frozen root forms a slow S-shaped spiral from top RIGHT into a central-left abyss. Circular ward appears as a tall tilted ellipse, two large separated arcs with wide broken gaps and many outward floating papers. The magenta light is a small intense source just below the ring at x48% y58%. Aurora opening at upper far left, cavern ceiling strongly visible. Distinct from A/B. Root terminates visually at y69%; bottom 25% dark quiet ice shadow without magenta glow or detailed architecture. No heart shape in this scene; only magenta light climbing bark. Main narrative in upper 75%, bottom quarter dark ice and shadow, almost no detail. Crisp painted pixel clusters not smooth airbrush; teal #0d2a33 #1f5560, cyan #7fe3ff, aurora #58d6a8, magenta #ff4fd8. NO people, creatures, faces, figures, statues, text, letters, kanji, glyphs, logos, UI, frame, border, watermark.
~~~

### cg_epilogue

참조: story/cg_prologue.png → ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. cg_epilogue variant 1, opaque landscape 16:9 at largest available resolution at least 1600x900. Reference image 1 is the CHOSEN PROLOGUE: preserve its exact world-tree position, canopy silhouette and SIZE, trunk, central island and heart position. Reference 2 is original game's style anchor and eight island identities; reference 3 game tree. Create the clear AFTER image of the FIRST reference: same tree x50%, canopy top y5%, width roughly40%, heart x50% y43%, central island y60-76%. Heart now entirely WHOLE with no cracks, soft warm pink-gold #ffb8e8 #f3cd7c, gently glowing heart-shaped core nested in trunk. All eight realm islands calmly upright floating in their same approximate positions but repaired and separated: gold castle upper left, green roof town middle left, moon grove far left, forest temple lower left, ice castle upper right, grey horned ruins mid-right, quiet red stone fortress far right WITHOUT FIRE, brass clockwork city lower right. Gentle thin waterfalls flow unbroken. Small gentle golden light motes rise by tree. Sky deep navy at top, fading to soft lavender and pale-gold DAWN at the horizon. Take A: warm luminous dawn, broad lavender clouds and delicate pale-gold rim light on canopy. No explosive light. Bottom quarter is only soft low-detail clouds. Keep crisp painted pixel clusters exactly like game, no airbrushed smoothness. Absolutely NO cracks, shockwave, fire, debris, catastrophe, people, creatures, letters, text, logos, UI, frames, border, watermark.
~~~

### dialogue_frame

참조: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Asset: transparent fantasy game dialogue FRAME only, variant 1, wide horizontal 4:1 ratio, target 480x120 pixels, generate large enough for downscale, genuine alpha background. Reference image is the game's existing frame ornament style: gold/deep gold and blue gemstone on navy outline. Draw a refined crisp PIXEL ART rectangular border with ornate gold wing-scroll corner pieces and one small blue diamond gem at EACH corner. Ornaments entirely confined to the outermost 5 percent canvas WIDTH and 20 percent HEIGHT corner squares (24x24 at final size). ALL four corners' outermost canvas pixel is transparent. Each long and short edge between corners is a completely plain straight double line, outer gold, inner thin blue. Absolutely no ornament at any edge's middle. Enormous EMPTY fully TRANSPARENT centre, not white, not black, not checkerboard. Palette gold #f3cd7c deep gold #a8742c gem blue #3d7bd9 highlights #9fd2ff dark outline #101827. Take A design: angular Norse leaf-wing scroll corners, blue diamond pointing toward centre. Crisp integer pixel steps, no blur or anti-alias. Border sits fully inside canvas, no drop shadow outside. No text, letters, UI contents, characters, filled centre, glow, gradients, watermark.
~~~

### name_plate

참조: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Transparent pixel art game speaker NAME PLATE variant 1. Reference image is gold and blue ornament style only. Very wide short horizontal blank navy plate, aspect 192:36 (5.333:1), generate at largest closest wide aspect. A DARK NAVY #101827 fill, alpha about235/255 (slightly translucent), surrounded by exactly TWO-PIXEL GOLD #f3cd7c border at final192x36. One TINY faceted blue #3d7bd9 #9fd2ff diamond gem at EACH end, completely confined to the 12px-wide end zones. End zones about6.25% of total width. Centre 87.5% absolutely flat navy with no ornament or text, intended to stretch with 9-slice 12px on all sides. Take A: chamfered angular clipped corners, tiny diamond gems in gold bezels. Fully transparent exterior and corners; crisp pixel steps no antialiasing, no blur, no shadows. NO text, letters, logo, watermark, large ornament, checkerboard background.
~~~

### shadow_aura

참조: effects/skill/luna_brave_aura.png

~~~text
Use case: stylized-concept. Transparent PIXEL EFFECT spritesheet, shadow_aura variant 2. Reference image is game's effect strip pixel rendering, NOT its ring motif or cyan palette. Output one horizontal strip with EXACTLY SIX evenly spaced animation cells, final each128x176, total768x176 aspect48:11; generate closest wide ratio large enough to downscale only. All background genuine transparent alpha. Each cell: body centre at50% width, feet at91% cell height; an empty central space for a separately drawn 42x96 fighter. Only DARK VIOLET SMOKE-FLAME WISPS rise at the sides and ABOVE this empty space, densest at sides and above head, wispy thin middle. No person or creature or humanoid silhouette or face, no ring, no solid filled centre. Six consecutive cyclical frames 10fps: wisps curl upward in a coherent repeating phase; last flows naturally into first with no pop. Take B: wider LOW DENSITY billowing shadow SMOKE, broad broken curling plumes at shoulders and above head, fragmented smoky lobes rather than tall narrow flame ribbons. One tiny magenta spark per side, much dimmer purple dominant. Wide empty central opening. Six frames phase-shift upwards by small coherent increments. Make frames one and six similar but NOT identical (no duplicated hold frame), seam must flow from sixth to first. Distinct from take A's sharp narrow flame licks. Painterly pixel clusters only. Colours ONLY deep violet #1a0f2e #3b1d5e purple #6b2fa8 small magenta #ff4fd8 faintpink #ff9be8. Dark smoke is dominant, bright sparks sparse. Keep clear empty margins at least4 pixels on EVERY side of EACH cell (3.2% x,2.3% y); nothing touches cell boundaries, no clipped wisps, no ground contact blob. Crisp pixel clusters, no blurred glow or white halo, no square cutoffs. Absolutely no text, letters, labels, numbering, grid, checkerboard, border, watermark.
~~~
