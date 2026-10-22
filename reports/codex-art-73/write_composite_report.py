"""Generate the Korean final handoff from saved composite measurements."""
from pathlib import Path
from datetime import datetime, timezone, timedelta
import json

REPORT = Path(__file__).resolve().parent


def run():
    rows = json.loads((REPORT/'composite-measurements.json').read_text(encoding='utf-8'))
    check = json.loads((REPORT/'verification.json').read_text(encoding='utf-8'))
    assert check['artifact_checks_pass']
    text = '''# ART-73 완료 — 중립 원본에 표정 24장 합성

리드는 기존 24장의 인물·구도·표정 가독성을 통과시켰다. 이번에는 리드의 명시적 Python/Pillow 지시에 따라 생성한 표정만 중립 원본에 합성했다. 24장 모두 `review_status: "candidate"`, `delivered: true`로 교체했다. **후보 납품이며 게임 채택·연결은 하지 않았다.** 이전 보고서의 일괄 rejected/납품 보류 판정은 이 보고서로 대체한다.

마스크 밖 RGBA 변경 **24/24 = 0px**, 전체 알파 완전 일치 **24/24**, 256×256 RGBA **24/24**다. 중립 원본 8장과 제품 경로는 바꾸지 않았다. 유키 hurt만 내장 이미지 도구로 1회 더 편집하여 2차를 선택했다. 이번 실행에서 설치·다운로드·Godot·스테이징·커밋은 하지 않았다.

## 방법

1. 생성 원본을 Pillow LANCZOS로 256×256 RGBA로 정규화했다. 초기 선택은 그대로 유지하고 유키 hurt만 2차로 바꿨다. 합성 전 후보와 이전 보고·측정은 git-ignored `art/raw/faces-73/pre-composite/`에 보관했다.
2. 폼별 중립 얼굴에서 **턱/뺨 윤곽과 앞머리 경계**를 지정했다. 눈·눈썹·입과 주변은 점수 영역에서 제외했다. dx,dy 각각 −4…+4의 81개 정수 이동을 전부 비교하여 `0.5 × RGB 평균 절대 차이 + x/y 색 기울기 평균 절대 차이`가 가장 작은 이동을 선택했다. offset은 생성 이미지를 중립 좌표로 옮기는 값이며 +x는 오른쪽, +y는 아래다. 회전·변형은 하지 않았다. 영역 그림은 `<stem>-alignment.png`, 전체 점수는 `alignment-scores.json`이다.
3. 폼마다 다른 눈·눈썹·입 위치를 `composite-config.json`에 지정했다. 입은 중립과 세 표정의 입술을 덮는 영역에 4px 여백을 주었다. 처음 합성에서 아랫입술이 페더에 걸린 사례를 보고 이 범위를 보정했다. 눈/눈썹은 경계를 따라 여백을 둔 다각형, 루나 두 폼은 볼 홍조 영역, 유키 hurt는 땀방울 영역을 포함했다. 유키의 땀방울 마스크만 표정별 추가 영역이다.
4. 마스크 안쪽 4px를 smoothstep으로 페더 처리했다. 유한 범위여서 바깥으로 흐릿한 꼬리가 생기지 않는다. 생성 표정 RGB를 중립 위에 붙이고 알파는 전부 중립 알파로 유지했다. 표정을 코드로 그리거나 전체 색을 보정하지 않았다. 실제 마스크는 `<stem>-<expression>-mask.png`다. JSON의 `mask_bbox`는 mask>0의 `[x0,y0,x1,y1]` 범위이며 오른쪽·아래 경계는 제외한다. 보존 검사는 bbox가 아닌 **실제 마스크 값이 0인 모든 픽셀**에 적용했다.
5. 저장된 PNG를 별도 검증기로 다시 읽어 RGBA 보존, JSON, 합성 재현, 경계 수치를 확인했다. 최종 8개 보드와 24개 경계 확대를 직접 확인했다. 확대본에서 분명한 붙인 테두리·이중 선·급격한 색 단차는 보이지 않았다. 이는 육안 판단이며 수치와 구분한다.

## 이미지별 측정

**경계 MAE**는 `0 < mask < 255`인 페더 띠에서 **정렬된 생성 편집본과 중립 원본** 사이 RGB 채널 절대 차이의 평균이다(0…255, 낮을수록 가까움). 최종 합성본과 중립의 차이가 아니며 값만으로 시각적 합격을 자동 판정하지 않는다. 후자의 평균과 경계 픽셀 수·95백분위는 `composite-measurements.json` 및 각 후보 JSON에 따로 기록했다. “재편집”은 이번 fix-1에서 이미지 도구를 다시 쓴 여부다.

| 폼 | 표정 | offset (dx,dy) px | 마스크 밖 변경 px | 경계 MAE | 재편집 |
|---|---|---:|---:|---:|---|
'''
    for r in rows:
        redo = '예 · 2차 선택' if r['redone_this_pass'] else '아니요'
        text += f'| {r["label"]} | [{r["expression"]}](../../{r["path"]}) | ({r["offset"][0]}, {r["offset"][1]}) | {r["outside_mask_changed_pixels"]} | {r["seam_edit_neutral_rgb_mae"]:.2f} | {redo} |\n'
    text += '''
## 시각적 확인

각 보드는 `neutral / happy / angry / hurt` 순서로 ① 256×256 원본 크기 ② 142×164 대화 상자 모사 ③ 얼굴 4배 확대를 놓았다. 142×164에는 정사각 그림을 142×142로 선형 축소하고 위아래 11px을 비워 비율을 유지했다. **실제 Godot 화면은 아니다.** 3행의 청록색 선은 마스크 50% 지점을 출력 기준 1px 두께로 표시한다. 최종 후보 PNG에는 선이 없다.

| 폼 | 크기별 보드 | 선 없는 경계 비교(중립/정렬 편집/합성/마스크) |
|---|---|---|
'''
    seen = set()
    for r in rows:
        if r['form'] in seen:
            continue
        seen.add(r['form']); stem = r['form']
        text += f'| {r["label"]} | [세 크기]({stem}-faces.png) | [세 표정 4배 비교]({stem}-seams.png) |\n'
    text += '''
각 `<stem>-<expression>-difference.png`도 새 합성 결과로 갱신했다(중립/후보/50% 겹침/RGB 차이 ×4). 마스크 밖 차이 그림은 완전히 검정이다. `<stem>-<expression>-seam.png`에는 표정별 경계 비교가 있다. 개별 육안 판단은 `visual-review.json`에 기록했다.

## 다시 한 작업과 남은 약점

- **유키 hurt:** 중립 원본에서 1회 더 직접 편집했다. 안쪽 눈썹을 모으고 눈을 더 감고 이를 악문 입과 땀방울을 넣었다. [이전 1차/새 2차 비교](yuki-hurt-comparison.png)를 같은 합성 방식·142×164 및 얼굴 4배에서 보고 2차를 선택했다. 1차도 raw에 남아 있다. 프롬프트는 `yuki-hurt-redo-prompt.txt`, 이력은 `generation-log.json`이다. **눈썹은 앞머리에 많이 가려지고 작은 표시에서는 땀방울이 작아 통증 강도는 여전히 절제되어 있다.**
- **리오 남 hurt:** 이를 악문 입은 보이지만 작은 표시에서는 고통보다 피로·찡그림으로도 읽힌다. 얼굴 위치나 합성 경계 문제는 관찰하지 않아 추가 이미지 생성은 하지 않았다.
- **노바 여 happy:** (0,+4) 정렬이 검색 범위 끝에서 최저 점수였다. 정렬 후 눈·턱·앞머리가 맞고 코를 남긴 합성에서도 이중 선이나 단차는 보이지 않았다. 다른 23장도 추가 얼굴 위치 재편집이 필요한 사례는 관찰하지 않았다.
- 나머지는 142×164 모사에서 happy/angry/hurt 차이를 읽을 수 있었다. 이번 추가 이미지 생성은 유키 hurt 1회뿐이다. 전체 이미지 도구 호출은 최초 26회 + 이번 1회 = **27회**다. 프레이 happy 최초 3회는 이전 작업이다.

## 확인 및 테스트

| 검사 | 결과 |
|---|---:|
| 중립 원본과 초기 복사본/해시 일치 | 8/8 |
| 256×256 RGBA | 24/24 |
| 마스크 밖 RGBA 변경 0px | 24/24 |
| 원본 알파 완전 일치 | 24/24 |
| JSON 상태·출처·offset·bbox 일치 | 24/24 |
| 저장 후보를 입력+마스크로 재현 | 24/24 |
| 경계 수치 별도 재계산 일치 | 24/24 |

`verify_candidates.py` exit 0. 결과는 `verification.json`이다. `git diff --name-only -- smash-nine-prototype` 출력은 비어 있었고 새 파일 상태도 별도 확인했다. Godot 실행·게임 대사별 연결 검사는 수행하지 않았다. 처음 검증기 작성 시 PowerShell 파이프 문자 변환으로 한글 범위 리터럴이 `?`로 바뀐 검사 오류를 수정한 뒤 재실행했다. 후보 이미지 오류는 아니었다.

```powershell
$env:PYTHONDONTWRITEBYTECODE='1'
& 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' reports/codex-art-73/composite_faces.py
& 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' reports/codex-art-73/verify_candidates.py
```

`check_faces.py`는 현재 측정의 읽기 전용 요약이다. `save_review_candidates.py`는 최초 미합성 시안 저장용으로 기존 파일이 있으면 중단되므로 다시 사용하지 않는다. `check_raw.py`, `compare_frey_tries.py`, `raw-measurements.json`, `frey-happy-attempts.json`은 최초 생성본의 차이 기록이며 최종 합성 품질 판정이 아니다.

## 커밋 인계와 다음 단계

`commit.ps1`을 새로 작성하고 PowerShell 구문과 명시적 파일 목록만 검증했다. **실행하지 않았다.** `commit-files.txt`의 ART-73 후보와 보고서만 포함하며 이번 요청 원문 `fix-1.prompt.md`도 포함한다. `git add -f`, `art/raw/`, `__pycache__`, 기존 실행 로그, 다른 카드 보고서는 포함하지 않는다. `git commit --only`로 다른 스테이징 파일을 제외한다. 검증 결과는 `commit-validation.json`이다.

**남은 작업:** 후보 납품은 완료. 게임 연결·대사별 표정 지정은 이 카드 밖의 리드 작업이다. **다음 권장 단계:** 리드가 새 보드와 유키/리오 hurt 강도를 확인한 뒤 채택 여부를 결정한다. 자동 후속 실행은 예약하지 않았다.

'''
    text += '이번 fix-1 첫 시각 확인: 2026-10-23 02:28:55 KST. 보고서 작성: ' + datetime.now(timezone(timedelta(hours=9))).strftime('%Y-%m-%d %H:%M:%S KST') + '. 90분 한도 내 종료.\n'
    (REPORT/'README.md').write_text(text, encoding='utf-8')
    print('Korean README updated.')


if __name__ == '__main__':
    run()
