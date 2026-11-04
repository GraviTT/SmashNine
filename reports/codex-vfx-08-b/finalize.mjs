import {readFileSync,writeFileSync,readdirSync,statSync} from "node:fs";
import {fileURLToPath, pathToFileURL} from "node:url";
import {relative,join} from "node:path";
import {specs,repo,rootFor} from "./bake-lib.mjs";
const here=new URL("./",import.meta.url),m=JSON.parse(readFileSync(new URL("measurements.json",here),"utf8")).measurements;
const rows=m.map(r=>`| \`${r.id}-b\` | ${r.frames} / ${r.duration.toFixed(2)}초 | F${r.first_visible_frame} | F${r.peak_frame} (${r.peak_time.toFixed(2)}초) | ${r.painted_size.join("×")} |`).join("\n");
const doc=`# CODEX-VFX-08 B — 방향을 따라 남는 여운

완료: Frey 4종, Luna 6종 후보 PNG·JSON·pixelfx 모듈과 캐릭터별 bake.mjs. 게임에는 연결하지 않았다. A 경로·A 파일은 열지 않았고 pixelfx 사본은 읽기만 했다.

- Frey: 도약은 아래·바깥으로 빠지는 흰 깃털과 금빛 먼지, 착지는 바닥을 따라 굴러 나가는 반투명 먼지. 큰 착지는 더 넓고 오래 남는다.
- Luna: 발사 지점 아래에서 앞으로 밀리는 별가루, 날아가는 별의 뒤로 흐르는 분홍·금 꼬리, 기존 불꽃·혜성 폭발 뒤 진행 방향으로 떨어지는 별 조각.
- 꼬리는 **항상 F1부터** 재생한다. 짧게 시작해 길어졌다 다시 짧아지는 과정을 시트에 구워 초기 발사자 겹침을 없앴다. 무작위 시작 프레임은 사용하지 않는다.

## 측정

전부 20fps, 월드 1배. 시간은 프레임 수/fps, 최댓값은 알파를 곱한 max(R,G,B)의 프레임 합계, 크기는 모든 프레임의 그려진 픽셀 합집합이다. 시각적 만족도를 뜻하는 점수는 아니다.

| 시트 | 프레임 / 재생 시간 | 최초 | 밝기 최댓값 | 실제 그려진 크기(px) |
|---|---:|---:|---:|---:|
${rows}

- 124프레임: 첫 그림 공백 0, 1px 테두리 침범 0, 48px 여유 캔버스 비교에서 잘림 0, 반복 렌더 동일. 더하기 시트 알파는 0/255이고 RGB 최댓값 40 미만은 제거했다. 먼지 3종만 반투명 보통 섞기다.
- 일회성 8종은 종료 시 완전히 비고, 마지막 그림 밝기는 최댓값의 0.51~3.14%다. 반복 2종은 t=0과 t=주기의 차이 0이며 마지막→첫 그림 변화량은 내부 프레임 변화 범위 이내다. 세부 수치는 measurements.json.
- 발사·비행은 0도/±60도, 작은 별 1050px/s·0.3초와 큰 별 930px/s·0.36초로 60fps 합성 검사했다. 발사자 영역 겹침 결과는 spawn-overlap.json에 별도로 있다. 이는 고정된 검사 영역·고정 발사자에 대한 측정이며 모든 실제 경기 상황을 보장하지 않는다.
- 적중 여운 자체는 중심의 40×48px 몸 영역과 48×46px 머리 영역에 그려진 픽셀이 0이다. 기존 hit spark와 큰 혜성 폭발은 별도로 합성했으므로 그것들의 기존 가림은 그대로 보인다.

## 눈으로 확인한 것

[board.png](board.png)는 각 시트의 게임 자산 합성 1배와 이펙트 부분 4배다. qa/의 23장에는 **모든 124프레임**을 실제 스프라이트와 함께 1배·4배로 넣었다. [preview.html](preview.html)은 외부 의존성 없는 재생판(정속/느리게, 1/2/4배, 시점 이동), flight-small.png·flight-big.png는 이동하는 별의 세 방향 연속 장면이다. 실제 게임 녹화가 아닌 벤치 합성이다.

수정 과정: ① 첫 초안의 깃털 뭉침과 약한 적중 별을 확인 → 시작 위치 분산·별 크기 증가, ② 입자별 난수 고정으로 입자가 사라질 때 다른 입자가 튀는 원인 제거, ③ 보통 섞기 깃털이 끝에 검어지던 것을 알파 감쇠로 수정, ④ 발사 순간 긴 꼬리의 발사자 겹침을 길이 변화가 있는 반복 시트로 수정하고 발사 별가루를 아래쪽으로 이동했다.

## 사람의 판단 / 남은 작업

- v2 수준으로 충분히 뚜렷한지, 작은 착지에도 깃털이 많은지, 반복 꼬리의 길어졌다 짧아지는 리듬이 자연스러운지, 네 번째 별의 기존 큰 폭발 뒤 여운이 적절한지는 월드컵에서 판단해야 한다.
- 실제 게임 연결, 적중당 1회 생성, 은신/F2, 8인 경기 성능·0.85배 카메라 확인은 하지 않았다. 후보 카드의 범위 밖이다.
- 카드에는 별 아트 1.5배라고 적혔으나 현재 소스의 Projectile.set_effect_art 기본값은 1배이고 Luna._fire_star는 배율을 전달하지 않는다. 기본 합성은 코드의 1배를 따랐다. star-scale-check-4x.png에서 소형/대형 별의 1배·1.5배를 별도로 비교했다. 판정 크기 33/60과 아트 배율을 혼동하지 말아야 한다.
- .git은 현재 환경에서 읽기 전용이므로 커밋하지 않았다. commit.ps1은 이번 파일 목록만 추가하고 커밋한다. 기존 Frey 시범의 파일과 bake() 내보내기는 보존했다. 현재 카드 굽기는 기본 명령이고, 과거 시범은 명시적인 --pilot으로만 실행한다.

## 다시 만들기

저장소 루트에서 순서대로 실행한다(설치 불필요, Node 24, UTF-8).

\`\`\`text
node reports/codex-vfx-08-b/setup.mjs
node art/bakeoff/effects/pixelfx/frey/b/bake.mjs
node art/bakeoff/effects/pixelfx/luna/b/bake.mjs
node reports/codex-vfx-08-b/audit.mjs
node reports/codex-vfx-08-b/render.mjs
node reports/codex-vfx-08-b/preview.mjs
\`\`\`
`;
writeFileSync(new URL("README.md",here),doc.trimEnd()+"\n","utf8");
const files=[];
for(const s of specs)for(const suffix of [".png",".json"])files.push(`art/bakeoff/effects/pixelfx/${s.family}/b/${s.id}-b${suffix}`);
for(const s of specs)files.push(`art/bakeoff/effects/pixelfx/${s.family}/b/src/sn-${s.id.replaceAll("_","-")}-b.js`);
for(const family of ["frey","luna"])for(const name of ["bake.mjs",`src/${family}-motion-b.mjs`])files.push(`art/bakeoff/effects/pixelfx/${family}/b/${name}`);
function walk(dir){for(const ent of readdirSync(dir,{withFileTypes:true})){const p=join(dir,ent.name);if(ent.isDirectory())walk(p);else files.push(relative(fileURLToPath(repo),p).replaceAll("\\","/"));}}
walk(fileURLToPath(here));
for(const p of ["reports/codex-vfx-08-b/commit.ps1","reports/codex-vfx-08-b/manifest.json","reports/codex-vfx-08-b/handoff-check.json"])files.push(p);
const list=[...new Set(files)].sort();
writeFileSync(new URL("manifest.json",here),JSON.stringify(list,null,2)+"\n","utf8");
const ps=`$ErrorActionPreference = 'Stop'
$taskRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
Set-Location -LiteralPath $taskRoot
$files = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'manifest.json') -Raw -Encoding UTF8 | ConvertFrom-Json)
$staged = @(git -c core.quotepath=false diff --cached --name-only)
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect the git index.' }
foreach ($path in $staged) {
    if ($path -notin $files -and $path -ne 'design/tasks/CODEX-VFX-08.md') { throw "Unrelated staged file: $path" }
}
git add -- $files
if ($LASTEXITCODE -ne 0) { throw 'git add failed. No force-add was attempted.' }
git diff --cached --check
if ($LASTEXITCODE -ne 0) { throw 'Whitespace check failed.' }
git commit -m 'art: add directional Frey and Luna VFX-08 B candidates'
if ($LASTEXITCODE -ne 0) { throw 'git commit failed.' }
`;
writeFileSync(new URL("commit.ps1",here),ps,"utf8");
console.log(`README and explicit commit manifest: ${list.length} files.`);
