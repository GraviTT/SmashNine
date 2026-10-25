# SART-02 처리 기록과 재현

## 실행한 작업

- image_gen 반환 경로에서 `art/raw/story/<id>_raw.png`로 26개 원본을 복사했다. 모든 SHA-256이 원본과 같음을 확인했다.
- 25개는 1672×941, 7번 v5만 1671×941이며 모두 RGB 불투명 PNG다.
- 원본 읽기 전용 밝기·채도·대비 분석을 했다. 수정·리샘플링·색 보정은 실행하지 않았다.
- `build_deliverables.py`는 Python AST 구문 검사만 통과했다. Pillow 제작 실행은 못 했다.
- 설치/다운로드, Godot 실행, 제품 파일 수정, 원본 덮어쓰기 없음.

## 아직 실행하지 않은 크롭·축소 계획

| 대상 | 원본 | 크롭 상자 (left, top, right, bottom; 끝 제외) | 크롭 크기 | 출력 | 축소율 |
|---|---|---|---|---|---|
| 7번 v5·9번 v3 제외 24개 | 1672×941 | [4,2,1668,938] | 1664×936 | 640×360 | 0.3846153846 |
| 7번 v5 | 1671×941 | [3,2,1667,938] | 1664×936 | 640×360 | 0.3846153846 |
| 9번 v3 | 1672×941 | [20,7,1668,934] | 1648×927 | 640×360 | 0.3883495146 |

모두 정확한 16:9이며 업스케일하지 않는다. 리샘플링은 Pillow Image.Resampling.LANCZOS 계획이다. 원본이 이미 불투명이므로 RGB로 저장하며 색보정·알파 제거·키잉·수동 페인트를 추가하지 않는다.

9번 v3의 생성 편집으로는 원본 좌상단 x≈11, y≈34의 Γ 유사 표시가 없어지지 않았다. x=20부터 크롭해 그 가장자리를 제외하는 계획이다. **아직 실행 전이므로 제거 성공으로 보고하지 않는다.** final 후보를 직접 열어 재확인해야 한다.

## Pillow 실행 장애

사용자 경로 Python:
`C:/Users/TH/AppData/Local/Programs/Python/Python312/python.exe`

기존 Pillow:
`C:/Users/TH/AppData/Local/Temp/gvt/venv/Lib/site-packages/PIL`

Python 3.12 프로세스 시작이 접근 거부되었다. venv 런처도 같은 인터프리터를 사용해 실행되지 않았다. 실행 가능한 Blender Python 3.13은 Pillow가 없고 기존 CPython 3.12용 확장 모듈과 호환되지 않는다. 차단된 실행파일을 다른 경로/도구로 우회 실행하지 않았다.

설치·다운로드 없이 기존 Sharp/libvips를 쓰는 대체 방안은 사용자 답변 대기 중이며 실행하지 않았다. `build_sharp.cjs`는 `processing-authorization.json`에 명시적 승인 기록이 없으면 실행되지 않는다. 사용자가 승인했을 때만 실제 답변을 기록하고 사용할 수 있다. 승인되지 않은 파일을 임의로 생성하지 않는다.

## 허용되는 Pillow 환경에서의 재현

현재 샌드박스 밖에서 리드/사용자가 기존 Pillow 환경으로 실행할 명령이다. 이 단위는 실행하지 않았다.

```powershell
& 'C:/Users/TH/AppData/Local/Temp/gvt/venv/Scripts/python.exe' reports/codex-sart-02/build_deliverables.py
```

스크립트는 기본 manifests와 수정 manifests를 읽어 전체 26개를 처리한다. 원본과 후보는 배타적 생성 모드로 쓰므로 덮어쓰지 않는다. 기존 후보 JSON이 있으면 SHA-256 일치를 확인하고 건너뛴다. 부분 생성 파일이 있으면 중단한다.

실행 뒤 생성될 파일:
- `art/bakeoff/story/stage_card_XX-vN.png`, 같은 이름 `.json`
- `reports/codex-sart-02/measurements.json`: 최종본 측정
- `reports/codex-sart-02/stage-01-comparison.jpg` … `stage-09-comparison.jpg`
- `reports/codex-sart-02/set-board.jpg`

각 단계 비교판에는 모든 해당 버전을 640×360과 480×270으로 넣는다. JPEG Q90, 4:4:4, 각 2,000,000 bytes 이하를 검사한다. 3×3 세트는 [2,1,8,3,9,7,4,5,6] 순서이며 Pillow ImageDraw + `C:/Windows/Fonts/malgun.ttf`로 다음 제목을 직접 그린다.

| ② 발키리의 문 | ① 부서진 하늘 | ⑧ 얼어붙은 뿌리 |
|---|---|---|
| ③ 달빛 다리 | ⑨ 세계수의 심장 | ⑦ 불의 짐승 |
| ④ 태엽 도시 | ⑤ 무너지는 숲 | ⑥ 중력의 우물 |

실행 뒤 모든 최종 그림과 비교판을 눈으로 검사하고, 현재 README/PASS_FAIL/inspection의 미완료 상태를 실제 결과로 갱신해야 한다. 파일 생성만으로 육안 검수를 통과한 것은 아니다.

실제 PNG 헤더를 읽어 7번 v5의 가로가 다른 원본보다 1px 작음을 발견하고 중앙 크롭 좌표를 보정했다. [전수 크롭 계획](processing-plan.json)에 각 원본의 실제 치수와 계획 좌표를 기록했다.
