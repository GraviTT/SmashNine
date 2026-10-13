# Smash Nine 스프라이트 정규화 파이프라인

생성된 한 동작 전체에 **배율 하나만** 적용해 128×128 셀, 6열, 발 y=120 규격으로 정리한다. 프레임마다 크기를 바꾸거나 머리·팔다리를 붙이지 않는다. 한 프레임이 공통 배율에서 들어오지 않으면 실패하며, 해당 동작을 다시 생성하거나 동작 전체의 `fixed:` 값만 바꾼다.

## 사용

Codex 런타임 Python을 사용한다.

```powershell
$py = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'

# 현재 게임 시트에서 가장 많이 쓰인 192색 캐릭터 팔레트 작성
& $py tools/sprite_pipeline/make_palette.py `
  smash-nine-prototype/assets/art/frey/frey_sheet.png --id frey

# 생성기의 녹색 편차와 녹색 격자선 정리(필요할 때)
& $py tools/sprite_pipeline/prepare_raw.py raw.png prepared.png --grid 6x1

# 한 동작 정규화. 출력은 항상 128px 셀 6열(768×128)이다.
& $py tools/sprite_pipeline/normalize.py `
  --sheet prepared.png --grid 6x1 --bg '#00ff00' `
  --scale-by height:100 --resample lanczos --sharpen 60 --despill auto --palette none `
  --reference smash-nine-prototype/assets/art/frey/frey_sheet.png:1:6 `
  --compare-scale 4 `
  --title 'FREY WALK' --out-dir reports/example --name frey-walk-v1 `
  --candidate-out art/bakeoff/frey/frey-walk-v1.png

# 서 있지 않은 기술은 캐릭터에 이미 정한 공통 배율을 재사용
& $py tools/sprite_pipeline/normalize.py ... --scale-by fixed:0.23
```

새 디테일 보존 경로는 축소에 `--resample lanczos`(기본값), RGB에 반경 1·임계값 2인 `--sharpen 60`(기본값), 알파 경계 2px 안의 초록 번짐에 `--despill auto`, 색 보존에 `--palette none`(기본값)을 쓴다. `--sharpen 0`은 선명화를 끈다. ART-36 이전 경로도 `--resample box --sharpen 0 --despill off --palette tools/sprite_pipeline/palettes/<id>.json`으로 재현할 수 있다.

긴 무기 때문에 전체 행을 같은 방향으로 옮겨야 할 때만 `--offset-x <px>`를 쓴다. 이 값은 모든 프레임에 동일하게 적용되며 프레임별 이동은 하지 않는다.

공격처럼 모든 프레임이 확실히 지상 동작인데 생성 원본의 셀별 바닥 위치가 조금 흔들렸다면 `--ground-all`로 모든 프레임의 발끝을 y=120에 둔다. 공중 높이를 보존해야 하는 점프·낙하·공중 기술에는 쓰지 않는다.

고립된 생성 잔여 픽셀은 최종 128px 프레임에서 4방향 연결 성분으로 검사해 제거할 수 있다. 다음 예시는 21px 미만의 분리 성분만 버리며, 제거한 성분의 프레임별 면적과 경계상자를 `metrics.json`의 `dropped_components`에 기록하고 콘솔에 총 성분 수/픽셀 수를 출력한다. 몸·무기처럼 이어진 큰 성분이 지워지지 않도록 비교판을 반드시 확인한다.

```powershell
& $py tools/sprite_pipeline/normalize.py ... --min-component 21
```

입력은 `--sheet PNG --grid CxR` 또는 `--frames 폴더/글롭` 중 하나다. `--pick 0,1,2`로 사용할 칸을 고를 수 있다. `--bg`는 `alpha`, `auto`, `#00ff00`을 지원한다. `auto`는 기존 투명을 우선하고, 불투명 입력이면 테두리에서 연결된 주 배경색만 지운다. `--outline auto`는 기존 실루엣 내부에서 어두운 외곽선 사이의 1px 구멍만 잇는다.

배경을 제거한 직후 원본 셀의 피사체가 위·아래·왼쪽·오른쪽 경계 중 하나라도 닿으면 즉시 실패한다. 이는 그림이 옆 셀로 넘어가 잘렸다는 신호이므로 배율로 숨기거나 조각을 지우지 말고, 동작 전체를 더 넓은 여백과 짧은 리치로 다시 생성한다. 오류에는 문제 셀과 닿은 변, 재생성 지침이 표시된다.

출력 폴더에는 다음이 생긴다.

- `<name>.png`: 128×128 셀 6열, 실제 프레임은 왼쪽부터 배치
- `frames/`: 프레임별 PNG
- `closeup.png`: 모든 후보 프레임을 `--compare-scale`(기본 2배)로 확대하고 y=120 선 표시
- `compare.png`: 같은 시트의 대기 프레임 + 현재 행, 대기 프레임 + 후보 행을 `--compare-scale`로 비교
- `metrics.json`: 프레임별 높이·너비·면적·바닥·공중 높이·색 수·내부 디테일·남은 초록 번짐·팔레트 위반·알파·1px 테두리·4px 여백과 전체 범위. `--reference`가 있으면 기준 행의 프레임별 색 수·내부 디테일과 후보/기준 평균 비율도 기록한다.

`height:<px>`는 원본에서 가장 낮은 접촉 프레임들의 몸 높이 중앙값을 목표 높이로 맞춘다. `fixed:<factor>`는 그대로 적용한다. 출력된 `factor=` 값을 같은 캐릭터의 다른 동작에서 재사용할 수 있다.

## 검사

```powershell
& $py -m unittest tools/sprite_pipeline/test_normalize.py -v
```

합성 검사는 연결 배경 제거, 한 공통 배율, 접촉 발 y=120, 공중 높이 보존, 팔레트 전용 색, 이진 알파, 6열 출력, 고정 배율, LANCZOS+선명화, 초록 번짐 제거, 팔레트 미적용 색 보존, 내부 디테일 수치, 원본 셀 경계 접촉 시 재생성 안내와 출력 셀 경계 초과 실패를 확인한다.

## 제한

- 공중 높이는 모든 입력 칸이 같은 원본 좌표계를 공유한다는 전제에서 원본 최저점 차이로 계산한다. 프레임을 각각 타이트하게 자른 입력은 높이 정보를 보존하지 못한다.
- 팔레트 매핑은 흐림·압축·가려짐·잘못 그린 해부를 복구하지 않는다.
- 자동 외곽선은 실루엣을 확장하지 않으며 큰 끊김을 그려 넣지 않는다.
- 4px 여백은 `metrics.json`에 보고한다. 1px 테두리 침범은 항상 실패하지만 4px 미달은 리드가 후보를 다시 생성할지 판단한다.
