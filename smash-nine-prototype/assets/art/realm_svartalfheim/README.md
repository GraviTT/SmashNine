# Svartalfheim realm art

Godot 4.7용 스바르트알프하임 원경·중경·플랫폼 세트다. 내장 `image_gen` 원본을 `tests/art_preview/realms_b/build_assets.gd`에서 640×360 기준 픽셀 그리드와 20색 팔레트로 줄인 뒤 2배 최근접 확대했다.

| 파일 | 크기 | 비고 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 완전 불투명 지하 태엽 도시 원경 |
| `bg_mid.png` | 1280×720 | 투명한 암벽·건축 전경 프레임 |
| `platform_main.png` | 184×44 | 44px 캡 + 96px 반복 중앙 + 44px 캡 |
| `platform_sub.png` | 160×32 | 32px 캡 + 96px 반복 중앙 + 32px 캡 |

팔레트: `#090C10 #11161C #19212A #222D37 #2D3943 #394751 #485760 #586870 #263C43 #31515A #3E6870 #745438 #8B6440 #A97945 #C5904E #E0AA5B #F2C26D #6F4930 #9A5F32 #CA7734`.

## 생성 프롬프트

원경: `Svartalfheim cavernous clockwork-dwarf metropolis far background for a 1280x720 platform-brawler; distant foundries, gear towers, bridges and small furnace windows; polished limited-palette 2D pixel art; exact 16:9; edge-weighted vertical city and calm dark y=150..650 fight band; no foreground platforms, characters, UI, text, logo or watermark; Concept2 is style/worldbuilding reference only.`

플랫폼 시트: `Transparent 16:9 pixel-art source sheet with exactly two isolated side-view Svartalfheim platforms: dark iron-and-bronze main platform above and thin metal ledge below; flat tops, symmetric end housings, restrained rivets and braces, long repeatable middles; no environment, characters, text, logo or watermark.`

`bg_mid.png`는 원경 원본의 가장자리 색을 어둡게 재매핑한 투명 실루엣이다. 플랫폼은 상승형 배치가 배경 기계 구조와 혼동되지 않도록 밝은 황동색을 작은 면적으로만 썼다.

## 1.5배 렐름 배경 갱신 (CODEX-ART-15)

- `bg_far.png` / `bg_mid.png`: 1920×1080, 960×540 논리 픽셀을 2배 최근접 확대, 좌상단 `(0, 0)` 기준.
- 원경 프롬프트: 기존 스바르트알프하임을 카메라 1.5배 줌아웃한 16:9 확장 장면. 용광로·기어탑·광산 승강기·동굴 벽을 확장하고 황동 불빛은 작게 제한.
- 중경: 기존 투명 기계 도시 프레임을 새 논리 격자에서 재구성하고 알파를 0/0.5/1로 정리했다.
