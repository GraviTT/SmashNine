# Smash Nine Sites 배포 기록

## 완료

- `git fetch origin` 후 작업 트리가 깨끗하고 `main`이 `origin/main`과 같은 커밋(`97d70c2926c42241a1ef5ba3824795d8af0664cc`)인지 확인했다.
- 지정된 명령으로 Godot 4.7 웹 빌드를 생성했다.
- Sites 새 프로젝트 `appgprj_6ac65f43555481918a37077e8c63c66c`를 등록했고, 접근 범위가 소유자 1명만 포함한 `custom` 정책이며 그룹 접근이 없음을 확인했다.

## 빌드 결과

- 출력 폴더: `build/web/`
- 업로드 ZIP: `build/SmashNine-web.zip`
- ZIP 크기: 36,819,860 bytes (35.11 MiB; 빌드 스크립트 표시는 35.1 MB)
- `index.wasm`: 39,509,339 bytes (37.68 MiB)
- `index.pck`: 26,684,744 bytes (25.45 MiB)
- 필수 파일 `index.html`, `index.js`, `index.wasm`, `index.pck`가 모두 존재한다.
- `index.html`에서 `/`로 시작하는 `src` 또는 `href`는 발견되지 않았다.

## 현재 상태

배포는 완료되지 않았다. Sites 소스 업로드 단계에서 원격 저장소가 다음 오류로 Git 객체를 거부했다.

```text
artifacts_git_receive_pack_object_too_large
```

서버 오류에는 거부된 파일명이 포함되지 않았다. 따라서 특정 파일이 원인이라고 확정하지 않았다. 다만 업로드 대상의 큰 파일은 위에 기록한 `index.wasm`과 `index.pck`이다.

```text
Git 동기화 확인 ✓
        ↓
Godot 웹 빌드 ✓
        ↓
Sites 프로젝트 등록 ✓ (소유자 전용)
        ↓
Sites 소스 업로드 ✗ 대용량 객체 거부
        ↓
버전 저장 / 배포 / 브라우저 확인 미실행
```

위 흐름도에서 실패 지점은 Sites 원격 소스 업로드이며, 그 뒤 단계인 버전 생성과 실제 사이트 게시에는 도달하지 못했다.

## 브라우저 확인

- 게시된 URL이 없으므로 실제 브라우저 확인을 수행하지 않았다.
- 시작 화면의 로고, 얼굴 초상화 5개, `[5] Rio`, `[V] Body`, 5 키 경기 시작, 브라우저 콘솔 오류 여부는 모두 미확인 상태다.
- 등록 시 제시된 주소 `https://smash-nine-prototype.tt9.chatgpt.site`는 게시 성공 URL이 아니므로 결과 URL로 간주하지 않는다.

## 남은 작업

- Sites가 허용하는 방식으로 대용량 Godot 산출물을 전달할 수 있는지 확인해야 한다.
- 파일 제한을 해결한 뒤 새 버전을 저장하고 소유자 전용으로 배포해야 한다.
- 게시 성공 후 실제 브라우저에서 시작 화면, 5 키 경기 시작, 콘솔 오류를 확인해야 한다.

요청 규칙에 따라 파일 크기 제한 오류 이후에는 우회 업로드나 재시도를 하지 않았다.
