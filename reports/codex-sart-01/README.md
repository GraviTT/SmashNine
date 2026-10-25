# SART-01 · 스토리 장면 그림 검수 및 인계

완료: 비교 후보 6장, 교체 전 멧돼지 2장, 각각의 JSON, JPEG 연락판과 검수 기록.

- 브랜치: `codex/sart-01`. 후보 작업이며 게임 채택·연결은 하지 않았다.
- 생성: 내장 `image_gen` 6회 + 멧돼지 하단 구도 수정 2회. 총 8개 원본을 서로 다른 버전 이름으로 보존했다.
- 실제 참조를 `referenced_image_paths`에 전달했다. 모든 장면은 `transparent_background=false`.
- 생성 도구 반환 경로 → `art/raw/story/<name>-vN_raw.png` 복사. 8/8 SHA-256 일치, PNG CRC 및 불투명 RGB/alpha 확인.
- `smash-nine-prototype/` 변경 없음. Godot·설치·다운로드·병합·push 실행 없음.
- `.git`은 현재 환경에서 읽기 전용이다. `commit.ps1`과 마지막 줄이 지정 Co-Authored-By인 `commit-message.txt`를 준비했으며 실행하지 않았다.

## 현재 상태

8장 모두 1600×900 불투명 RGB PNG로 가공했다. 비교 대상은 숲 v1/v2, 멧돼지 v3/v4, 심장 v1/v2다. 멧돼지 v1/v2는 원안의 하단 가독성 실패 이력으로만 남긴다.

## 그림별 비교와 추천

| 장면 | 비교 버전 | 추천 | 이유 |
|---|---|---|---|
| cg_forest · stage 5 | v1 먼 전경 / v2 가까운 사선 | **v1** | 수정 3개와 끊어진 다리, 무너지는 두 지반의 관계가 빠르게 읽히고 하단도 더 조용하다. |
| cg_beast · stage 7 | v3 측면 / v4 정면 사선 | **v3** | 몸통·등 가시·굽은 엄니와 바닥 긁기가 잘 구분된다. v4는 정면 돌진의 압박감이 더 강한 대안이다. |
| cg_heart · stage 9 | v1 정면 / v2 사선 | **v1** | 원형 경기장과 다섯 불꽃이 한눈에 보이고 중앙 심장에 시선이 모인다. v2는 공간 깊이가 더 크다. |

멧돼지 v1/v2는 앞발과 바닥 긁는 불꽃이 화면 하단 25%에 들어가 **FAIL**로 기록했다. 같은 원안을 실제 edit target으로 전달해 v3/v4로 다시 생성했으며 원안을 덮어쓰지 않았다.

### 실제 파일

- cg_forest: [cg_forest-v1 가공 후보](../../art/bakeoff/story/cg_forest-v1.png) · [cg_forest-v2 가공 후보](../../art/bakeoff/story/cg_forest-v2.png)
- cg_beast: [cg_beast-v3 가공 후보](../../art/bakeoff/story/cg_beast-v3.png) · [cg_beast-v4 가공 후보](../../art/bakeoff/story/cg_beast-v4.png)
- cg_heart: [cg_heart-v1 가공 후보](../../art/bakeoff/story/cg_heart-v1.png) · [cg_heart-v2 가공 후보](../../art/bakeoff/story/cg_heart-v2.png)

[브라우저 비교판](raw-compare.html)은 이미지를 나란히 보고 하단 대화 영역을 켜고 끄는 로컬 검토용 HTML이다. JPEG 연락판을 대체했다고 간주하지 않는다.

## 명세 줄별 PASS / FAIL

내용·스타일의 PASS는 생성 원본을 전 해상도에서 본 육안 판정이다. OCR·얼굴 검출기의 자동 무검출 결과가 아니다. 후처리 이후 최종 PNG도 전 해상도에서 별도로 확인해야 한다. 필수 주제인 멧돼지의 동물 머리·눈은 허용하고, 공통 금지 얼굴은 사람 얼굴·인간형 형상·의도하지 않은 얼굴 모티프로 해석했다.

