# ART-70 실제 생성 프롬프트와 출처

도구: 내장 image_gen. 각 변형을 별도 호출했다. 아래 문자열은 실제 전달한 영어 프롬프트이며, 참조 파일도 referenced_image_paths로 전달했다. 투명 자산은 transparent_background=true, 장면은 false였다. 생성 원본은 도구가 반환한 generated_images 경로에서 복사했고 원본을 수정하지 않았다.

## 최종 선택 프롬프트

### cg_prologue · 선택 1안

참조 순서: ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. Create variant 1 of a game story scene, opaque landscape 16:9, largest available resolution at least 1600x900 (prefer 2048x1152). Reference 1 is the painted pixel-art style and eight realm islands, reference 2 the exact Yggdrasil tree and pink heart identity. Central broad world tree occupies x32-68%, canopy y8-32%, heart centre x50% y45%. The heart-shaped pink core inside the trunk is visibly CRACKING AND BURSTING, jagged white-pink cracks across the heart, brilliant white-pink flash, ONE expanding elliptical ring shockwave and flying light shards. Eight distinctive surrounding floating realm islands: gold castle, green-roof town, ice castle, purple moon grove, red lava fortress, brass clockwork city, green forest temple, grey horned ruins; all visibly tilted and drifting. On the left middle, the gold castle island and green-roof town island physically collide, jagged rubble between them and severed waterfalls. Galaxies in navy cosmos tinted red-violet by the eruption. Composition take A: symmetrical vast cosmic disaster panorama, shockwave horizontal. Bottom 25 percent only dark clouds and rocks with little detail, important story action entirely above y75%. Crisp painted pixel clusters like reference, no smooth airbrush. Palette #0b1030 #3b1d5e #7a3fc0 #ff4fd8 #ffd6f5 #f3cd7c. Absolutely no people, creatures, figures, letters, text, logos, UI, border, frame, watermark, photographic textures.
~~~

### cg_root · 선택 3안

참조 순서: ui/title_bg.png → realm_niflheim/bg_far.png

~~~text
Use case: illustration-story. Game story scene cg_root variant 3, opaque landscape 16:9 at largest available resolution, at least 1600px wide preferably 2048x1152. Reference 1: painted pixel-art style of game. Reference 2: ice cavern palette and aurora. An immense ancient woody root of Yggdrasil, distinctly bark NOT snake or creature, frost and long icicles encrusting it, spirals downward through a circular opening into an immense abyss INSIDE AN ICE CAVERN. Around the root opening at x50% y48%, a circular ward seal: a clearly visible broken ring of pale-cyan magical light carrying plain rectangular paper talismans. Each paper has ONLY a single abstract red spiral brush swirl, absolutely no writing or readable glyphs. The ring is breaking into separated arcs; papers drift outward. Deep below, pink magenta heart light rises along the spiralling bark. Aurora green light enters through a distant narrow opening far above. Take C composition: wide side view across cavern, great frozen root forms a slow S-shaped spiral from top RIGHT into a central-left abyss. Circular ward appears as a tall tilted ellipse, two large separated arcs with wide broken gaps and many outward floating papers. The magenta light is a small intense source just below the ring at x48% y58%. Aurora opening at upper far left, cavern ceiling strongly visible. Distinct from A/B. Root terminates visually at y69%; bottom 25% dark quiet ice shadow without magenta glow or detailed architecture. No heart shape in this scene; only magenta light climbing bark. Main narrative in upper 75%, bottom quarter dark ice and shadow, almost no detail. Crisp painted pixel clusters not smooth airbrush; teal #0d2a33 #1f5560, cyan #7fe3ff, aurora #58d6a8, magenta #ff4fd8. NO people, creatures, faces, figures, statues, text, letters, kanji, glyphs, logos, UI, frame, border, watermark.
~~~

### cg_epilogue · 선택 1안

