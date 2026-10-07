# Effects B art build and preview

이 폴더는 CODEX-ART-05 유닛 B의 재현 가능한 이미지 원본 12개와 Godot 후처리 스크립트를 담는다.

- `source_*.png`: 내장 ImageGen이 만든 투명 대형 원본.
- `build_assets.gd`: Godot `Image` API만 사용해 알파 정리, 크롭, 최근접 축소, 팔레트 제한, 중앙 정렬, PNG 저장 및 규격 검증을 수행한다.
- 결과 프리뷰: `reports/codex-art-05b/preview.png` (960×600).

실행:

```powershell
C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe --headless --path smash-nine-prototype -s tests/art_preview/effects_b/build_assets.gd
```

프리뷰의 위 행은 프레이 2배 표시 옆의 히트 스파크 4프레임, 가운데 행은 투사체 5종의 게임 배율 2배, 아래 행은 카드 아이콘 6종의 UI 배율 1배다. 체크무늬는 투명 영역을 확인하기 위한 실제 합성 배경이다.