| 공통 명세 | 숲 v1/v2 | 멧돼지 v3/v4 | 심장 v1/v2 | 근거 |
|---|---|---|---|---|
| 최종 1600×900 | PASS | PASS | PASS | 실제 후보 PNG 계측 |
| 불투명 | PASS | PASS | PASS | 모든 원본 픽셀 확인; 반투명·투명 없음 |
| 16:9 크롭·축소·확대 금지 | PASS | PASS | PASS | 아래 처리 좌표와 배율 기록 |
| Python + Pillow LANCZOS | PASS | PASS | PASS | 가공 기록 확인 |
| ART-70 페인티드 픽셀 아트·픽셀 덩어리·에어브러시 회피 | PASS | PASS | PASS | cg_prologue와 title_bg를 실제 참조로 전달; 픽셀 군집과 계단형 외곽 |
| 하늘 노출부의 깊은 남색·은하 | PASS | PASS | PASS | 모든 원본에서 확인 |
| 하단 25% 어둡고 조용함 | PASS | PASS | PASS | 밝기 수치 + 중요 주제 가림 여부 육안 확인 |
| 사람·얼굴·인물·인간 조각상 없음 | PASS | PASS | PASS | 필수 멧돼지 외의 생물/인물 없음 |
| 글자·글리프·로고·UI·프레임·테두리·워터마크·사진풍 없음 | PASS | PASS | PASS | 전 해상도에서 발견 없음 |
| Text: none | PASS | PASS | PASS | 읽을 수 있는 글자나 유사 글자열 발견 없음 |
| 두 안의 명확한 차이 | PASS | PASS | PASS | 먼 전경/근경 사선, 측면/정면 사선, 정면/사선 |

### cg_forest

| 명세 | v1 | v2 | 확인 |
|---|---|---|---|
| 참조 3 바나헤임·참조 7 수정 | PASS | PASS | 스타일 참조 1·2와 함께 도구에 전달 |
| 숲 섬 붕괴·거목·기울어진 이끼 사원 | PASS | PASS | v1 왼쪽 사원과 오른쪽 거목 / v2 오른쪽 위 사원과 왼쪽 거목 |
| 뿌리 뜯김·낙하하는 지반 조각 | PASS | PASS | 벌어진 토양 아래 노출 뿌리와 분리된 낙하 조각 |
| 끊어지는 덩굴 다리 | PASS | PASS | 끊어진 바닥과 벌어진 끝, 늘어지거나 끊어진 덩굴 |
| 초록·금빛 숲 조명·균열의 적주황 붕괴광 | PASS | PASS | 잎·사원 광원과 지반 균열에서 확인 |
| 보라 소울 수정 정확히 3개, 다른 높이 | PASS | PASS | 별개의 수정 3개; 좌표는 visual-review-v1.json |
| 지정 팔레트 | PASS | PASS | 육안 계열 확인; 색상별 거리와 점유율은 계측 JSON. 수치 합격선은 카드에 없음 |

### cg_beast

| 명세 | v1 | v2 | v3 | v4 |
|---|---|---|---|---|
| 참조 4 용암 렐름·참조 6 멧돼지 디자인 | PASS | PASS | PASS | PASS |
| 거대 멧돼지·어두운 암석·발광 균열·등 가시·굽은 엄니 | PASS | PASS | PASS | PASS |
| 낮은 시점·용암의 아래 조명 | PASS | PASS | PASS | PASS |
| 바닥 긁기·돌진 직전 자세 | PASS | PASS | PASS | PASS |
| 연기·불씨·뒤쪽 분출 기둥 | PASS | PASS | PASS | PASS |
| 유일한 생물 | PASS(1마리) | PASS(1마리) | PASS(1마리) | PASS(1마리) |
| 지정 팔레트 | PASS | PASS | PASS | PASS |
| 하단 25% 조용함 | **FAIL** | **FAIL** | PASS | PASS |

v1/v2의 하단 평균이 어둡다는 사실만으로 합격시키지 않았다. 앞발과 긁는 동작이 대화 상자에 가려지므로 구도를 수정했다.

### cg_heart

| 명세 | v1 | v2 | 확인 |
|---|---|---|---|
| 참조 5 중앙 렐름·참조 1 심장 외형 | PASS | PASS | 스타일 title_bg와 함께 전달 |
| 세계수 아래 최종 경기장·뿌리와 돌의 원형 바닥 | PASS | PASS | 정면 타원 / 사선 타원으로 원형 바닥 표현 |
| 뒤틀린 분홍 심장·균열·검보라 맥·발광 | PASS | PASS | 갈라진 표면과 뒤엉킨 어두운 가지형 맥, 분홍/백색 균열 빛 |
| 바닥에서 심장 쪽으로 오르는 검보라 불꽃 정확히 5개 | PASS | PASS | 독립 바닥 접점 5개, 서로 구분되는 화염 |
| 추상 불꽃만, 얼굴·몸·사람 실루엣 없음 | PASS | PASS | 머리·눈·어깨·팔·다리 없이 꼬인 화염 띠 |
| 희미한 분홍 빛 입자 | PASS | PASS | 불꽃 사이와 심장 주변의 작은 입자 |
| 지정 팔레트 | PASS | PASS | 육안 계열과 색상별 거리 함께 기록 |

## 가공 후보 계측

밝기는 모든 픽셀의 감마 인코딩된 sRGB에서 `Y′=0.2126R+0.7152G+0.0722B`(0~255)를 계산했다. 하단은 `floor(H×3/4)`부터다. 대화 띠를 씌우기 전 그림 자체를 측정했다.