참조 순서: story/cg_prologue.png → ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. cg_epilogue variant 1, opaque landscape 16:9 at largest available resolution at least 1600x900. Reference image 1 is the CHOSEN PROLOGUE: preserve its exact world-tree position, canopy silhouette and SIZE, trunk, central island and heart position. Reference 2 is original game's style anchor and eight island identities; reference 3 game tree. Create the clear AFTER image of the FIRST reference: same tree x50%, canopy top y5%, width roughly40%, heart x50% y43%, central island y60-76%. Heart now entirely WHOLE with no cracks, soft warm pink-gold #ffb8e8 #f3cd7c, gently glowing heart-shaped core nested in trunk. All eight realm islands calmly upright floating in their same approximate positions but repaired and separated: gold castle upper left, green roof town middle left, moon grove far left, forest temple lower left, ice castle upper right, grey horned ruins mid-right, quiet red stone fortress far right WITHOUT FIRE, brass clockwork city lower right. Gentle thin waterfalls flow unbroken. Small gentle golden light motes rise by tree. Sky deep navy at top, fading to soft lavender and pale-gold DAWN at the horizon. Take A: warm luminous dawn, broad lavender clouds and delicate pale-gold rim light on canopy. No explosive light. Bottom quarter is only soft low-detail clouds. Keep crisp painted pixel clusters exactly like game, no airbrushed smoothness. Absolutely NO cracks, shockwave, fire, debris, catastrophe, people, creatures, letters, text, logos, UI, frames, border, watermark.
~~~

### dialogue_frame · 선택 1안

참조 순서: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Asset: transparent fantasy game dialogue FRAME only, variant 1, wide horizontal 4:1 ratio, target 480x120 pixels, generate large enough for downscale, genuine alpha background. Reference image is the game's existing frame ornament style: gold/deep gold and blue gemstone on navy outline. Draw a refined crisp PIXEL ART rectangular border with ornate gold wing-scroll corner pieces and one small blue diamond gem at EACH corner. Ornaments entirely confined to the outermost 5 percent canvas WIDTH and 20 percent HEIGHT corner squares (24x24 at final size). ALL four corners' outermost canvas pixel is transparent. Each long and short edge between corners is a completely plain straight double line, outer gold, inner thin blue. Absolutely no ornament at any edge's middle. Enormous EMPTY fully TRANSPARENT centre, not white, not black, not checkerboard. Palette gold #f3cd7c deep gold #a8742c gem blue #3d7bd9 highlights #9fd2ff dark outline #101827. Take A design: angular Norse leaf-wing scroll corners, blue diamond pointing toward centre. Crisp integer pixel steps, no blur or anti-alias. Border sits fully inside canvas, no drop shadow outside. No text, letters, UI contents, characters, filled centre, glow, gradients, watermark.
~~~

### name_plate · 선택 1안

참조 순서: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Transparent pixel art game speaker NAME PLATE variant 1. Reference image is gold and blue ornament style only. Very wide short horizontal blank navy plate, aspect 192:36 (5.333:1), generate at largest closest wide aspect. A DARK NAVY #101827 fill, alpha about235/255 (slightly translucent), surrounded by exactly TWO-PIXEL GOLD #f3cd7c border at final192x36. One TINY faceted blue #3d7bd9 #9fd2ff diamond gem at EACH end, completely confined to the 12px-wide end zones. End zones about6.25% of total width. Centre 87.5% absolutely flat navy with no ornament or text, intended to stretch with 9-slice 12px on all sides. Take A: chamfered angular clipped corners, tiny diamond gems in gold bezels. Fully transparent exterior and corners; crisp pixel steps no antialiasing, no blur, no shadows. NO text, letters, logo, watermark, large ornament, checkerboard background.
~~~

### shadow_aura · 선택 2안

참조 순서: effects/skill/luna_brave_aura.png

~~~text
Use case: stylized-concept. Transparent PIXEL EFFECT spritesheet, shadow_aura variant 2. Reference image is game's effect strip pixel rendering, NOT its ring motif or cyan palette. Output one horizontal strip with EXACTLY SIX evenly spaced animation cells, final each128x176, total768x176 aspect48:11; generate closest wide ratio large enough to downscale only. All background genuine transparent alpha. Each cell: body centre at50% width, feet at91% cell height; an empty central space for a separately drawn 42x96 fighter. Only DARK VIOLET SMOKE-FLAME WISPS rise at the sides and ABOVE this empty space, densest at sides and above head, wispy thin middle. No person or creature or humanoid silhouette or face, no ring, no solid filled centre. Six consecutive cyclical frames 10fps: wisps curl upward in a coherent repeating phase; last flows naturally into first with no pop. Take B: wider LOW DENSITY billowing shadow SMOKE, broad broken curling plumes at shoulders and above head, fragmented smoky lobes rather than tall narrow flame ribbons. One tiny magenta spark per side, much dimmer purple dominant. Wide empty central opening. Six frames phase-shift upwards by small coherent increments. Make frames one and six similar but NOT identical (no duplicated hold frame), seam must flow from sixth to first. Distinct from take A's sharp narrow flame licks. Painterly pixel clusters only. Colours ONLY deep violet #1a0f2e #3b1d5e purple #6b2fa8 small magenta #ff4fd8 faintpink #ff9be8. Dark smoke is dominant, bright sparks sparse. Keep clear empty margins at least4 pixels on EVERY side of EACH cell (3.2% x,2.3% y); nothing touches cell boundaries, no clipped wisps, no ground contact blob. Crisp pixel clusters, no blurred glow or white halo, no square cutoffs. Absolutely no text, letters, labels, numbering, grid, checkerboard, border, watermark.
~~~

