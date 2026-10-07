# Vanaheim realm art

Godot 4.7용 바나하임 원경·중경·플랫폼 세트다. 내장 `image_gen` 원본을 `tests/art_preview/realms_b/build_assets.gd`에서 640×360 기준 픽셀 그리드와 20색 팔레트로 줄인 뒤 2배 최근접 확대했다.

| 파일 | 크기 | 비고 |
|---|---:|---|
| `bg_far.png` | 1280×720 | 완전 불투명 숲·침수 신전 원경 |
| `bg_mid.png` | 1280×720 | 투명한 수관·신전 전경 프레임 |
| `platform_main.png` | 188×46 | 46px 캡 + 96px 반복 중앙 + 46px 캡 |
| `platform_sub.png` | 160×32 | 32px 캡 + 96px 반복 중앙 + 32px 캡 |

팔레트: `#04110E #071A16 #0B251E #103129 #153E32 #1B4D3B #235D45 #2D6F4F #39825A #489565 #5BA972 #70BD7E #88CF91 #17383B #235057 #326A6E #4B817C #78965C #A3AD62 #D4C46F`.

## 생성 프롬프트

원경: `Vanaheim ancient sunken temple reclaimed by enchanted forest, a 1280x720 platform-brawler far background; edge trees, distant mossy arches, quiet pools and restrained spirit lights; polished limited-palette 2D pixel art; exact 16:9; large calm dark y=150..650 fight band and no central trunk; no foreground platforms, characters, UI, text, logo or watermark; Concept2 is style/worldbuilding reference only.`

플랫폼 시트: `Transparent 16:9 pixel-art source sheet with exactly two isolated side-view Vanaheim platforms: ancient green temple-stone main platform above and thin mossy ledge below; perfectly flat tops, symmetric caps, restrained moss and root carvings, long repeatable middles; no environment, characters, text, logo or watermark.`

`bg_mid.png`는 원경 가장자리와 상단 모서리 수관을 투명 실루엣으로 재구성했다. 녹색 전용 팔레트라 프레이 외 다른 녹색 캐릭터의 윤곽은 사람이 실제 전투에서 확인해야 한다.