색상 거리는 sRGB→D65 CIELAB의 ΔE76이다. 아래 평균은 각 픽셀에서 지정 팔레트 중 가장 가까운 색까지의 거리를 픽셀 수로 가중했다. 남색 하늘·다른 명암색도 포함하므로 색상 품질 점수로 단정하지 않는다. 카드에는 수치 합격선이 없다. 각 팔레트 색의 최소 거리와 ΔE≤10 점유율은 JSON에 있다.

| 버전 | 실제 크기 | 상단 75% 평균 | 하단 25% 평균 | 하단/상단 | 팔레트 평균 ΔE76 |
|---|---|---:|---:|---:|---:|
| cg_forest-v1 | 1600×900 | 69.89 | 22.91 | 0.328 | 32.62 |
| cg_forest-v2 | 1600×900 | 71.62 | 28.93 | 0.404 | 27.74 |
| cg_beast-v1 | 1600×900 | 56.25 | 25.47 | 0.453 | 17.83 |
| cg_beast-v2 | 1600×900 | 52.36 | 19.67 | 0.376 | 17.86 |
| cg_heart-v1 | 1600×900 | 58.90 | 17.37 | 0.295 | 16.57 |
| cg_heart-v2 | 1600×900 | 55.09 | 16.21 | 0.294 | 16.70 |
| cg_beast-v3 | 1600×900 | 49.76 | 9.06 | 0.182 | 18.08 |
| cg_beast-v4 | 1600×900 | 47.44 | 7.55 | 0.159 | 18.46 |

전체 계측: [최종 가공 계측](measurements-v1.json).

## 크롭·리사이즈

실제 수행한 공통 처리:

| 원본 | 중앙 크롭 상자 | 크롭 결과 | 축소 목표 | 배율 |
|---|---|---|---|---|
| 1672×941 (6장) | (4, 2, 1668, 938) | 1664×936 | 1600×900 | 25/26 ≈ 0.961538 |
| 1672×940 (forest v2, beast v4) | (4, 2, 1668, 938) | 1664×936 | 1600×900 | 25/26 ≈ 0.961538 |

상자는 `[left, top, right, bottom)`이다. 좌우 4px씩, 941px 원본은 위 2px·아래 3px, 940px 원본은 위아래 2px씩만 제거한다. 확대·페인팅·색상 매핑·선명화·합성·검은 띠 굽기는 후보에 적용하지 않는다.

## 연락판

- [cg_forest-contact.jpg](cg_forest-contact.jpg): 1,201,868 bytes, JPEG quality 90, 각 그림 1280×720, 전체 3840×828.
- [cg_beast-contact.jpg](cg_beast-contact.jpg): 1,015,103 bytes, JPEG quality 90, 각 그림 1280×720, 전체 3840×828.
- [cg_heart-contact.jpg](cg_heart-contact.jpg): 1,180,891 bytes, JPEG quality 90, 각 그림 1280×720, 전체 3840×828.
- [cg_beast-before-contact.jpg](cg_beast-before-contact.jpg): 1,099,754 bytes, JPEG quality 90, 각 그림 1280×720, 전체 3840×828.

각 장면의 두 최종 후보 옆에 ART-70 cg_prologue를 놓고 하단 25%에만 RGBA (8,12,25,200) 띠를 올렸다. 후보 PNG에는 띠나 글자가 없다. `cg_beast-before-contact.jpg`는 탈락 원안 비교용이다.

## 사람이 판단할 부분

1. 숲: 넓게 설명하는 v1과 눈앞에서 붕괴하는 v2 중 대사 분위기에 더 맞는 구도. 수정과 끊어진 다리가 바로 읽히는지.
2. 멧돼지: v3의 몸체·등 가시 가독성과 v4의 정면 압박감 중 선호. 기존 작은 멧돼지 스프라이트와 같은 짐승으로 느껴지는지.
3. 심장: v1의 명확한 최종 무대와 v2의 공간 깊이 중 선호. 불꽃이 사람이나 유령 얼굴로 오해되지 않는지, 심장의 타락이 충분히 보이는지.
4. 공통: ART-70와 나란히 보았을 때 픽셀 밀도·채도·광원 강도가 맞는지. 최종 채택 후 리드가 실제 대화 상자를 얹어 가림과 읽기 편함을 확인할 것.

## 남은 작업과 실행

후보 채택은 사용자 판단이다. 리드의 통합 후 실제 스토리 화면에서 대화 가림을 확인하면 된다. 게임 실행 검증은 하지 않았다.

## 최종 프롬프트 전문

수정본은 원안과 수정 프롬프트를 함께 남긴다. 개별 복사용 파일은 [PROMPTS.md](PROMPTS.md), 기계 판독용은 [generation-manifest-v2.json](generation-manifest-v2.json)이다.

### cg_forest-v1

참조 순서: C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_vanaheim/bg_far.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/objects/soul_crystal.png