## 전체 변형의 실제 프롬프트

### cg_prologue v1

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-d97bac4e-7379-4c27-96f7-feac86d71495.png

보존 원본: smash-nine-prototype/assets/art/story/cg_prologue_source.png

SHA-256: 93972e6c3ec31e9fc66fc9ea2e37b2e93c8e938849ce91ea718f3648d8dfb814

참조 순서: ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. Create variant 1 of a game story scene, opaque landscape 16:9, largest available resolution at least 1600x900 (prefer 2048x1152). Reference 1 is the painted pixel-art style and eight realm islands, reference 2 the exact Yggdrasil tree and pink heart identity. Central broad world tree occupies x32-68%, canopy y8-32%, heart centre x50% y45%. The heart-shaped pink core inside the trunk is visibly CRACKING AND BURSTING, jagged white-pink cracks across the heart, brilliant white-pink flash, ONE expanding elliptical ring shockwave and flying light shards. Eight distinctive surrounding floating realm islands: gold castle, green-roof town, ice castle, purple moon grove, red lava fortress, brass clockwork city, green forest temple, grey horned ruins; all visibly tilted and drifting. On the left middle, the gold castle island and green-roof town island physically collide, jagged rubble between them and severed waterfalls. Galaxies in navy cosmos tinted red-violet by the eruption. Composition take A: symmetrical vast cosmic disaster panorama, shockwave horizontal. Bottom 25 percent only dark clouds and rocks with little detail, important story action entirely above y75%. Crisp painted pixel clusters like reference, no smooth airbrush. Palette #0b1030 #3b1d5e #7a3fc0 #ff4fd8 #ffd6f5 #f3cd7c. Absolutely no people, creatures, figures, letters, text, logos, UI, border, frame, watermark, photographic textures.
~~~

### cg_prologue v2

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-618da5b7-2b3b-4c0a-be79-8f8ddbe3320c.png

보존 원본: reports/codex-art-70/variants/cg_prologue-v2_source.png

SHA-256: a4112e53a04a6d90751759346d2ffd00dd35468d6042bd28d928a7341b98e2e0

참조 순서: ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. Create variant 2 of a game story scene, opaque landscape 16:9, largest available resolution at least 1600x900 (prefer 2048x1152). Reference 1 is the painted pixel-art style and eight realm islands, reference 2 the exact Yggdrasil tree and pink heart identity. Central broad world tree occupies x32-68%, canopy y8-32%, heart centre x50% y45%. The heart-shaped pink core inside the trunk is visibly CRACKING AND BURSTING, jagged white-pink cracks across the heart, brilliant white-pink flash, ONE expanding elliptical ring shockwave and flying light shards. Eight distinctive surrounding floating realm islands: gold castle, green-roof town, ice castle, purple moon grove, red lava fortress, brass clockwork city, green forest temple, grey horned ruins; all visibly tilted and drifting. On the right middle, ice castle and grey horned ruins physically collide, jagged rubble between them and severed waterfalls. Galaxies in navy cosmos tinted red-violet by the eruption. Composition take B: closer slightly low camera looking up at the immense tree, a diagonal tilted shockwave seen nearly edge-on sweeps from lower left to upper right; dramatic asymmetrical debris vectors. The collision instead occurs on the RIGHT middle, between the ice castle island and grey horned ruins; gold castle and green-roof town on left are separating without contact. Heart remains x50% y45%, tree remains central. This must be a distinctly different illustration, not a near duplicate of take A. Bottom 25 percent only dark clouds and rocks with little detail, important story action entirely above y75%. Crisp painted pixel clusters like reference, no smooth airbrush. Palette #0b1030 #3b1d5e #7a3fc0 #ff4fd8 #ffd6f5 #f3cd7c. Absolutely no people, creatures, figures, letters, text, logos, UI, border, frame, watermark, photographic textures.
~~~

### cg_prologue v3

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-4092ee3a-3eed-4717-a09a-37be46c6c632.png

