# CODEX-ART-05A preview and verification

이 폴더는 제품 소스를 수정하지 않고 Unit A 아트를 생성·검증하는 도구만 포함합니다.

- `build_assets.gd` — 생성 원본을 Godot `Image` API로 셀 분할하고, 알파 컷오프, 최근접 축소, 2× 픽셀 격자, 색상 양자화, 중심/발 기준 정렬을 적용합니다.
- `verify_assets.gd` — 정확한 크기, RGBA8, 투명/불투명 픽셀 공존, 사용/빈 셀, 기준선, 2× 픽셀 격자를 검사합니다.
- `preview.gd` — 모든 사용 프레임을 2배 최근접 크기로 배치하고 Frey 기준 프레임과 함께 `reports/codex-art-05a/preview.png`를 캡처합니다.

프로젝트 폴더에서 실행합니다.

```powershell
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/monsters_a/build_assets.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --headless --path . -s tests/art_preview/monsters_a/verify_assets.gd
& 'C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe' --path . -s tests/art_preview/monsters_a/preview.gd
```

Windows 샌드박스의 루트 인증서 저장소 오류는 알려진 환경 잡음입니다.
