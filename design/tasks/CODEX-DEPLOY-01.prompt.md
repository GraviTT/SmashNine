# Codex 웹 배포 요청 (Sites)

CuRun과 같은 방식: Codex가 빌드해서 Sites(`*.chatgpt.site`)에 올리고, 사이트 정보를 `.openai/hosting.json`과 `reports/codex-deploy/site.json`에 남긴다.

- 사이트는 2026-10-07에 등록됨: `appgprj_6ac65f43555481918a37077e8c63c66c`, `https://smash-nine-prototype.tt9.chatgpt.site`, 소유자 전용. 첫 업로드는 `artifacts_git_receive_pack_object_too_large`로 거부돼 아직 게시된 버전이 없다.
- 거부 원인: 파일 하나가 너무 컸다(`index.wasm` 37.7 MiB, `index.pck` 25.4 MiB). Sites에 받아들여진 가장 큰 파일로 아는 것은 CuRun의 6.4 MB.
- 수정(리드, 2026-10-08): `tools/build_web.ps1`이 5 MiB가 넘는 파일을 `<이름>.part0`, `.part1` … 로 나누고, `index.html`에 넣은 로더(`tools/web_part_loader.js`)가 브라우저에서 이어 붙인다. 아트 생성 원본 PNG가 pck에 들어가던 것도 빼서 `index.pck`는 4.3 MiB가 됐다. 지금 빌드의 가장 큰 파일은 5 MiB.
- 실패한 업로드가 남긴 로컬 소스 저장소 `build/sites-source`(거부된 큰 파일 이력이 든 커밋)는 지웠다.

## 다음 배포 (지금 쓸 문구)

```text
C:\Users\TH\Documents\AI\GameProject\SmashNine 에서 `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 빌드해서(결과 build/web/), reports/codex-deploy/site.json의 기존 사이트에 새 버전으로 배포만 해줘.

- 빌드 출력 끝의 "Largest file"이 5 MiB 이하인지 본다. build/web/ 에는 index.wasm 대신 index.wasm.part0~7 이 있고 index.html의 로더가 이어 붙이니, 파일을 합치거나 빼지 말고 build/web/ 그대로 올린다.
- 지난번 업로드는 큰 파일 때문에 거부됐다. 새 Sites 소스 커밋에 그 큰 파일(옛 index.wasm, index.pck) 이력이 섞이지 않게 새로 시작한다(지난번 로컬 소스 저장소 build/sites-source 는 리드가 지웠다).
- 확인: 실제 브라우저로 사이트를 열어 시작 화면(로고, 왼쪽 얼굴 초상화 5개, "[5] Rio", "[V] Body" 줄), 5 키로 경기 시작, 콘솔 오류 없음, 네트워크에서 index.wasm.part0~7 과 index.pck 가 200 인지 본다. 소유자 로그인이 필요하면 적는다.
- site.json(버전·배포 ID, game_source_commit_sha, deployed_at_utc, verified_at_utc, verified_routes, status)과 reports/codex-deploy/README.md만 갱신하고, 커밋·push와 다른 파일 수정은 하지 말 것.
- 또 거부되면 서버 오류 문구 그대로, 어떤 파일 크기에서 거부됐는지 알 수 있는 만큼 보고하고 멈춘다(조각 크기를 줄여 다시 빌드하는 것은 리드가 정한다: `tools/build_web.ps1 -PartMB 2`).
```

## 그다음부터 (한 줄)

```text
C:\Users\TH\Documents\AI\GameProject\SmashNine 에서 `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 빌드해서(결과 build/web/, 큰 파일은 .partN 조각 그대로), reports/codex-deploy/site.json의 기존 사이트에 새 버전으로 배포만 해줘. site.json과 reports/codex-deploy/README.md만 갱신하고, 커밋·push와 다른 파일 수정은 하지 말 것.
```