~~~text
Use case: illustration-story. Asset: cg_forest, stage 5 narration background for Smash Nine Realms. Generate ONE complete opaque landscape scene, widescreen 16:9, at the largest available native resolution, preferably 2048x1152 or larger and at least 1600px wide. Input images are REFERENCES, not edit targets: Image 1 cg_prologue is the primary painted pixel-art style anchor; image 2 title_bg supports the same style and cosmic realm setting; image 3 Vanaheim background defines the lush mossy ruined temple architecture and forest palette; image 4 is a repeated sprite strip showing ONE soul crystal design, not a count or layout to copy.
Story: the forest realm island is breaking apart. Show giant mature trees and a moss-covered stone temple visibly TILTING with broken foundations, huge exposed roots being ripped out of soil, large detached chunks of ground FALLING into the void, and a clearly SNAPPING vine bridge with two separated ragged ends over an open gap. Green and gold forest illumination, red-orange collapse light runs along the major ground cracks. EXACTLY THREE violet soul crystals total, each a single upright elongated faceted amethyst spindle matching image 4, glowing among separate ruins at THREE DISTINCT HEIGHTS. Make the three crystals countable and separated, not clusters of extra crystals.
Style: match the rich painted PIXEL ART of image 1 with visible crisp pixel clusters, stepped edges and pixel-built lighting. No smooth airbrush, no photographic textures, no vector illustration. Deep navy cosmic sky with small spiral galaxies wherever sky is visible. Main palette deep green #0e3b2a, moss #3f7d3a, gold light #e8c86a, collapse glow #ff6a3d, crystal violet #b77cff.
Narrative action and every crystal entirely within the TOP 72% of frame. BOTTOM QUARTER is dark quiet green-navy abyss mist, minimal detail and low contrast, darker than everything above; no important objects or bright cracks there. This darkness is part of the natural scene, not a drawn panel or border.
Text: none. Absolutely no people, human faces, creatures, humanoid figures, human statues, face-like patterns, letters, glyphs, inscriptions, runes, symbols, logos, UI, frames, borders or watermark. Temple masonry is plain stone with no writing.
TAKE A composition: a broad panorama seen from across the void. The large island tears diagonally into a high LEFT terrace and a sinking RIGHT terrace. The tall arched mossy temple leans left on the high terrace; gigantic trees lean outward on the right as their root mass rips free. The broken vine bridge crosses the central crack at mid-frame, clearly split. Three crystals anchored on surviving ledges at approximately (24% width,35% height), (51%,48%), (78%,62%). Show open dark gaps between separated falling chunks above y72%. Keep a sweeping readable island silhouette rather than a close-up.
~~~

### cg_forest-v2

참조 순서: C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_vanaheim/bg_far.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/objects/soul_crystal.png

~~~text
Use case: illustration-story. Asset: cg_forest, stage 5 narration background for Smash Nine Realms. Generate ONE complete opaque landscape scene, widescreen 16:9, at the largest available native resolution, preferably 2048x1152 or larger and at least 1600px wide. Input images are REFERENCES, not edit targets: Image 1 cg_prologue is the primary painted pixel-art style anchor; image 2 title_bg supports the same style and cosmic realm setting; image 3 Vanaheim background defines the lush mossy ruined temple architecture and forest palette; image 4 is a repeated sprite strip showing ONE soul crystal design, not a count or layout to copy.
Story: the forest realm island is breaking apart. Show giant mature trees and a moss-covered stone temple visibly TILTING with broken foundations, huge exposed roots being ripped out of soil, large detached chunks of ground FALLING into the void, and a clearly SNAPPING vine bridge with two separated ragged ends over an open gap. Green and gold forest illumination, red-orange collapse light runs along the major ground cracks. EXACTLY THREE violet soul crystals total, each a single upright elongated faceted amethyst spindle matching image 4, glowing among separate ruins at THREE DISTINCT HEIGHTS. Make the three crystals countable and separated, not clusters of extra crystals.
Style: match the rich painted PIXEL ART of image 1 with visible crisp pixel clusters, stepped edges and pixel-built lighting. No smooth airbrush, no photographic textures, no vector illustration. Deep navy cosmic sky with small spiral galaxies wherever sky is visible. Main palette deep green #0e3b2a, moss #3f7d3a, gold light #e8c86a, collapse glow #ff6a3d, crystal violet #b77cff.
Narrative action and every crystal entirely within the TOP 72% of frame. BOTTOM QUARTER is dark quiet green-navy abyss mist, minimal detail and low contrast, darker than everything above; no important objects or bright cracks there. This darkness is part of the natural scene, not a drawn panel or border.
Text: none. Absolutely no people, human faces, creatures, humanoid figures, human statues, face-like patterns, letters, glyphs, inscriptions, runes, symbols, logos, UI, frames, borders or watermark. Temple masonry is plain stone with no writing.
TAKE B composition: a closer dramatic low viewpoint looking UP ACROSS the snapped vine bridge toward a huge temple on the upper RIGHT. The bridge's near end enters from the middle LEFT, its loose vine ropes recoil into the empty central chasm, and the far end hangs off a visibly tilted temple terrace. An immense uprooted tree on the left arches diagonally over the chasm; a second smaller tree tips off the right ledge. Detached slabs tumble downward through the middle, ending above y72%. Three glowing crystal spindles on three small separated ruin ledges at approximately (72%,29%), (43%,45%), (22%,61%). Emphasize the deep chasm, torn roots and broken bridge close to the camera, with the temple looming behind; clearly different from a distant whole-island panorama.
~~~

