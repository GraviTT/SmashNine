# Muspelheim realm art

Godot 4.7용 무스펠하임 원경·중경·플랫폼 세트다. 내장 `image_gen`으로 만든 원경/플랫폼 원본을 `tests/art_preview/realms_b/build_assets.gd`에서 640×360 기준 픽셀 그리드와 20색 팔레트로 줄인 뒤 2배 최근접 확대했다.

| 파일 | 크기 | 비고 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 완전 불투명 화산 원경 |
| `bg_mid.png` | 1280×720 | 투명한 현무암 전경 프레임 |
| `platform_main.png` | 200×52 | 52px 캡 + 96px 반복 중앙 + 52px 캡 |
| `platform_sub.png` | 160×32 | 32px 캡 + 96px 반복 중앙 + 32px 캡 |

팔레트: `#10070A #19090C #250D10 #321116 #43151A #581B1D #702321 #8B2D24 #A83A27 #C64A29 #E35E2C #F47B35 #FF9A45 #2A1B22 #3C2730 #56333A #704149 #8E5154 #BD6A5E #E99170`.

## 생성 프롬프트

원경: `Muspelheim volcanic-caldera far background for a 1280x720 platform-brawler; distant basalt forge citadel and lava falls high on the horizon; polished limited-palette 2D pixel art; exact 16:9; calm, dark, low-detail y=150..650 fight band; no foreground platforms, characters, UI, text, logo, watermark; Concept2 is style/worldbuilding reference only.`

플랫폼 시트: `Transparent 16:9 pixel-art source sheet with exactly two isolated side-view Muspelheim platforms: heavy black-basalt main platform above and thin one-way ledge below; perfectly flat tops, symmetric caps, restrained ember fissures, long repeatable middles; no scene, fire pillars, characters, text, logo or watermark.`

`bg_mid.png`는 원경 원본의 가장자리 색을 어둡게 재매핑해 만든 투명 실루엣이다. 실제 분출 경고/불기둥을 가리지 않도록 플랫폼 균열 발광은 제한했다.

## 1.5배 렐름 배경 갱신 (CODEX-ART-15)

- `bg_far.png` / `bg_mid.png`: 1920×1080, 960×540 논리 픽셀을 2배 최근접 확대, 좌상단 `(0, 0)` 기준.
- 원경 프롬프트: 기존 무스펠하임을 카메라 1.5배 줌아웃한 16:9 확장 장면. 화산·현무암 성채·용암 폭포·외곽 칼데라를 확장하되 중앙 전투 띠의 용암 밝기를 억제.
- 중경: 기존 투명 현무암 프레임을 새 논리 격자에서 재구성하고 알파를 0/0.5/1로 정리했다.
