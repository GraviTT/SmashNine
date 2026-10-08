# Basic attack and skill VFX strips (2x canvas, 1x pixel density)

`CODEX-ART-16`에서 공격 범위 확대에 맞춰 다시 만든 6프레임 RGBA 가로 스트립입니다. 기존 ART-13과 재생 순서·오른쪽 방향·blend 방식은 같고, 각 프레임의 가로/세로와 앵커만 정확히 2배입니다. 원화를 새 크기로 직접 후처리했으므로 기존 1배 PNG를 nearest 2배 한 2~3px 블록이 아니라 1px 디테일을 유지합니다.

| 파일 | 프레임 | 프레임 크기 | 전체 PNG | 권장 FPS | 앵커(px) | Additive | 반복 |
|---|---:|---:|---:|---:|---|---|---|
| `frey_slash.png` | 6 | 384x256 | 2304x256 | 36 | (0, 128) | 예 | 아니요 |
| `frey_k.png` | 6 | 448x192 | 2688x192 | 30 | (0, 96) | 예 | 아니요 |
| `frey_l.png` | 6 | 256x384 | 1536x384 | 30 | (128, 376) | 예 | 아니요 |
| `yuki_slash.png` | 6 | 384x256 | 2304x256 | 30 | (0, 128) | 예 | 아니요 |
| `yuki_k.png` | 6 | 256x256 | 1536x256 | 18 | (128, 128) | 아니요 | 아니요 |
| `yuki_l.png` | 6 | 384x384 | 2304x384 | 24 | (192, 192) | 예 | 아니요 |
| `luna_slash.png` | 6 | 384x256 | 2304x256 | 30 | (0, 128) | 예 | 아니요 |
| `luna_k.png` | 6 | 320x192 | 1920x192 | 30 | (0, 96) | 예 | 아니요 |
| `luna_l.png` | 6 | 384x384 | 2304x384 | 24 | (192, 192) | 예 | 아니요 |
| `luna_brave_slash.png` | 6 | 448x256 | 2688x256 | 36 | (0, 128) | 예 | 아니요 |
| `nova_slash.png` | 6 | 320x256 | 1920x256 | 36 | (0, 128) | 예 | 아니요 |
| `nova_k.png` | 6 | 448x192 | 2688x192 | 30 | (0, 96) | 예 | 아니요 |
| `nova_l.png` | 6 | 384x384 | 2304x384 | 24 | (192, 376) | 아니요 | 아니요 |
| `rio_slash.png` | 6 | 384x256 | 2304x256 | 36 | (0, 128) | 예 | 아니요 |
| `rio_k.png` | 6 | 512x192 | 3072x192 | 30 | (0, 96) | 예 | 아니요 |
| `rio_l.png` | 6 | 256x320 | 1536x320 | 18 | (0, 160) | 아니요 | 아니요 |

## 통합 메모

- `hframes = 6`, one-shot 재생입니다. 왼쪽 공격은 `flip_h` 또는 X축 음수 스케일로 미러링합니다.
- ART-13 대비 프레임과 앵커가 2배이므로, 기존과 같은 월드 크기로 그리려면 리드 코드에서 텍스처 표시 배율을 0.5 기준으로 다시 맞춰야 합니다. 공격 판정·도달 거리 자체는 제품 코드가 소유합니다.
- 위·아래 기본 공격은 `(0, height / 2)` 몸 앵커를 회전 중심으로 사용합니다.
- `nova_k.png`는 판정 없는 이동 잔상입니다.
- `nova_l.png`, `rio_l.png`, `yuki_k.png`는 normal alpha 권장입니다. 나머지 Additive 자산은 흰 코어가 과포화되면 `modulate.a = 0.7~0.85` 또는 normal alpha로 낮춥니다.
- import는 filter off, mipmaps off를 권장합니다. 새 스트립은 **1 art pixel = 1 texture pixel**입니다.

## 재생성과 검증

```powershell
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/attack_vfx_2x_a/build_attack_vfx.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/attack_vfx_2x_a/verify.gd
```

Godot `Image` API 빌더는 고해상도 원화를 6프레임으로 분리하고, 배경 정리, nearest 축소, 6색 팔레트 양자화, 공통 배율·앵커 정렬을 적용합니다. Frey/Luna/Brave Luna slash는 잘린 호를 없애기 위해 ART-16 신규 원화를 사용합니다.