보존 원본: reports/codex-art-70/variants/cg_prologue-v3_source.png

SHA-256: 72d12e12c9ac9efe85e3a78c3449ff9d77f8d4cc8526f0fc1a481fa4b6b007a7

참조 순서: ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. Create variant 3 of a game story scene, opaque landscape 16:9, largest available resolution at least 1600x900 (prefer 2048x1152). Reference 1 is the painted pixel-art style and eight realm islands, reference 2 the exact Yggdrasil tree and pink heart identity. Central broad world tree occupies x32-68%, canopy y8-32%, heart centre x50% y45%. The heart-shaped pink core inside the trunk is visibly CRACKING AND BURSTING, jagged white-pink cracks across the heart, brilliant white-pink flash, ONE expanding elliptical ring shockwave and flying light shards. Eight distinctive surrounding floating realm islands: gold castle, green-roof town, ice castle, purple moon grove, red lava fortress, brass clockwork city, green forest temple, grey horned ruins; all visibly tilted and drifting. In the right middle the brass clockwork island's jagged cliff physically collides with the grey horned ruins' cliff, rubble and severed waterfalls at the contact point. Other islands separated. Galaxies in navy cosmos tinted red-violet by the eruption. Composition take C: more distant elevated camera, the tree is seen through a huge almost circular frontal shockwave that bows up into the cosmos; broad negative-space navy sky at the top, eight islands form a broken spiral around it. Tree canopy and tree island fit within x30-70%, y12-72%. Bright crystalline shards spray vertically rather than horizontally. Distinct from takes A and B, quieter dark cosmic edges and more emphasis on a broken orbital arrangement. Bottom 25 percent only dark clouds and rocks with little detail, important story action entirely above y75%. Crisp painted pixel clusters like reference, no smooth airbrush. Palette #0b1030 #3b1d5e #7a3fc0 #ff4fd8 #ffd6f5 #f3cd7c. Absolutely no people, creatures, figures, letters, text, logos, UI, border, frame, watermark, photographic textures.
~~~

### cg_root v1

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-8d3dfb79-d7fb-43df-8246-9d34ce309443.png

보존 원본: reports/codex-art-70/variants/cg_root-v1_source.png

SHA-256: 847cd71bc875b0a40f7b555a31aa15e6fb91d5534f515c9732363e986a6a201e

참조 순서: ui/title_bg.png → realm_niflheim/bg_far.png

~~~text
Use case: illustration-story. Game story scene cg_root variant 1, opaque landscape 16:9 at largest available resolution, at least 1600px wide preferably 2048x1152. Reference 1: painted pixel-art style of game. Reference 2: ice cavern palette and aurora. An immense ancient woody root of Yggdrasil, distinctly bark NOT snake or creature, frost and long icicles encrusting it, spirals downward through a circular opening into an immense abyss INSIDE AN ICE CAVERN. Around the root opening at x50% y48%, a circular ward seal: a clearly visible broken ring of pale-cyan magical light carrying plain rectangular paper talismans. Each paper has ONLY a single abstract red spiral brush swirl, absolutely no writing or readable glyphs. The ring is breaking into separated arcs; papers drift outward. Deep below, pink magenta heart light rises along the spiralling bark. Aurora green light enters through a distant narrow opening far above. Take A composition: grand frontal symmetrical cavern, colossal root descends from upper left toward central chasm, ring seen as broad ellipse around the mouth. Main narrative in upper 75%, bottom quarter dark ice and shadow, almost no detail. Crisp painted pixel clusters not smooth airbrush; teal #0d2a33 #1f5560, cyan #7fe3ff, aurora #58d6a8, magenta #ff4fd8. NO people, creatures, faces, figures, statues, text, letters, kanji, glyphs, logos, UI, frame, border, watermark.
~~~

### cg_root v2

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-95d27c8b-d3db-4524-903c-85a8a4bd814f.png

보존 원본: reports/codex-art-70/variants/cg_root-v2_source.png

SHA-256: 35355b0e78371c3b7277dfecda73c34f2cf48096a9708a295398aa84b5d48b21

참조 순서: ui/title_bg.png → realm_niflheim/bg_far.png

