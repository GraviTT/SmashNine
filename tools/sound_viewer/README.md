# 사운드 청음실 · AUD-01 전체 효과음 + AUD-02* 음악

효과음 **72종 × A/B/C = 216개**를 외부 WAV로 불러온다. 처음에는 선수 그룹과 A가 보인다. A는 미리보기 기본값이며 채택된 값이 아니다. 상단 A/B/C로 모든 효과음의 재생 스타일을 바꾸고, 그룹·검색으로 범위를 줄인 뒤 **표시한 효과음 이어듣기** 또는 **이 그룹 이어듣기**를 누른다. 개별 카드의 **A → B → C 비교**는 세 스타일을 180ms 간격으로 재생한다. 비교 체크는 세 패널을 나란히 보여 준다.

그룹은 선수 15 / 기술·궁극기 20 / 몬스터 15 / 렐름 11 / 성장·진행 6 / 메뉴·스토리 5다. 카탈로그의 Fallback 네 종은 각각 선수(swing), 기술(skill_cast, ult_start), 몬스터(monster_attack)에 넣었다. 원래 카탈로그 그룹도 매니페스트의 `catalog_group`으로 보존한다. 모든 카드의 한국어 재생 상황은 `design/AUDIO.md`의 계약을 바탕으로 청음용 문장으로 정리했다. 내부 래퍼·serial 같은 구현 표현은 화면 설명에서 뺐다. 채택과 게임 적용은 별도다.

음악은 접힌 **음악 후보** 영역에 있다. 빌더가 `reports/codex-aud-02*/measurements.json`의 음악 레코드를 전부 읽는다. 같은 ID·스타일이 겹치면 전체 AUD-02가 시험 AUD-02a보다 우선한다. 고정 두 곡 검사나 D 도리안 고정 표기는 제거했다. 현재 클론에는 AUD-02a 두 곡·6 WAV만 있으며, AUD-02 병합 후 다시 빌드하면 새 곡이 추가된다. 곡별 반복은 기본 켜짐이며 재생 중 변경할 수 있다. 음악과 효과음은 동시에 하나만 재생한다.

