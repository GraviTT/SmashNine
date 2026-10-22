# 사운드 청음실 · AUD-01a 효과음 + AUD-02a 음악

**음악**에는 타이틀·전투 두 카드가 있고 각각 A 칩튠 / B 16비트 / C 레이어드를 비교한다. 후보별 재생·정지, 곡별 반복 체크(기본 켜짐), 전역 음량을 제공한다. 반복은 재생 중에도 바꿀 수 있으며 끄면 현재 한 바퀴 뒤 끝난다. 음악·효과음은 동시에 하나만 재생한다.

**효과음**은 기존 12개 동작·36개 후보를 유지한다. 개별 재생, 카드의 **전체 재생**(A→B→C, 사이 180ms), 정지, 음량, 스타일 선택과 채택 메모는 그대로다. 모바일 CSS에서는 A/B/C가 세로로 쌓인다.

음색 설명은 합성 설계에 따른 의도다. 수치·모의 동작 검사가 직접 청음 평가를 뜻하지 않는다.

## 빌드하고 열기

저장소 루트에서 음악 WAV와 측정값이 없다면 먼저 [합성 도구](../audio_synth/README.md)의 음악 명령을 실행한다. 기존 효과음 WAV와 AUD-01a 측정값도 필요하다.

```powershell
node tools/sound_viewer/build.mjs
node tools/sound_viewer/verify.mjs
```

결과는 `dist/index.html`, `dist/audio/`의 WAV **42개**(기존 효과음 36 + 음악 6), `dist/files.json`이다. dist는 git 제외이므로 각 클론에서 다시 빌드한다. 빌더는 고정 36개 검사를 없애고 매니페스트별 A/B/C 완결성과 음악 두 id를 검사한다.

- 효과음: 이전처럼 **HTML에 data URL로 내장**한다. 검수용 동일 WAV도 audio 폴더에 복사한다.
- 음악: **내장하지 않고** `audio/music_title-a.wav` 같은 상대 경로를 참조한다. `files.json`에 여섯 음악 파일을 모두 기록한다. **HTML만 보내면 음악은 재생되지 않는다.**
- 로컬에서는 `dist/index.html`을 audio 폴더와 함께 열거나 다음 서버로 확인한다.

```powershell
node tools/serve_web.js tools/sound_viewer/dist 8076
```

`http://127.0.0.1:8076`을 연다. 음악 경로에 접근할 수 없으면 페이지가 오류를 알린다. 이 유닛의 연결된 앱·브라우저 목록은 비어 있어 실제 화면·디코딩·스피커 재생은 검증하지 못했다.

## Artifact 재게시 · 리드 담당

기존 사운드 Artifact: https://claude.ai/artifact/BWneucCv1GHme5JX7fmUuW

1. 빌드한 **`dist/index.html`**을 같은 사운드 Artifact에 재게시한다. 모션 뷰어와 구분한다.
2. 게시 요청에 **`root=tools/sound_viewer/dist`, `files=dist/files.json`**을 함께 지정하여 모든 sidecar를 게시한다. 목록은 `{ "path": "audio/music_title-a.wav" }` 형식 배열이며 효과음 검수 복사본도 포함한다. 파일 상대 경로를 그대로 유지한다.
3. **`capabilities`를 생략해 기존 `db`와 `sound_picks` 기록을 유지**한다. 기존 컬렉션을 비우지 않는다.
4. 게시 후 여섯 음악의 재생·반복 경계, 정지·음량·모바일 배치, 음악 채택 후 새로고침 복원과 기존 효과음 선택 유지 여부를 확인한다. 이 유닛은 게시하거나 실제 채택 기록을 쓰지 않았다.

## 채택 저장

기존 `window.claude.use("db")` / `onSnapshot` API를 그대로 사용한다. DB가 없거나 연결에 실패하면 채택 버튼·메모를 숨기고 청음·스타일 선택은 유지한다.

| 대상 | 컬렉션 | 문서 id | 선택 파일 |
|---|---|---|---|
| 효과음 | `sound_picks` | `hit_light`, `portal` 등 기존 id | `art/audio_bakeoff/<id>-<style>.wav` |
| 타이틀 | `sound_picks` | **`music_title`** | `art/audio_bakeoff/music_title-<style>.wav` |
| 전투 | `sound_picks` | **`music_battle`** | `art/audio_bakeoff/music_battle-<style>.wav` |

필드는 기존과 같은 `sound`, `style` (`a`/`b`/`c`), `note`, `adopted_at` (ISO UTC)다. 예:

```json
{
  "sound": "music_title",
  "style": "b",
  "note": "형식 예시이며 실제 채택 기록이 아님",
  "adopted_at": "2026-10-23T00:00:00.000Z"
}
```

리드는 해당 Artifact의 ArtifactData에서 collection `sound_picks`를 읽는다. 문서마다 한 스타일이며 다시 채택하면 해당 문서만 덮어쓴다. 미선택을 A로 간주하지 않는다. 저장 성공·실패·재시도와 작성 중 메모 보존을 유지한다.

## 검증 범위

`verify.mjs`는 Node 표준 라이브러리의 모의 DOM·Audio·DB로 기존 효과음 순서·정지·음량·채택을 검사하고, 음악 외부 경로·반복 켜기/끄기·카드 간 격리·정지·효과음과의 상호 중단·음악 id별 채택과 복원을 검사한다. 모든 내장 효과음·복사 WAV·원본의 바이트를 비교하고, 음악에 data URL이 없으며 여섯 sidecar가 원본과 같고 파일 목록에 있는지 확인한다.

실행 결과는 **`reports/codex-aud-02a/viewer-checks.json`**에 쓴다. 과거 AUD-01a 보고서는 덮어쓰지 않는다. 실제 브라우저 렌더링·Audio 디코딩·호스팅 Artifact API 검사는 아니다. 음악 파일 자체의 재현성과 루프 경계는 `tools/audio_synth/verify_music.py`가 별도로 검사한다.