~~~text
Use case: illustration-story. Game story scene cg_root variant 2, opaque landscape 16:9 at largest available resolution, at least 1600px wide preferably 2048x1152. Reference 1: painted pixel-art style of game. Reference 2: ice cavern palette and aurora. An immense ancient woody root of Yggdrasil, distinctly bark NOT snake or creature, frost and long icicles encrusting it, spirals downward through a circular opening into an immense abyss INSIDE AN ICE CAVERN. Around the root opening at x50% y48%, a circular ward seal: a clearly visible broken ring of pale-cyan magical light carrying plain rectangular paper talismans. Each paper has ONLY a single abstract red spiral brush swirl, absolutely no writing or readable glyphs. The ring is breaking into separated arcs; papers drift outward. Deep below, pink magenta heart light rises along the spiralling bark. Aurora green light enters through a distant narrow opening far above. Take B composition: steep elevated oblique camera peers down into a vast dark round shaft, root coils clockwise along the inside wall, large circular seal seen almost face-on in upper middle; an open gap at upper right of seal with several detached talismans drifting out. Aurora shaft from top left. Everything vital including pink light source lies above y70%. Lower 25 percent is truly dark calm ice ledge, with no glowing roots or papers crossing it. Distinct from frontal take A. Main narrative in upper 75%, bottom quarter dark ice and shadow, almost no detail. Crisp painted pixel clusters not smooth airbrush; teal #0d2a33 #1f5560, cyan #7fe3ff, aurora #58d6a8, magenta #ff4fd8. NO people, creatures, faces, figures, statues, text, letters, kanji, glyphs, logos, UI, frame, border, watermark.
~~~

### cg_root v3

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-905d6be1-b365-4b82-a17e-515eeb82e8b7.png

보존 원본: smash-nine-prototype/assets/art/story/cg_root_source.png

SHA-256: f066c7802bedcd61a4884493af84dbdfbb3321cd1b0c32985228c496d707d6c8

참조 순서: ui/title_bg.png → realm_niflheim/bg_far.png

~~~text
Use case: illustration-story. Game story scene cg_root variant 3, opaque landscape 16:9 at largest available resolution, at least 1600px wide preferably 2048x1152. Reference 1: painted pixel-art style of game. Reference 2: ice cavern palette and aurora. An immense ancient woody root of Yggdrasil, distinctly bark NOT snake or creature, frost and long icicles encrusting it, spirals downward through a circular opening into an immense abyss INSIDE AN ICE CAVERN. Around the root opening at x50% y48%, a circular ward seal: a clearly visible broken ring of pale-cyan magical light carrying plain rectangular paper talismans. Each paper has ONLY a single abstract red spiral brush swirl, absolutely no writing or readable glyphs. The ring is breaking into separated arcs; papers drift outward. Deep below, pink magenta heart light rises along the spiralling bark. Aurora green light enters through a distant narrow opening far above. Take C composition: wide side view across cavern, great frozen root forms a slow S-shaped spiral from top RIGHT into a central-left abyss. Circular ward appears as a tall tilted ellipse, two large separated arcs with wide broken gaps and many outward floating papers. The magenta light is a small intense source just below the ring at x48% y58%. Aurora opening at upper far left, cavern ceiling strongly visible. Distinct from A/B. Root terminates visually at y69%; bottom 25% dark quiet ice shadow without magenta glow or detailed architecture. No heart shape in this scene; only magenta light climbing bark. Main narrative in upper 75%, bottom quarter dark ice and shadow, almost no detail. Crisp painted pixel clusters not smooth airbrush; teal #0d2a33 #1f5560, cyan #7fe3ff, aurora #58d6a8, magenta #ff4fd8. NO people, creatures, faces, figures, statues, text, letters, kanji, glyphs, logos, UI, frame, border, watermark.
~~~

### cg_epilogue v1

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-bc152a53-48f2-45cf-ab83-aafcaaeb312d.png

보존 원본: smash-nine-prototype/assets/art/story/cg_epilogue_source.png

SHA-256: 84331d77c39e6b824c3d94cfc0c0d0e363926e6e7edf9ca98b348cbbaff76cf8