### cg_beast-v1

참조 순서: C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_muspelheim/bg_far.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png

~~~text
Use case: illustration-story. Asset: cg_beast, stage 7 narration background for Smash Nine Realms. Generate ONE complete opaque landscape 16:9 scene, at the largest available native resolution preferably 2048x1152 or larger and at least 1600px wide. Input images are REFERENCES, not edit targets. Image 1 cg_prologue is the primary painted pixel-art style anchor. Image 2 title_bg defines the same cosmic fantasy world and pixel clusters. Image 3 Muspelheim is the lava realm architecture, basalt landscape and palette. Image 4 is a strip showing successive poses of ONE magma boar: copy its creature DESIGN, not the strip or repeated creatures.
Scene: a GIANT MAGMA BOAR dominates the volcanic realm, camera LOW near ground level, head lowered and body tense READY TO CHARGE, one forehoof actively scraping and pawing a fresh furrow in the ground, a small spray of scraped black rock and embers clearly tied to that hoof. It is the ONLY creature. Preserve the reference boar: very heavy low barrel-shaped dark ROCK body with segmented craggy basalt armor, glowing orange-yellow lava CRACKS between plates, a swept ridge of sharp rock SPIKES along its back, a short unmistakably boar snout, TWO large curved upward tusks. All body parts are stone, not fur. Four short sturdy legs, no extra legs or tusks. No humanoid expression. Huge compared with the distant plain volcanic ruins.
Lava beneath and behind the belly illuminates the underside, jaw and tusks from BELOW. Smoke curls and embers rise; tall eruption pillars clearly visible BEHIND it. Distant dark lava-realm fortress silhouettes and volcano landforms echo image 3; plain masonry without any glyphs. A small area of DEEP NAVY sky with a faint spiral galaxy is visible high above through dark smoke.
Style: rich painted PIXEL ART matching image 1, crisp visible pixel clusters and stepped edges, pixel-built ember light, no airbrushed gradients, no photorealism, no glossy 3D. Palette dark rock #2a1410, lava #ff5a1f, hot core #ffd27a, smoke #4a2a2a, only sparse dark navy sky.
All important beast features, the scraping hoof, ground furrow and lava light lie above y72%. The BOTTOM QUARTER is dark quiet cooled rock and deep smoky shadow with very little detail and low contrast, no bright lava rivers in it, no creature limbs hidden by it. Blend naturally into the scene without drawing a rectangular panel.
Text: none. No people, human faces, humanoid figures, human statues, secondary creatures, face-like rocks, letters, glyphs, runes, inscriptions, logos, UI, frames, borders or watermark.
TAKE A: monumental three-quarter SIDE view. The boar faces RIGHT with head near x72%, shoulders x56% and rump x30%. Whole body spans about x18%-85%, y20%-70%, the two curved tusks clearly silhouetted at the right. One near forehoof at x63% scratches backward through the ground, throwing low embers leftward. Two distant eruption pillars bracket the body without obscuring its silhouette. The massive long diagonal spiked back leads the eye toward the lowered snout; emphasize its huge weight and the lava underlighting.
~~~

### cg_beast-v2

참조 순서: C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_muspelheim/bg_far.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png

