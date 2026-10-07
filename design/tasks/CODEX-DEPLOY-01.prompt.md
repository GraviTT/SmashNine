# Codex 웹 배포 요청 (Sites)

CuRun과 같은 방식: Codex가 빌드해서 Sites(`*.chatgpt.site`)에 올리고, 사이트 정보를 `.openai/hosting.json`과 `reports/codex-deploy/site.json`에 남긴다. 다음부터는 같은 사이트에 새 버전만 올린다.

## A. 첫 배포 (사이트가 아직 없을 때)

```text
C:\Users\TH\Documents\AI\GameProject\SmashNine 의 Godot 웹 빌드를 Sites에 새 사이트로 배포해 줘. (SmashNine은 가제)

1. 확인: `git fetch origin` 후 `git status`가 깨끗하고 main이 origin/main과 같은지 본다. 다르면 배포하지 말고 보고.
2. 빌드: 저장소 루트에서 `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`
   - Godot 웹 export(Compatibility 렌더러, 스레드 없는 템플릿)를 build/web/ 에 만든다(index.html, index.js, index.wasm, index.pck 등, 모두 상대 경로). 마지막 줄 "Web build: ..." 와 zip 크기.
   - Godot 콘솔: C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe, 웹 템플릿은 %APPDATA%\Godot\export_templates\4.7.stable 에 설치돼 있다. 샌드박스의 "Failed to read the root certificate store" ERROR 한 줄은 알려진 잡음.
3. 배포: build/web/ 폴더 전체를 정적 사이트로 Sites에 새 사이트로 올린다. 접근은 CuRun처럼 소유자 전용(기본값)으로 두고 넓히지 않는다.
   - 스레드 없는 빌드라 COOP/COEP 헤더는 필요 없다. index.wasm(수십 MB)과 index.pck가 그대로 올라가야 한다. 파일 크기 제한 등으로 거부되면 무엇이 거부됐는지 보고하고 멈춘다.
4. 기록: 사이트 ID를 `.openai/hosting.json`에, 배포 정보를 `reports/codex-deploy/site.json`에 남긴다(project_id, url, access, version_number, version_id, deployment_id, game_source_commit_sha = 배포한 main 커밋, build_command = "powershell -ExecutionPolicy Bypass -File tools/build_web.ps1", deployed_at_utc, verified_at_utc, verified_routes). `reports/codex-deploy/README.md`(한국어)에 확인 결과를 적는다.
5. 확인: 실제 브라우저로 사이트를 열어 시작 화면(로고, 왼쪽 얼굴 초상화 5개, "[5] Rio", "[V] Body" 줄)이 뜨는지, 5 키로 경기가 시작되는지, 브라우저 콘솔에 게임 오류가 없는지 본다. 소유자 로그인이 필요하면 그 사실을 적는다. 본 것과 짐작한 것을 나눠 적는다.

규칙
- 쓰는 곳은 build/(git이 무시하는 산출물), `.openai/hosting.json`, `reports/codex-deploy/**` 뿐이다. 제품 코드·문서·설정(전역 git 설정 포함)은 바꾸지 않는다.
- 커밋·push 하지 않는다. 기록 파일은 리드가 확인하고 커밋한다.
- GitHub Pages(gh-pages 브랜치, tools/deploy_pages.ps1)는 건드리지 않는다.

최종 보고(한국어): 배포한 main 커밋, 빌드 결과(zip 크기), 사이트 URL과 접근 범위, 버전·배포 ID, 브라우저 확인 결과, 문제가 있었다면 무엇이었는지.
```

## B. 이후 배포 (사이트가 있을 때, 한 줄)

```text
C:\Users\TH\Documents\AI\GameProject\SmashNine 에서 `powershell -ExecutionPolicy Bypass -File tools/build_web.ps1`로 빌드해서(결과 build/web/), reports/codex-deploy/site.json의 기존 사이트에 새 버전으로 배포만 해줘. site.json과 reports/codex-deploy/README.md만 갱신하고, 커밋·push와 다른 파일 수정은 하지 말 것.
```