참조 순서: story/cg_prologue.png → ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. cg_epilogue variant 1, opaque landscape 16:9 at largest available resolution at least 1600x900. Reference image 1 is the CHOSEN PROLOGUE: preserve its exact world-tree position, canopy silhouette and SIZE, trunk, central island and heart position. Reference 2 is original game's style anchor and eight island identities; reference 3 game tree. Create the clear AFTER image of the FIRST reference: same tree x50%, canopy top y5%, width roughly40%, heart x50% y43%, central island y60-76%. Heart now entirely WHOLE with no cracks, soft warm pink-gold #ffb8e8 #f3cd7c, gently glowing heart-shaped core nested in trunk. All eight realm islands calmly upright floating in their same approximate positions but repaired and separated: gold castle upper left, green roof town middle left, moon grove far left, forest temple lower left, ice castle upper right, grey horned ruins mid-right, quiet red stone fortress far right WITHOUT FIRE, brass clockwork city lower right. Gentle thin waterfalls flow unbroken. Small gentle golden light motes rise by tree. Sky deep navy at top, fading to soft lavender and pale-gold DAWN at the horizon. Take A: warm luminous dawn, broad lavender clouds and delicate pale-gold rim light on canopy. No explosive light. Bottom quarter is only soft low-detail clouds. Keep crisp painted pixel clusters exactly like game, no airbrushed smoothness. Absolutely NO cracks, shockwave, fire, debris, catastrophe, people, creatures, letters, text, logos, UI, frames, border, watermark.
~~~

### cg_epilogue v2

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-64c43d14-182d-459d-b49a-f6cebce6d5ea.png

보존 원본: reports/codex-art-70/variants/cg_epilogue-v2_source.png

SHA-256: 255d28dbc7c7685a19672bfede5f600158ad2fab10bbd5976622811b3e1ea7cb

참조 순서: story/cg_prologue.png → ui/title_bg.png → realm_center/bg_far.png

~~~text
Use case: illustration-story. cg_epilogue variant 2, opaque landscape 16:9 at largest available resolution at least 1600x900. Reference image 1 is the CHOSEN PROLOGUE: preserve its exact world-tree position, canopy silhouette and SIZE, trunk, central island and heart position. Reference 2 is original game's style anchor and eight island identities; reference 3 game tree. Create the clear AFTER image of the FIRST reference: same tree x50%, canopy top y5%, width roughly40%, heart x50% y43%, central island y60-76%. Heart now entirely WHOLE with no cracks, soft warm pink-gold #ffb8e8 #f3cd7c, gently glowing heart-shaped core nested in trunk. All eight realm islands calmly upright floating in their same approximate positions but repaired and separated: gold castle upper left, green roof town middle left, moon grove far left, forest temple lower left, ice castle upper right, grey horned ruins mid-right, quiet red stone fortress far right WITHOUT FIRE, brass clockwork city lower right. Gentle thin waterfalls flow unbroken. Small gentle golden light motes rise by tree. Sky deep navy at top, fading to soft lavender and pale-gold DAWN at the horizon. Take B: cool quiet pre-dawn with 55 percent navy cosmic sky and a low narrow band of pale-gold sunrise at y65-72%; clouds muted lavender rather than saturated peach. Gentle vertical motes, restrained soft pink heart with a gold rim, no dramatic glow veins on bark. This must be clearly cooler, quieter and more night-preserving than take A. Match FIRST reference tree silhouette precisely: canopy spans x27-72% and top is y5%, central island spans x32-68%, heart centre x50% y43%, tree base y61%. Keep tree trunk's exact fork shape; do not shrink the tree. Give dark navy clouds in bottom quarter no rocks. No explosive light. Bottom quarter is only soft low-detail clouds. Keep crisp painted pixel clusters exactly like game, no airbrushed smoothness. Absolutely NO cracks, shockwave, fire, debris, catastrophe, people, creatures, letters, text, logos, UI, frames, border, watermark.
~~~

### dialogue_frame v1

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-320945d9-a35f-44fb-9239-a6375c02d237.png

보존 원본: smash-nine-prototype/assets/art/story/dialogue_frame_source.png

SHA-256: 4e619427429b0d2feed0aaad907de037efe937f49c04dcbdc19291a8c626775a

참조 순서: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Asset: transparent fantasy game dialogue FRAME only, variant 1, wide horizontal 4:1 ratio, target 480x120 pixels, generate large enough for downscale, genuine alpha background. Reference image is the game's existing frame ornament style: gold/deep gold and blue gemstone on navy outline. Draw a refined crisp PIXEL ART rectangular border with ornate gold wing-scroll corner pieces and one small blue diamond gem at EACH corner. Ornaments entirely confined to the outermost 5 percent canvas WIDTH and 20 percent HEIGHT corner squares (24x24 at final size). ALL four corners' outermost canvas pixel is transparent. Each long and short edge between corners is a completely plain straight double line, outer gold, inner thin blue. Absolutely no ornament at any edge's middle. Enormous EMPTY fully TRANSPARENT centre, not white, not black, not checkerboard. Palette gold #f3cd7c deep gold #a8742c gem blue #3d7bd9 highlights #9fd2ff dark outline #101827. Take A design: angular Norse leaf-wing scroll corners, blue diamond pointing toward centre. Crisp integer pixel steps, no blur or anti-alias. Border sits fully inside canvas, no drop shadow outside. No text, letters, UI contents, characters, filled centre, glow, gradients, watermark.
~~~

