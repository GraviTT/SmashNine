# Ultimate VFX strips

`CODEX-ART-10`의 고해상도 생성 원본을 `CODEX-ART-14`에서 2배 전투 스케일용 1x 밀도로 다시 추출한 궁극기 효과다. 모든 애니메이션은 왼쪽에서 시작하는 단일 가로 스트립이며 PNG RGBA다. 프레임 수와 타이밍은 유지했고 프레임 크기와 앵커는 2배가 되었다. `*_source.png`는 생성 원본, 이름에 `_source`가 없는 파일이 게임용 결과물이다.

| 파일 | 프레임 | 프레임 크기 | 권장 FPS | 앵커(px) | 반복 | Additive |
|---|---:|---:|---:|---:|---|---|
| `frey_ult_charge.png` | 6 | 256x256 | 24 | (128, 248), 발 중앙 | 아니오 | 예 |
| `frey_ult_wave.png` | 8 | 512x192 | 30 | (0, 192), 좌하단 | 아니오 | 예 |
| `yuki_ult_seal.png` | 8 | 512x512 | 12 | (256, 256), 중앙 | 예 | 아니오 |
| `yuki_ult_burst.png` | 6 | 512x512 | 30 | (256, 256), 중앙 | 아니오 | 예 |
| `luna_ult_transform.png` | 8 | 384x384 | 24 | (192, 192), 가슴 중앙 | 아니오 | 예 |
| `luna_ult_laser.png` | 4 | 256x192 | 24 | (0, 96), 좌중앙 | 예 | 예 |
| `luna_ult_laser_head.png` | 4 | 192x192 | 24 | (96, 96), 중앙 | 아니오 | 예 |
| `nova_ult_core.png` | 6 | 256x256 | 18 | (128, 128), 중앙 | 예 | 아니오 |
| `nova_ult_burst.png` | 8 | 512x512 | 48 | (256, 256), 중앙 | 아니오 | 아니오 |
| `rio_ult_circle.png` | 6 | 384x384 | 18 | (192, 192), 중앙 | 예 | 예 |
| `rio_ult_impact.png` | 6 | 128x128 | 36 | (64, 64), 중앙 | 아니오 | 예 |
| `ult_cutin_band.png` | 1 | 640x112 | - | (320, 56), 중앙 | - | 예 |

## 통합 메모

- `frey_ult_wave.png`는 오른쪽 진행용이다. 왼쪽 파동은 `flip_h` 또는 음수 X 스케일로 미러링한다.
- `yuki_ult_seal.png`는 경고 0.7초와 활성 2.35초 동안 같은 루프를 사용하고, 활성 진입 시 색/알파 펄스를 코드에서 추가한다.
- `luna_ult_laser.png`는 256px 세그먼트를 반복하고 끝에 192px 헤드를 배치한다. 세그먼트와 헤드의 중앙 Y는 동일하다. 좌우 끝 픽셀은 타일 연결을 위해 동일하며, 좌우만 의도적으로 투명 여백이 없다.
- `nova_ult_core.png`와 `nova_ult_burst.png`는 검은 중심을 보존해야 하므로 기본은 normal alpha다. 링만 별도 복제해 additive로 겹칠 수 있다.
- `rio_ult_impact.png`는 무채색이다. 각 보석검의 색으로 `modulate`한 뒤 additive로 그린다.
- 레이저를 제외한 모든 프레임은 네 방향에 최소 3px의 투명 여백이 있다.
- `scripts/Vfx.gd`의 11개 앵커를 위 표대로 2배로 바꾸고, 기존 화면 크기를 유지하려면 호출부 표시 스케일을 공통 0.5배로 보정해야 한다. 프레임 수와 FPS는 그대로다.
- Import 설정은 filter off, mipmaps off를 권장한다.

## 재생성 및 검증

```powershell
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/fx_1x_b/build_fx.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/fx_1x_b/verify_fx.gd
```

빌더는 생성 원본을 그리드로 자른 뒤 Godot `Image` API로 알파 정리, 최종 1x 밀도 샘플링, 캐릭터별 제한 팔레트 양자화, 프레임 정렬을 수행한다. 완성된 저해상도 PNG를 확대하지 않는다. 보고용 `reports/codex-art-14/comparison.png`도 같은 빌드에서 다시 생성된다.
