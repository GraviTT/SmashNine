# Basic attack and skill VFX strips

`CODEX-ART-13`에서 제작한 1x 픽셀 아트 공격 이펙트입니다. 모든 PNG는 RGBA 가로 스트립이며, 오른쪽을 향하는 6개 동일 크기 프레임으로 구성됩니다. 아래 앵커는 각 프레임 안에서 캐릭터 또는 기술 원점에 맞출 픽셀 좌표입니다.

| 파일 | 프레임 | 프레임 크기 | 권장 FPS | 앵커(px) | Additive | 반복 |
|---|---:|---:|---:|---|---|---|
| `frey_slash.png` | 6 | 192x128 | 36 | (0, 64), 몸 왼쪽-중앙 | 예 | 아니요 |
| `frey_k.png` | 6 | 224x96 | 30 | (0, 48), 몸 왼쪽-중앙 | 예 | 아니요 |
| `frey_l.png` | 6 | 128x192 | 30 | (64, 188), 발밑-중앙 | 예 | 아니요 |
| `yuki_slash.png` | 6 | 192x128 | 30 | (0, 64), 몸 왼쪽-중앙 | 예 | 아니요 |
| `yuki_k.png` | 6 | 128x128 | 18 | (64, 64), 봉인 대상 중앙 | 아니요 | 아니요 |
| `yuki_l.png` | 6 | 192x192 | 24 | (96, 96), 결계 중앙 | 예 | 아니요 |
| `luna_slash.png` | 6 | 192x128 | 30 | (0, 64), 몸 왼쪽-중앙 | 예 | 아니요 |
| `luna_k.png` | 6 | 160x96 | 30 | (0, 48), 발사 원점 왼쪽-중앙 | 예 | 아니요 |
| `luna_l.png` | 6 | 192x192 | 24 | (96, 96), 몸 중앙 | 예 | 아니요 |
| `luna_brave_slash.png` | 6 | 224x128 | 36 | (0, 64), 몸 왼쪽-중앙 | 예 | 아니요 |
| `nova_slash.png` | 6 | 160x128 | 36 | (0, 64), 몸 왼쪽-중앙 | 예 | 아니요 |
| `nova_k.png` | 6 | 224x96 | 30 | (0, 48), 몸 왼쪽-중앙 | 예 | 아니요 |
| `nova_l.png` | 6 | 192x192 | 24 | (96, 188), 지면-중앙 | 아니요 | 아니요 |
| `rio_slash.png` | 6 | 192x128 | 36 | (0, 64), 몸 왼쪽-중앙 | 예 | 아니요 |
| `rio_k.png` | 6 | 256x96 | 30 | (0, 48), 몸 왼쪽-중앙 | 예 | 아니요 |
| `rio_l.png` | 6 | 128x160 | 18 | (0, 80), 몸 왼쪽-중앙 | 아니요 | 아니요 |

## 통합 메모

- `hframes = 6`, one-shot 재생을 전제로 합니다. 왼쪽 공격은 `flip_h` 또는 X축 음수 스케일로 미러링합니다.
- 위·아래 기본 공격은 해당 캐릭터의 `*_slash.png`를 회전해 사용하되, 프레임의 `(0, height / 2)` 몸 앵커가 회전 중심이 되게 맞춥니다.
- `nova_k.png`는 공격 판정이 없는 이동 잔상입니다. 노바 본체 뒤쪽에 필요하면 X 위치를 조금 당기되, 스트립 자체는 카드 규칙대로 오른쪽 진행으로 제작했습니다.
- `nova_l.png`와 `rio_l.png`, 종이 질감이 중요한 `yuki_k.png`는 normal alpha를 권장합니다. 표에서 Additive가 `예`인 스트립은 CanvasItemMaterial의 additive blend를 권장합니다.
- Additive 스트립도 흰 코어가 과포화되면 normal alpha로 낮추거나 `modulate.a`를 0.7~0.85로 조정하십시오.
- 가져오기 설정은 filter off, mipmaps off를 권장합니다. 1 art pixel = 1 screen pixel입니다.

## 재생성 및 검증

```powershell
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/attack_vfx_a/build_attack_vfx.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/attack_vfx_a/verify_attack_vfx.gd
```

빌더는 `reports/codex-art-13/source/`의 이미지 생성 원화를 Godot `Image` API로 6등분하고, 투명 배경 정리, nearest 축소, 제한 팔레트 양자화, 공통 프레임 배율과 앵커 정렬을 적용합니다.