### dialogue_frame v2

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-fff0a732-8e97-43fe-9a21-9f46b962b4a8.png

보존 원본: reports/codex-art-70/variants/dialogue_frame-v2_source.png

SHA-256: 5c851c93ea1ee6bba557ef6a2024af71abf02a889a97a5c88366c9aae19e8f84

참조 순서: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Asset: transparent fantasy game dialogue FRAME only, variant 2, wide horizontal 4:1 ratio, target 480x120 pixels, generate large enough for downscale, genuine alpha background. Reference image is the game's existing frame ornament style: gold/deep gold and blue gemstone on navy outline. Draw a refined crisp PIXEL ART rectangular border with ornate gold wing-scroll corner pieces and one small blue diamond gem at EACH corner. Ornaments entirely confined to the outermost 5 percent canvas WIDTH and 20 percent HEIGHT corner squares (24x24 at final size). ALL four corners' outermost canvas pixel is transparent. Each long and short edge between corners is a completely plain straight double line, outer gold, inner thin blue. Absolutely no ornament at any edge's middle. Enormous EMPTY fully TRANSPARENT centre, not white, not black, not checkerboard. Palette gold #f3cd7c deep gold #a8742c gem blue #3d7bd9 highlights #9fd2ff dark outline #101827. Take B design: restrained stepped architectural gold corner brackets, tiny ROUND icy blue gem inset into a square bezel; minimal geometric angular corner silhouette and no leaf or wing scroll. Distinct from ornate leaf-wing design. Corners should feel like carved Norse stone-and-gold fretwork. Crisp integer pixel steps, no blur or anti-alias. Border sits fully inside canvas, no drop shadow outside. No text, letters, UI contents, characters, filled centre, glow, gradients, watermark.
~~~

### name_plate v1

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-2c324891-61ef-4fdd-abb8-b83848fa6545.png

보존 원본: smash-nine-prototype/assets/art/story/name_plate_source.png

SHA-256: 3712aef0c65dac9fd2f0feafceb88ebca6614048bd924f63254fc129785d2bba

참조 순서: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Transparent pixel art game speaker NAME PLATE variant 1. Reference image is gold and blue ornament style only. Very wide short horizontal blank navy plate, aspect 192:36 (5.333:1), generate at largest closest wide aspect. A DARK NAVY #101827 fill, alpha about235/255 (slightly translucent), surrounded by exactly TWO-PIXEL GOLD #f3cd7c border at final192x36. One TINY faceted blue #3d7bd9 #9fd2ff diamond gem at EACH end, completely confined to the 12px-wide end zones. End zones about6.25% of total width. Centre 87.5% absolutely flat navy with no ornament or text, intended to stretch with 9-slice 12px on all sides. Take A: chamfered angular clipped corners, tiny diamond gems in gold bezels. Fully transparent exterior and corners; crisp pixel steps no antialiasing, no blur, no shadows. NO text, letters, logo, watermark, large ornament, checkerboard background.
~~~

### name_plate v2

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-63bba169-618c-4e9c-9eea-713e5580b8c6.png

보존 원본: reports/codex-art-70/variants/name_plate-v2_source.png

SHA-256: f061bb745a3d2362dcc9a578930eeb8b47a876bf577a93f865d957f614b753f8

참조 순서: ui/frames/result_panel.png

~~~text
Use case: stylized-concept. Transparent pixel art game speaker NAME PLATE variant 2. Reference image is gold and blue ornament style only. Very wide short horizontal blank navy plate, aspect 192:36 (5.333:1), generate at largest closest wide aspect. A DARK NAVY #101827 fill, alpha about235/255 (slightly translucent), surrounded by exactly TWO-PIXEL GOLD #f3cd7c border at final192x36. One TINY faceted blue #3d7bd9 #9fd2ff diamond gem at EACH end, completely confined to the 12px-wide end zones. End zones about6.25% of total width. Centre 87.5% absolutely flat navy with no ornament or text, intended to stretch with 9-slice 12px on all sides. Take B: simple rectangular plate with small step-cut corner pixels and tiny ROUND blue cabochon at each end, no diamond tabs, no bevel, no outer gold glow. Plate must have perfectly flat solid fill and uniform border, NO gradients anywhere. Exterior MUST be genuine transparent alpha rather than black. Distinct from chamfered diamond design. Fully transparent exterior and corners; crisp pixel steps no antialiasing, no blur, no shadows. NO text, letters, logo, watermark, large ornament, checkerboard background.
~~~

