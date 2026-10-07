# Ultimate VFX strips

`CODEX-ART-10`에서 제작한 1x 픽셀 아트 궁극기 효과입니다. 모든 애니메이션은 왼쪽에서 시작하는 단일 가로 스트립이며 PNG RGBA입니다. `*_source.png`는 생성 원본, 이름에 `_source`가 없는 파일이 게임용 결과물입니다.

| 파일 | 프레임 | 프레임 크기 | 권장 FPS | 앵커(px) | 반복 | Additive |
|---|---:|---:|---:|---:|---|---|
| `frey_ult_charge.png` | 6 | 128x128 | 24 | (64, 124), 발 중앙 | 아니오 | 예 |
| `frey_ult_wave.png` | 8 | 256x96 | 30 | (0, 96), 좌하단 | 아니오 | 예 |
| `yuki_ult_seal.png` | 8 | 256x256 | 12 | (128, 128), 중앙 | 예 | 아니오 |
| `yuki_ult_burst.png` | 6 | 256x256 | 30 | (128, 128), 중앙 | 아니오 | 예 |
| `luna_ult_transform.png` | 8 | 192x192 | 24 | (96, 96), 가슴 중앙 | 아니오 | 예 |
| `luna_ult_laser.png` | 4 | 128x96 | 24 | (0, 48), 좌중앙 | 예 | 예 |
| `luna_ult_laser_head.png` | 4 | 96x96 | 24 | (48, 48), 중앙 | 아니오 | 예 |
| `nova_ult_core.png` | 6 | 128x128 | 18 | (64, 64), 중앙 | 예 | 아니오 |
| `nova_ult_burst.png` | 8 | 256x256 | 48 | (128, 128), 중앙 | 아니오 | 아니오 |
| `rio_ult_circle.png` | 6 | 192x192 | 18 | (96, 96), 중앙 | 예 | 예 |
| `rio_ult_impact.png` | 6 | 64x64 | 36 | (32, 32), 중앙 | 아니오 | 예 |
| `ult_cutin_band.png` | 1 | 640x112 | - | (320, 56), 중앙 | - | 예 |

## 통합 메모

- `frey_ult_wave.png`는 오른쪽 진행용입니다. 왼쪽 파동은 `flip_h` 또는 음수 X 스케일로 미러링합니다.
- `yuki_ult_seal.png`는 경고 0.7초와 활성 2.35초 동안 같은 루프를 사용하고, 활성 진입 시 색/알파 펄스를 코드에서 추가하는 구성이 적합합니다. 게임에서는 약 410px로 확대 예정이므로 nearest 필터를 유지합니다.
- `luna_ult_laser.png`는 좌우 끝 픽셀이 동일한 타일 세그먼트입니다. 타일 연결을 위해 좌우만 의도적으로 투명 여백이 없고 상하에는 35px 이상의 여백이 있습니다.
- `nova_ult_core.png`와 `nova_ult_burst.png`는 검은 중심을 보존해야 하므로 기본은 normal alpha를 권장합니다. 링만 별도 복제해 additive로 겹치면 더 강한 발광을 만들 수 있습니다.
- `rio_ult_impact.png`는 무채색입니다. 각 보석검의 색으로 `modulate`한 뒤 additive로 그립니다.
- 나머지 모든 프레임은 네 방향에 최소 3px의 투명 여백이 있습니다.
- Import 설정은 filter off, mipmaps off를 권장합니다.

## 재생성 및 검증

```powershell
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/ult_vfx_b/build_vfx.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/ult_vfx_b/verify_vfx.gd
```

빌더는 생성 원본을 그리드로 자른 뒤 Godot `Image` API로 알파 정리, 최근접 크기 조정, 캐릭터별 제한 팔레트 양자화, 프레임 정렬을 수행합니다. 보고용 `reports/codex-art-10/contact_sheet.png`도 같은 빌드에서 다시 생성됩니다.
