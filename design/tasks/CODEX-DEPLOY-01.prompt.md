SmashNine(가제) 웹 빌드를 GitHub Pages에 배포해 줘.

- 저장소: C:/Users/TH/Documents/AI/GameProject/SmashNine (리드의 main 체크아웃. SmashNine-units 아래 유닛 클론이 아님)
- 사이트: https://gravitt.github.io/SmashNine/
- 지금 배포된 것: gh-pages 커밋 메시지 "Deploy web build from 58bf86e"
- 배포할 것: origin/main 최신 (작성 시점 802b7c6, 캐릭터 아트 v2)

## 순서
1. 상태 확인: `git fetch origin` 후 `git status`가 깨끗하고 main이 origin/main과 같은지 본다. 다르면 배포하지 말고 그대로 보고한다.
2. 검사: smash-nine-prototype/ 에서 `powershell -ExecutionPolicy Bypass -File tests/run_all.ps1` → 마지막 줄 ALL PASSED.
   - 샌드박스에서 모든 Godot 실행에 찍히는 "ERROR: Failed to read the root certificate store" 한 줄은 알려진 잡음이다(AGENTS.md). 실패 원인이 이 줄뿐이면 통과로 보고 그 사실을 따로 적는다. 다른 오류로 실패하면 배포하지 말고 보고한다.
3. 배포: 저장소 루트에서 `powershell -ExecutionPolicy Bypass -File tools/deploy_pages.ps1`
   - 이 스크립트가 웹 export(tools/build_web.ps1)를 하고, build/gh-pages 에 커밋 하나짜리 저장소를 만들어 origin 의 gh-pages 브랜치에 force push 한다. 마지막 줄은 "Deployed <sha> to gh-pages. Site: ..."
4. 확인:
   - `git ls-remote origin gh-pages` 가 새 커밋을 가리키고, 그 커밋 메시지가 "Deploy web build from <main 짧은 sha>" 인지.
   - 1–2분 뒤 사이트의 index.html, index.pck, index.wasm 이 200 으로 응답하는지. 가능하면 브라우저로 시작 화면을 열어 로고, 왼쪽 얼굴 초상화 5개, "[5] Rio", "[V] Body" 줄이 보이는지.

## 규칙
- main 브랜치에는 커밋하거나 push 하지 않는다. force push 는 gh-pages 에만(스크립트가 하는 것). main 을 force push 하지 않는다.
- 제품 코드, 문서, 설정(전역 git 설정 포함)을 바꾸지 않는다. build/ 는 git 이 무시하는 산출물이라 생겨도 된다.
- 네트워크(git push, 사이트 확인)가 필요하다. 샌드박스나 인증 때문에 막히면 무엇이 막혔는지 그대로 보고하고 멈춘다. 자격 증명을 새로 만들거나 바꾸지 않는다.
- push 가 HTTP 408 로 실패하면 한 번 더 시도한다(이 저장소에는 http.postBuffer 가 이미 크게 설정돼 있다). 또 실패하면 보고한다.
- Godot 콘솔: C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe (GODOT_BIN 으로 바꿀 수 있음). 웹 템플릿: %APPDATA%\Godot\export_templates\4.7.stable (설치돼 있음).

## 최종 보고 (한국어)
배포한 main 커밋, 검사 결과, 빌드 zip 크기, gh-pages 새 커밋과 메시지, 사이트 확인 결과(직접 확인한 것과 짐작한 것을 나눠서), 문제가 있었다면 무엇이었는지.
