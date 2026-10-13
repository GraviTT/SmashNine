# Frey 디테일 기준 재현

동일 원본 `reports/codex-art-36a/frey-idle/prepared.png`의 첫 칸을 동일 배율 `0.18761726`로 정규화했다. 내부 디테일은 알파가 불투명하고 상하좌우 이웃도 모두 불투명한 픽셀에서 RGB 평균 밝기의 4방향 라플라시안 절댓값 평균이다.

| 버전 | 색 수 | 내부 디테일 |
| --- | ---: | ---: |
| 현재 게임 idle F0 | 1,405 | 102.05 |
| ART-36 방식: BOX + 192색 팔레트 | 180 | 65.32 |
| BOX, 팔레트 없음 | 5,165 | 63.89 |
| LANCZOS, 팔레트 없음 | 5,193 | 69.45 |
| LANCZOS + unsharp radius 1 / 60% / threshold 2, 팔레트 없음 | 4,928 | 99.49 |

카드의 반올림 표(`102.0`, `65.3`, `63.9`, `69.4`, `99.5`)를 재현했다. 새 경로에 `--despill auto`까지 적용하면 내부 디테일 `99.50`, 색 수 `4,878`, 알파 경계 2px 안의 남은 초록 번짐 `0px`다.

재현 설정:

```text
--sheet reports/codex-art-36a/frey-idle/prepared.png
--grid 4x1 --pick 0 --bg #00ff00
--scale-by fixed:0.18761726
--reference smash-nine-prototype/assets/art/frey/frey_sheet.png:0:1
```

- 구 방식: `--resample box --sharpen 0 --despill off --palette tools/sprite_pipeline/palettes/frey.json`
- 새 방식: `--resample lanczos --sharpen 60 --despill auto --palette none`
