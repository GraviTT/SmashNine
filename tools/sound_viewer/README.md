# 사운드 청음실 · AUD-01a

12개 동작마다 A 칩튠 / B 16비트 / C 레이어드 아케이드를 나란히 비교한다. 개별 재생, 각 카드의 **전체 재생**(A→B→C, 사이 180ms), 정지, 재생 음량 조절, 스타일 선택과 채택 메모를 제공한다. 모바일 폭에서는 세 후보가 세로로 쌓인다.

게시 주소(사용자 전용, `db` 기능, 채택 기록 컬렉션 `sound_picks`): https://claude.ai/artifact/BWneucCv1GHme5JX7fmUuW — 다시 게시할 때는 같은 주소로, `capabilities`를 생략해 `db`를 유지한다.

## 다시 빌드하고 열기

저장소 루트에서:

```powershell
node tools/sound_viewer/build.mjs
node tools/sound_viewer/verify.mjs
```

결과는 `tools/sound_viewer/dist/index.html`과 `dist/audio/`의 WAV 36개, `dist/files.json`이다. dist는 git에서 제외한다. WAV와 분석 수치는 먼저 `tools/audio_synth/synth.py`로 만든다.

**`dist/index.html`을 브라우저로 직접 열면 청음할 수 있다.** HTML 안에 WAV 36개를 data URL로 넣어 외부 경로·네트워크가 없어도 재생된다. 동일한 WAV를 `dist/audio/`에도 남겨 다운로드·개별 검수에 쓸 수 있게 했다. `index.html` 소스 자체에는 매니페스트가 없으므로 빌드 결과를 연다.

로컬 서버를 선호하면 기존 도구를 사용할 수 있다:

```powershell
node tools/serve_web.js tools/sound_viewer/dist 8076
```

이후 `http://127.0.0.1:8076`을 연다. 이 유닛 환경에는 연결된 브라우저가 없어서 실제 화면·스피커 재생은 확인하지 못했다.

## Artifact 게시 · 리드 담당

1. 최초에는 **새 사운드 Artifact**에 `dist/index.html`을 게시한다. 기존 모션 뷰어를 덮어쓰지 않는다. 처음 게시할 때 Artifact의 `db` 기능을 사용 가능하게 한다.
2. HTML에 음원이 내장되어 있으므로 청음은 HTML 하나로 가능하다. 파일 첨부가 필요한 게시 경로에서는 `root=tools/sound_viewer/dist`, `files=dist/files.json` 목록을 사용한다.
3. 재게시할 때는 같은 사운드 Artifact 주소를 유지하고, 모션 뷰어처럼 **`capabilities`를 생략해 기존 `db`와 채택 기록을 유지**한다.
4. 게시 후 휴대폰 폭·실제 재생·채택 후 새로고침으로 기록 복원을 확인한다. 이 유닛은 게시하지 않았다.

## 채택 저장과 읽기

`tools/motion_viewer/index.html`과 같은 `window.claude.use("db")` / `onSnapshot` 패턴을 사용한다. DB가 없거나 연결에 실패하면 채택 버튼과 메모 입력은 숨기고 청음·스타일 선택은 유지한다.

- 컬렉션: **`sound_picks`**
- 문서 id: 효과 id 하나 (`hit_light`, `portal` 등). 효과마다 하나만 있고 다시 채택하면 덮어쓴다.
- 필드: `sound`, `style` (`a`/`b`/`c`), `note`, `adopted_at` (ISO UTC 문자열).

```json
{
  "sound": "hit_heavy",
  "style": "c",
  "note": "강타는 이 저음이 좋아요",
  "adopted_at": "2026-10-23T00:00:00.000Z"
}
```

위 JSON은 형식 설명용 예시이며 실제 사용자 선택은 아직 없다.

리드는 해당 사운드 Artifact의 `ArtifactData` list에서 collection `sound_picks`를 읽는다. 선택된 파일은 `art/audio_bakeoff/<sound>-<style>.wav`다. 기록 없는 효과는 미선택이며 A를 기본 채택한 것으로 간주하면 안 된다. 사용자 채택 후 게임 연결은 후속 카드에서 진행한다.

페이지는 저장 성공/실패를 표시하고, 저장 실패 시 재시도할 수 있다. 다른 효과의 DB 갱신이 작성 중인 메모를 지우지 않는다. 실제 호스팅 DB 연결은 이 유닛에서 시험하지 못했으며 모의 DB로 저장 필드·복원·실패 처리를 확인했다.

## 확인 도구

`verify.mjs`는 Node 표준 라이브러리만 사용한다. 간단한 DOM·Audio·DB 모형으로 12개 카드/36개 후보, A→B→C 순서, 중첩 방지, 정지, 음량, 파일 바이트 일치, 채택 필드, 스냅샷 복원, 저장 오류와 DB 없는 환경을 점검한다. 결과는 `reports/codex-aud-01a/viewer-checks.json`이다. **브라우저 렌더링·실제 오디오 디코딩·실제 Artifact API 검사가 아니다.**