~~~text
Use case: illustration-story. Asset: cg_beast, stage 7 narration background for Smash Nine Realms. Generate ONE complete opaque landscape 16:9 scene, at the largest available native resolution preferably 2048x1152 or larger and at least 1600px wide. Input images are REFERENCES, not edit targets. Image 1 cg_prologue is the primary painted pixel-art style anchor. Image 2 title_bg defines the same cosmic fantasy world and pixel clusters. Image 3 Muspelheim is the lava realm architecture, basalt landscape and palette. Image 4 is a strip showing successive poses of ONE magma boar: copy its creature DESIGN, not the strip or repeated creatures.
Scene: a GIANT MAGMA BOAR dominates the volcanic realm, camera LOW near ground level, head lowered and body tense READY TO CHARGE, one forehoof actively scraping and pawing a fresh furrow in the ground, a small spray of scraped black rock and embers clearly tied to that hoof. It is the ONLY creature. Preserve the reference boar: very heavy low barrel-shaped dark ROCK body with segmented craggy basalt armor, glowing orange-yellow lava CRACKS between plates, a swept ridge of sharp rock SPIKES along its back, a short unmistakably boar snout, TWO large curved upward tusks. All body parts are stone, not fur. Four short sturdy legs, no extra legs or tusks. No humanoid expression. Huge compared with the distant plain volcanic ruins.
Lava beneath and behind the belly illuminates the underside, jaw and tusks from BELOW. Smoke curls and embers rise; tall eruption pillars clearly visible BEHIND it. Distant dark lava-realm fortress silhouettes and volcano landforms echo image 3; plain masonry without any glyphs. A small area of DEEP NAVY sky with a faint spiral galaxy is visible high above through dark smoke.
Style: rich painted PIXEL ART matching image 1, crisp visible pixel clusters and stepped edges, pixel-built ember light, no airbrushed gradients, no photorealism, no glossy 3D. Palette dark rock #2a1410, lava #ff5a1f, hot core #ffd27a, smoke #4a2a2a, only sparse dark navy sky.
All important beast features, the scraping hoof, ground furrow and lava light lie above y72%. The BOTTOM QUARTER is dark quiet cooled rock and deep smoky shadow with very little detail and low contrast, no bright lava rivers in it, no creature limbs hidden by it. Blend naturally into the scene without drawing a rectangular panel.
Text: none. No people, human faces, humanoid figures, human statues, secondary creatures, face-like rocks, letters, glyphs, runes, inscriptions, logos, UI, frames, borders or watermark.
TAKE B: intimidating almost FRONTAL three-quarter low view, boar turned a little toward LEFT, foreshortened massive shoulders and lowered head in the centre-left x45%, one tusk on each side of the snout. Body recedes diagonally toward upper RIGHT so the spiked back remains clearly readable. One near forehoof at x35% scrapes forward in the visible mid-ground, a broad fresh gouge and small rock spray show imminent charge. The boar spans x23%-82%, y15%-70%. An eruption plume behind the right shoulder and a second farther left create a strong depth corridor. More near-symmetrical confrontation and smoky red rim lighting than the side-on take, but keep the same boar identity and unobscured body silhouette.
~~~

### cg_heart-v1

참조 순서: C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_center/bg_far.png

~~~text
Use case: illustration-story. Asset: cg_heart, stage 9 opening narration background for Smash Nine Realms. Generate ONE complete opaque landscape 16:9 scene at the largest available native resolution preferably 2048x1152 or larger and at least 1600px wide. Input images are REFERENCES, not edit targets. Image 1 cg_prologue is the primary painted pixel-art style anchor and exact HEART identity; image 2 title_bg supports the pixel clusters and cosmic realm visual language; image 3 realm_center defines Yggdrasil's broad canopy, braided trunk, root-and-stone arena and violet setting.
Scene: the final arena UNDER the gigantic world tree. A clearly CIRCULAR FLOOR made of interlocking roots and worn plain stone slabs is seen in perspective. Above the floor, held in the fork of the enormous twisting tree trunk, hangs a vivid PINK HEART-SHAPED CORE with a visibly TWISTED asymmetric contour, jagged luminous CRACKS and branching DARK VIOLET VEINS across the pink surface. The heart must read as a corrupted version of the reference heart, never an anatomical organ or face. Heart centre around y29%, crown of tree fills upper frame, cosmic deep navy sky and faint galaxies visible between outer branches.
EXACTLY FIVE SEPARATE PILLARS of dark violet SOUL FLAME rise FROM FIVE distinct points on the circular FLOOR TOWARD the heart. Make all five easy to count, with gaps between them: five continuous non-anthropomorphic swirling columns of smoke-fire, each with a broad uneven base, twisting jagged tapering flame tongues and multiple wispy tips. Dark interiors #1a0f2e, violet luminous edges #9b5cff. Pure abstract fire, NOT ghosts or spirits with bodies, no round heads, no shoulders, arms, robes, eyes, mouths, faces or humanoid silhouettes. Do not let pillars merge into one cloud or divide into extra columns. There are FIVE visible bases and FIVE distinct columns. Faint sparse pink light motes.
Palette violet #3b1d5e, dark flame #1a0f2e, flame edge #9b5cff, heart #ff4fd8, crack light #ffd6f5. Rich painted PIXEL ART matching image 1 with crisp visible pixel clusters, stepped edges, clear painterly depth; no airbrushed smoothness and no photographic or 3D rendering.
The floor circle and all flame bases lie between y49%-68%; all important story features stay above y72%. The BOTTOM QUARTER is naturally dark quiet purple shadow with very little detail, no bright cracks, roots, flames or important objects. Do not draw a black rectangle or a panel; use a natural deep shadow foreground.
Text: none. Absolutely no people, creatures, human faces, humanoid figures, human statues, face-like patterns, letters, glyphs, runes, inscriptions, magic writing, symbols, logos, UI, frame, border or watermark. Stone floor and architecture have no written ornament.
TAKE A: solemn FRONTAL near-symmetrical composition. Broad tree canopy arches over the centred twisted heart at x50%, y28%. The circular root-and-stone floor is a wide clear ellipse beneath it. Place the five soul-flame columns along a shallow arc, ordered left to right with bases near (18%,62%), (34%,56%), (50%,64%), (66%,56%), (82%,62%). Pillars have varied heights and lean inward toward the heart but remain fully separated. The giant trunk frames the heart and the five flames, strongly readable like a final battleground.
~~~