## 빌드·검사

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$audioPython = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $audioPython tools/audio_synth/sfx_all.py
& $audioPython tools/audio_synth/verify_sfx_all.py
node tools/sound_viewer/build.mjs
node tools/sound_viewer/verify.mjs
```

기본 출력은 `tools/sound_viewer/dist/`이며 git에 포함하지 않는다. **AUD-01 유닛은 카드의 dist 쓰기 금지를 지켜 아래 별도 출력만 만들고 검증했다.** 기본 dist는 리드가 다시 빌드한다.

```powershell
node tools/sound_viewer/build.mjs --out reports/codex-aud-01/preview
node tools/sound_viewer/verify.mjs --out reports/codex-aud-01/preview
node tools/serve_web.js reports/codex-aud-01/preview 8077
```

이 preview도 재생성 가능한 로컬 산출물이며 commit.ps1은 stage하지 않는다. `index.html`을 반드시 `audio/`와 함께 열어야 한다. 효과음·음악 모두 data URL이 없고 재생할 때만 해당 WAV를 요청한다. HTML만 게시하면 소리가 나지 않는다. `files.json`은 모든 외부 WAV를 한 번씩 나열한다. `publish-plan.json`은 파일 수·바이트 수와 **이번 빌드에서 사용할 목록 이름**을 알려 준다. 과거 빌드의 번호 목록이 남아 있어도 계획에 없는 파일은 사용하지 않는다.

현재 출력: HTML 약 252KB, WAV 222개 / 41,216,454바이트. HTML 포함 223파일 / 약 41.5MB이므로 한 번에 게시 가능하다. 향후 음악이 늘면 자동으로 분할한다.

## Artifact에 다시 게시 · 리드 담당

기존 주소: https://claude.ai/artifact/BWneucCv1GHme5JX7fmUuW

1. AUD-02 파일을 병합한 뒤 빌드·검사한다. `publish-plan.json`을 읽는다.
2. 한 묶음이면 같은 Artifact에 `dist/index.html`, `root=tools/sound_viewer/dist`, `files=dist/files.json`을 지정한다. `{ "path": "audio/<id>-<style>.wav" }`의 상대 경로를 유지한다.
3. 파일 수 또는 용량이 크면 `files-1.json`, `files-2.json`, …도 생성된다. 각 목록은 **HTML 한 개를 포함해 최대 250파일·60,000,000바이트** 이내다(Artifact의 255파일·64MB 한도보다 작다). 이때 전체 `files.json`을 한 요청에 보내지 말고 `publish-plan.json`의 순서로 번호 목록을 사용해 첨부를 누적한다. 마지막까지 끝나기 전에는 일부 소리가 누락될 수 있다.
4. 게시 도구가 여러 요청의 첨부를 누적하는지 먼저 확인한다. 첨부를 교체하는 API라면 단순 연속 재게시만으로 전체 파일을 유지할 수 없다. 그런 환경에서 번호 목록 하나만 남긴 채 완료로 보고하지 않는다. 이 유닛은 호스팅·누적 첨부 동작을 검증하지 않았다. 현재 한 묶음에는 해당하지 않는 제한이다.
5. **`capabilities`를 생략**해 기존 `db`와 `sound_picks`를 유지한다. 컬렉션을 비우지 않는다.
6. 게시 후 그룹마다 효과음과 음악을 재생하고, 음량·정지·루프·작은 화면·새로고침 후 선택 복원을 확인한다. 실제 저장은 사용자가 채택할 때 수행한다.

## 채택 저장 계약

`window.claude.use("db")` / `sound_picks` 전체 스냅샷 구독을 유지한다. DB가 없거나 연결에 실패하면 저장 UI만 숨기고 청음은 유지한다.

| 대상 | 문서 | 저장 필드 |
|---|---|---|
| 전체 효과음 스타일 | `sound_picks/style` | **`style`, `note` 두 필드** |
| 개별 효과음 | `sound_picks/<id>` | 기존 `sound`, `style`, `note`, `adopted_at` |
| 모든 음악 | `sound_picks/music_<track>` | 기존 `sound`, `style`, `note`, `adopted_at` |

전체 스타일 예시(실제 채택 아님):

```json
{"style":"b","note":"전체 스타일 선택 예시"}
```

상단의 스타일 버튼은 미리보기만 바꾼다. **현재 스타일 채택**을 눌러야 위 문서 하나를 쓴다. 개별 효과음 72개 문서를 일괄 갱신하지 않는다. 기존 시험 12종의 문서 ID·네 필드는 그대로다. 전체 스타일 채택은 음악의 스타일을 바꾸지 않는다. 기존 개별 선택은 지우거나 덮어쓰지 않는다. 리드는 전체 스타일을 기본값으로 읽고 개별 채택을 따로 판단할 수 있다.

스냅샷에서 전체 스타일·메모를 복원하며 편집 중인 미저장 스타일·메모는 유지한다. 저장 실패는 한국어 메시지와 재시도를 제공한다. 게임 적용 코드는 만들지 않았다.

## 검증 범위

`verify.mjs`는 Node 모의 DOM·Audio·DB로 검사한다. 결과는 **`reports/codex-aud-01/viewer-checks.json`**에 쓴다. 전체 외부 WAV와 원본 바이트 비교, A/B/C 완결성, 순서 재생·정지·음량·오류, 음악 반복, 기존 개별 채택, 전체 스타일의 정확한 두 필드 저장·복원·실패, 검색·그룹, 선택 스타일 전체 이어듣기를 확인한다. 실제 파일 목록 외에 251파일·60MB 초과 데이터를 만들어 분할 경계와 누락·중복도 검사한다. 별도 fixture로 AUD-02* 추가 곡 자동 발견과 전체 보고서 우선을 검사한다.

실제 브라우저 검증은 **로컬 origin 승인 거부**로 실행하지 못했다. 실제 Audio 디코딩·스피커 청음·모바일 렌더링·Artifact DB·게시 검증 결과가 아니다.