### shadow_aura v1

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-ffe3f7b2-2447-4839-8d2e-237f0cfce258.png

보존 원본: reports/codex-art-70/variants/shadow_aura-v1_source.png

SHA-256: 0b46f3e4e26457cfc39a8fc15ba22e7cc8f32c52cdc8add1052d3ff5e5d2ae7e

참조 순서: effects/skill/luna_brave_aura.png

~~~text
Use case: stylized-concept. Transparent PIXEL EFFECT spritesheet, shadow_aura variant 1. Reference image is game's effect strip pixel rendering, NOT its ring motif or cyan palette. Output one horizontal strip with EXACTLY SIX evenly spaced animation cells, final each128x176, total768x176 aspect48:11; generate closest wide ratio large enough to downscale only. All background genuine transparent alpha. Each cell: body centre at50% width, feet at91% cell height; an empty central space for a separately drawn 42x96 fighter. Only DARK VIOLET SMOKE-FLAME WISPS rise at the sides and ABOVE this empty space, densest at sides and above head, wispy thin middle. No person or creature or humanoid silhouette or face, no ring, no solid filled centre. Six consecutive cyclical frames 10fps: wisps curl upward in a coherent repeating phase; last flows naturally into first with no pop. Take A: narrow licking angular flame wisps, smoke curls crest alternately above left and right, sparse tiny magenta sparks drift upward. Colours ONLY deep violet #1a0f2e #3b1d5e purple #6b2fa8 small magenta #ff4fd8 faintpink #ff9be8. Dark smoke is dominant, bright sparks sparse. Keep clear empty margins at least4 pixels on EVERY side of EACH cell (3.2% x,2.3% y); nothing touches cell boundaries, no clipped wisps, no ground contact blob. Crisp pixel clusters, no blurred glow or white halo, no square cutoffs. Absolutely no text, letters, labels, numbering, grid, checkerboard, border, watermark.
~~~

### shadow_aura v2

도구 반환 원본: C:\Users\TH\.codex\generated_images\01a16292-03cf-7843-8149-126f34897965\exec-03c994fa-587a-46b5-afcf-50e59d9ba17d.png

보존 원본: smash-nine-prototype/assets/art/story/shadow_aura_source.png

SHA-256: 2628f2131e7919445d5e0c81e921105b23f9b9aa892086c633eb017704c9b180

참조 순서: effects/skill/luna_brave_aura.png

~~~text
Use case: stylized-concept. Transparent PIXEL EFFECT spritesheet, shadow_aura variant 2. Reference image is game's effect strip pixel rendering, NOT its ring motif or cyan palette. Output one horizontal strip with EXACTLY SIX evenly spaced animation cells, final each128x176, total768x176 aspect48:11; generate closest wide ratio large enough to downscale only. All background genuine transparent alpha. Each cell: body centre at50% width, feet at91% cell height; an empty central space for a separately drawn 42x96 fighter. Only DARK VIOLET SMOKE-FLAME WISPS rise at the sides and ABOVE this empty space, densest at sides and above head, wispy thin middle. No person or creature or humanoid silhouette or face, no ring, no solid filled centre. Six consecutive cyclical frames 10fps: wisps curl upward in a coherent repeating phase; last flows naturally into first with no pop. Take B: wider LOW DENSITY billowing shadow SMOKE, broad broken curling plumes at shoulders and above head, fragmented smoky lobes rather than tall narrow flame ribbons. One tiny magenta spark per side, much dimmer purple dominant. Wide empty central opening. Six frames phase-shift upwards by small coherent increments. Make frames one and six similar but NOT identical (no duplicated hold frame), seam must flow from sixth to first. Distinct from take A's sharp narrow flame licks. Painterly pixel clusters only. Colours ONLY deep violet #1a0f2e #3b1d5e purple #6b2fa8 small magenta #ff4fd8 faintpink #ff9be8. Dark smoke is dominant, bright sparks sparse. Keep clear empty margins at least4 pixels on EVERY side of EACH cell (3.2% x,2.3% y); nothing touches cell boundaries, no clipped wisps, no ground contact blob. Crisp pixel clusters, no blurred glow or white halo, no square cutoffs. Absolutely no text, letters, labels, numbering, grid, checkerboard, border, watermark.
~~~