### cg_heart-v2

참조 순서: C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_center/bg_far.png

~~~text
Use case: illustration-story. Asset: cg_heart, stage 9 opening narration background for Smash Nine Realms. Generate ONE complete opaque landscape 16:9 scene at the largest available native resolution preferably 2048x1152 or larger and at least 1600px wide. Input images are REFERENCES, not edit targets. Image 1 cg_prologue is the primary painted pixel-art style anchor and exact HEART identity; image 2 title_bg supports the pixel clusters and cosmic realm visual language; image 3 realm_center defines Yggdrasil's broad canopy, braided trunk, root-and-stone arena and violet setting.
Scene: the final arena UNDER the gigantic world tree. A clearly CIRCULAR FLOOR made of interlocking roots and worn plain stone slabs is seen in perspective. Above the floor, held in the fork of the enormous twisting tree trunk, hangs a vivid PINK HEART-SHAPED CORE with a visibly TWISTED asymmetric contour, jagged luminous CRACKS and branching DARK VIOLET VEINS across the pink surface. The heart must read as a corrupted version of the reference heart, never an anatomical organ or face. Heart centre around y29%, crown of tree fills upper frame, cosmic deep navy sky and faint galaxies visible between outer branches.
EXACTLY FIVE SEPARATE PILLARS of dark violet SOUL FLAME rise FROM FIVE distinct points on the circular FLOOR TOWARD the heart. Make all five easy to count, with gaps between them: five continuous non-anthropomorphic swirling columns of smoke-fire, each with a broad uneven base, twisting jagged tapering flame tongues and multiple wispy tips. Dark interiors #1a0f2e, violet luminous edges #9b5cff. Pure abstract fire, NOT ghosts or spirits with bodies, no round heads, no shoulders, arms, robes, eyes, mouths, faces or humanoid silhouettes. Do not let pillars merge into one cloud or divide into extra columns. There are FIVE visible bases and FIVE distinct columns. Faint sparse pink light motes.
Palette violet #3b1d5e, dark flame #1a0f2e, flame edge #9b5cff, heart #ff4fd8, crack light #ffd6f5. Rich painted PIXEL ART matching image 1 with crisp visible pixel clusters, stepped edges, clear painterly depth; no airbrushed smoothness and no photographic or 3D rendering.
The floor circle and all flame bases lie between y49%-68%; all important story features stay above y72%. The BOTTOM QUARTER is naturally dark quiet purple shadow with very little detail, no bright cracks, roots, flames or important objects. Do not draw a black rectangle or a panel; use a natural deep shadow foreground.
Text: none. Absolutely no people, creatures, human faces, humanoid figures, human statues, face-like patterns, letters, glyphs, runes, inscriptions, magic writing, symbols, logos, UI, frame, border or watermark. Stone floor and architecture have no written ornament.
TAKE B: an OBLIQUE view from the LEFT edge of the circular arena, with strong diagonal perspective. The twisted heart hangs offset to the RIGHT at x65%, y27%, framed by a massive fork of the trunk. The arena ellipse recedes toward the right; great roots sweep in from upper left and around the circle. Five flame bases occupy clearly separated points along its tilted arc: approximately (20%,61%), (36%,53%), (51%,65%), (66%,56%), (82%,63%). All five irregular ribbons rise and bend toward the offset heart, still clearly countable and entirely abstract, no humanoid masses. Sparse pink motes trace the diagonal flow. Give the left opening more navy galaxy sky and asymmetrical violet backlighting, clearly different from a frontal centred composition.
~~~

### cg_beast-v3

참조 순서: C:\Users\TH\.codex\generated_images\01a17200-5b83-7b52-b1d3-46cce7b2a1e4\exec-f2cfb96d-c1b8-414e-819c-36d1e11d564e.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_muspelheim/bg_far.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png

