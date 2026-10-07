# Jotunheim realm art

Godot 4.7용 요툰하임 원경·중경·플랫폼 세트다. 내장 `image_gen` 원본을 `tests/art_preview/realms_b/build_assets.gd`에서 640×360 기준 픽셀 그리드와 20색 팔레트로 줄인 뒤 2배 최근접 확대했다.

| 파일 | 크기 | 비고 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 완전 불투명 거인 계곡 원경 |
| `bg_mid.png` | 1280×720 | 투명한 거석 전경 프레임 |
| `platform_main.png` | 188×46 | 46px 캡 + 96px 반복 중앙 + 46px 캡 |
| `platform_sub.png` | 160×32 | 32px 캡 + 96px 반복 중앙 + 32px 캡 |

팔레트: `#080B18 #0D1224 #131A31 #1A2340 #222D50 #2C3961 #374672 #455584 #566696 #6978A8 #7E8CBA #95A3CB #ADB9DC #C6D0EA #252741 #343650 #484965 #5F5D7D #777494 #9691AD`.

## 생성 프롬프트

원경: `Jotunheim storm-dark highland valley far background for a 1280x720 platform-brawler; colossal stone terraces, giant-carved monoliths and distant petrified ribcage; polished limited-palette 2D pixel art; exact 16:9; broad calm dark y=150..650 center for thin-ledge combat; no living giants, foreground platforms, characters, UI, text, logo or watermark; Concept2 is style/worldbuilding reference only.`

플랫폼 시트: `Transparent 16:9 pixel-art source sheet with exactly two isolated side-view Jotunheim platforms: massive slate monolith main platform above and thin giant-stone ledge below; flat tops, symmetric masonry ends, restrained runes and quake cracks, long repeatable middles; no snow, rubble, environment, characters, text, logo or watermark.`

`bg_mid.png`는 원경 가장자리의 거석을 어둡게 재매핑한 투명 실루엣이다. 지진 경고와 점프 회피를 읽기 쉽도록 밝은 룬은 발판 상단 강조선보다 약하게 유지했다.