~~~text
Use case: precise-object-edit. This is a targeted composition repair of cg_beast cg_beast-v1; generate an opaque landscape 16:9 image at largest available native resolution, preferably 2048x1152 or larger and at least 1600px wide.
REFERENCE ROLES: Image 1 is the EDIT TARGET. Images 2 and 3 are the cg_prologue and title_bg painted pixel-art STYLE anchors; image 4 is the Muspelheim lava-realm background; image 5 is the original magma boar sprite design. Preserve image 1's single giant rock magma boar, its right-facing three-quarter SIDE view, lowered boar head, two upturned curved tusks, craggy dark basalt armor, glowing orange lava cracks, back spikes, pawing pose, smoke, embers, distant volcano eruptions, navy galaxy sky, architecture and crisp painted pixel texture.
CHANGE ONLY THE FRAMING TO FIX THE DIALOGUE SAFE AREA. Pull the camera back and aim slightly upward so the ENTIRE BOAR including ALL FEET and the gouge/scraped sparks is contained in the top 68 percent of the image. All hoof ground-contact points at y63%-65%, no boar part below y68%. Keep its shoulders massive and low-angle by making distant ruins tiny. The boar should span about 65% of canvas width, centred horizontally. The lava-lit ground shelf supporting it runs at y65%. Below this shelf, the bottom 30% is an unlit very dark cooled-basalt foreground with soft low-contrast shadow/mist and ALMOST NO texture or visible rocks. NO orange fissures, embers, reflections, bright edges, sparks or detailed objects anywhere below y72%. This is continuous natural scene depth, never a rectangular black panel, frame or border.
Above y68%, retain a clear scraping forehoof with a small rock/ember spray and a fresh groove, and clear lava UNDERLIGHT on belly and tusks. Tall eruption pillars behind the beast remain visible. The boar is the ONLY creature, keep its identity consistent with the sprite design.
Palette dark rock #2a1410, lava #ff5a1f, hot core #ffd27a, smoke #4a2a2a. Painted pixel art exactly like image 2, visible crisp clusters, no airbrush or photographic look. Text NONE. No people, human faces, humanoid figures, human statues, secondary creatures, letters, glyphs, runes, inscriptions, logos, UI, frames, borders or watermark. Do not add new elements or change the creature design.
~~~

### cg_beast-v4

참조 순서: C:\Users\TH\.codex\generated_images\01a17200-5b83-7b52-b1d3-46cce7b2a1e4\exec-4aeaa96f-5b0c-47d6-9a37-f87b162d9c3f.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/story/cg_prologue.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/ui/title_bg.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/smash-nine-prototype/assets/art/realm_muspelheim/bg_far.png → C:/Users/TH/Documents/AI/GameProject/SmashNine-units/story-art-a/SmashNine/art/bakeoff/monsters/muspelheim_magma_boar-idle-v1.png

~~~text
Use case: precise-object-edit. This is a targeted composition repair of cg_beast cg_beast-v2; generate an opaque landscape 16:9 image at largest available native resolution, preferably 2048x1152 or larger and at least 1600px wide.
REFERENCE ROLES: Image 1 is the EDIT TARGET. Images 2 and 3 are the cg_prologue and title_bg painted pixel-art STYLE anchors; image 4 is the Muspelheim lava-realm background; image 5 is the original magma boar sprite design. Preserve image 1's single giant rock magma boar, its near-FRONTAL three-quarter view facing slightly LEFT, lowered boar head, two upturned curved tusks, craggy dark basalt armor, glowing orange lava cracks, back spikes, pawing pose, smoke, embers, distant volcano eruptions, navy galaxy sky, architecture and crisp painted pixel texture.
CHANGE ONLY THE FRAMING TO FIX THE DIALOGUE SAFE AREA. Pull the camera back and aim slightly upward so the ENTIRE BOAR including ALL FEET and the gouge/scraped sparks is contained in the top 68 percent of the image. All hoof ground-contact points at y63%-65%, no boar part below y68%. Keep its shoulders massive and low-angle by making distant ruins tiny. The boar should span about 65% of canvas width, centred horizontally. The lava-lit ground shelf supporting it runs at y65%. Below this shelf, the bottom 30% is an unlit very dark cooled-basalt foreground with soft low-contrast shadow/mist and ALMOST NO texture or visible rocks. NO orange fissures, embers, reflections, bright edges, sparks or detailed objects anywhere below y72%. This is continuous natural scene depth, never a rectangular black panel, frame or border.
Above y68%, retain a clear scraping forehoof with a small rock/ember spray and a fresh groove, and clear lava UNDERLIGHT on belly and tusks. Tall eruption pillars behind the beast remain visible. The boar is the ONLY creature, keep its identity consistent with the sprite design.
Palette dark rock #2a1410, lava #ff5a1f, hot core #ffd27a, smoke #4a2a2a. Painted pixel art exactly like image 2, visible crisp clusters, no airbrush or photographic look. Text NONE. No people, human faces, humanoid figures, human statues, secondary creatures, letters, glyphs, runes, inscriptions, logos, UI, frames, borders or watermark. Do not add new elements or change the creature design.
~~~
