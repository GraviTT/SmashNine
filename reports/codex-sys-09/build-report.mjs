import fs from 'node:fs';
import path from 'node:path';
import { execFileSync } from 'node:child_process';
const dir = 'reports/codex-sys-09';
const read = file => fs.readFileSync(file, 'utf8').replace(/^\uFEFF/, '').replace(/\r\n/g, '\n');
const readLog = file => {
  const bytes = fs.readFileSync(file);
  return bytes[0] === 0xff && bytes[1] === 0xfe ? bytes.toString('utf16le').replace(/^\uFEFF/, '') : bytes.toString('utf8');
};
const result = JSON.parse(read(`${dir}/face-results.json`));
const suite = JSON.parse(read(`${dir}/full-suite-result.json`));
const summary = readLog(`${dir}/full-suite.log`).replace(/\r\n/g, '\n');
const suitePasses = summary.split('\n').filter(line => /^PASS test_|^PASS visual_preview/.test(line));
const lastLines = summary.trim().split('\n').slice(-2).join('\n');
const soak = JSON.parse(summary.match(/SOAK_RESULT (\{[^\n]+\})/)[1]);
const rawSuiteErrors = fs.readdirSync(`${dir}/full-suite`).filter(name => name.endsWith('.log')).flatMap(name =>
  readLog(`${dir}/full-suite/${name}`).split('\n').filter(line => /^\s*(SCRIPT ERROR|ERROR|Parse Error)/.test(line) && line.trim() !== 'ERROR: Failed to read the root certificate store.').map(line => `${name}: ${line.trim()}`)
);
const product = [
  'smash-nine-prototype/scripts/ArtSettings.gd',
  'smash-nine-prototype/scripts/ui/StoryDialogue.gd',
  'smash-nine-prototype/scripts/story/StoryCatalog.gd',
  'smash-nine-prototype/tests/test_story_faces.gd',
  'smash-nine-prototype/tests/run_all.ps1',
  'smash-nine-prototype/assets/art/README.md',
];
const catalogPath = product[2];
const originalCatalog = execFileSync('git', ['show', `HEAD:${catalogPath}`], { encoding: 'utf8' }).replace(/\r\n/g, '\n');
const strippedCatalog = read(catalogPath)
  .replace(/\t# Sparse face tags;[\s\S]*?(?=\t# Scene pictures)/, '')
  .replaceAll(', {"cg": "", "face": "angry"}', '');
const modified = execFileSync('git', ['diff', '--name-only'], { encoding: 'utf8' }).trim().split('\n').filter(Boolean);
const imageChanges = execFileSync('git', ['diff', '--name-only', '--', 'smash-nine-prototype/assets'], { encoding: 'utf8' }).trim().split('\n').filter(name => /\.(png|webp|jpg)$/i.test(name));
const reportFiles = [
  'README.md', 'build-report.mjs', 'run-focused.ps1', 'commit.ps1', 'commit-files.txt',
  'face-results.json', 'validation.json', 'full-suite-result.json', 'full-suite.log',
  'import.log', 'import-isolated.log',
  ...fs.readdirSync(dir).filter(name => /^test_story_.*\.log$/.test(name)),
];
const commitFiles = [...product, ...reportFiles.map(name => `${dir}/${name}`)];
fs.writeFileSync(`${dir}/commit-files.txt`, commitFiles.join('\n') + '\n');
const validation = {
  branch: execFileSync('git', ['branch', '--show-current'], { encoding: 'utf8' }).trim(),
  story_catalog_without_face_tags_equals_HEAD: originalCatalog === strippedCatalog,
  tracked_changes_within_allowlist: modified.every(name => product.includes(name)),
  tracked_asset_image_changes: imageChanges,
  no_candidate_asset_adoption: imageChanges.length === 0 && fs.readdirSync('smash-nine-prototype/assets/art', { recursive: true }).every(name => !/_face_(happy|angry|hurt|shadow)\.png$/.test(name)),
  test_passed: result.passed,
  full_suite_exit: suite.exit_code,
  full_suite_tests_passed: suitePasses.length,
  full_suite_all_passed: summary.includes('ALL PASSED') && !/^FAIL/m.test(summary),
  full_suite_non_certificate_engine_errors: rawSuiteErrors,
  soak: { match_over: soak.match_over, winner: soak.winner, seconds_simulated: soak.seconds_simulated, players: soak.players, nan_positions: soak.nan_positions },
  scoped_logs_under_1MiB: fs.readdirSync(dir, { recursive: true }).filter(name => name.endsWith('.log')).every(name => fs.statSync(path.join(dir, name)).size <= 1024 * 1024),
  commit_script_executed: false,
};
const reason = row => {
  if (row.speaker === 'narrator') return '서술';
  if (row.speaker === 'shadow') return '위협';
  if (row.id === 'story.s03.home.post.2') return '충격';
  if (row.id === 'story.s08.home.pre.2') return '애도';
  if (row.id === 'story.s03.pre.2') return '호기';
  if (row.id === 'story.s04.pre.1') return '여유';
  if (row.id === 'story.s02.pre.1') return '추궁';
  if (row.id === 'story.s02.pre.2') return '도전';
  if (row.face === 'angry') return row.id.includes('home.pre') ? '수호' : '결의';
  if (row.id === 'story.voice.yuki.victory' || row.id === 'story.s03.post.1') return '사과';
  if (row.id === 'story.voice.luna.victory') return '환희';
  if (row.id.includes('post')) return '정보';
  return '침착';
};
const table = [...result.rows].sort((a, b) => a.id.localeCompare(b.id)).map(row =>
  `| \`${row.id}\` | ${row.speaker} | ${row.ko.replaceAll('|', '\\|')} | ${row.face || (row.speaker === 'shadow' ? '없음 · shadow 자동' : '없음')} | ${reason(row)} |`
).join('\n');
const text = `# SYS-09 작업 완료 — 스토리 표정과 그림자 얼굴 연결

선택한 후보를 정해진 제품 경로에 복사하고 임포트하면 대화에 반영된다. 현재 후보는 한 장도 복사하지 않았으며, 기존 얼굴과 색조를 유지한다. 작업 브랜치는 \`codex/sys-09\`다. 커밋 스크립트는 작성·구문 검사만 했고 실행하지 않았다.

## 변경된 내용

- \`ArtSettings.character_portrait(id, body, expression := "")\`: 표정 파일 우선, 없으면 기존 중립 얼굴·픽셀 초상화·idle 칸으로 폴백한다. 기존 두 인자 호출은 그대로다. 중립 얼굴이 결정한 stem을 따라 남녀 표정이 섞이지 않는다.
- \`StoryDialogue\`: 말하는 쪽에만 태그 표정을 적용하고, 매 줄 양쪽 얼굴을 다시 선택한다. 무태그·비발화자는 중립, 비발화자 밝기 감소는 기존과 같다. 그림자 파일이 있으면 추가 보라색 없이 표시하고, 없으면 기존 중립에 보라색을 곱한다. 그림자는 감정 태그보다 shadow 정체성을 우선한다.
- \`StoryCatalog\`: 대사 목록의 얼굴 메타데이터만 추가했다. 기존 장면 그림 테스트가 세 번째 사전의 cg 키를 읽으므로 빈 cg도 명시했다. 태그를 제거한 카탈로그가 HEAD와 완전히 같음을 별도 검사했다. 대본·번역·진행·저장 코드는 바꾸지 않았다.
- \`tests/test_story_faces.gd\`와 전체 테스트 목록을 추가하고, [아트 채택 경로](../../smash-nine-prototype/assets/art/README.md)에 복사 표를 적었다.

## 태그 수와 판단 범위

실제 카탈로그를 다섯 주인공으로 해석한 **고유 대사 ID 87개** 중 angry **15줄**, happy **2줄**, hurt **2줄**이다. 나머지는 무태그 68줄(그림자 10줄은 shadow를 자동 선택, 중립·해설 58줄)이다. 동일한 도전 대사가 여러 라이벌 스테이지에서 재생되어도 ID는 한 번 센다. 별도 엔딩 화면의 15줄은 이 대화 목록 밖이므로 바꾸지 않았다.

한국어·영어 CSV의 전 문장과 STORY.md를 읽고 선택했다. 표정의 감정 적합성은 **문맥에 대한 판단**이며 수치로 측정한 사실이 아니다. angry는 격한 분노뿐 아니라 도전·수호·결의, happy는 루나의 싸움에 대한 호기와 리오의 여유, hurt는 루나의 자기 그림자에 대한 충격과 유키의 수호수에 대한 애도로 해석했다. 마지막 맞서기 줄들은 모두 적극적인 결의여서 hurt 대신 angry다.

주인공 공용 도전 템플릿은 다섯 주인공에 같은 angry 태그를 쓴다. 공용 승리 템플릿은 유키의 사과·프레이와 노바의 차분한 판단까지 포함하므로 happy를 일괄 지정하지 않았다. 이 때문에 루나의 환희가 분명한 승리 줄도 현재는 중립이다. 주인공별로 태그를 달리하는 새 메타데이터 형식은 추가하지 않았다. 전체 국·영문과 실제 태그는 [face-results.json](face-results.json)에 있다.

## 시각적 확인

\`\`\`mermaid
flowchart TD
    L[대사의 face 태그] --> S{말하는 쪽}
    S --> H[주인공: 왼쪽 / 라이벌: 오른쪽]
    H --> E{같은 stem의 표정 파일 존재?}
    E -->|예| P[선택 표정]
    E -->|아니요·무태그| N[기존 중립 얼굴]
    S --> X[그림자: 오른쪽]
    X --> Q{shadow 파일 존재?}
    Q -->|예| A[그림자 그림 · 추가 색조 없음]
    Q -->|아니요| B[중립 얼굴 × 기존 보라색]
    D[말하지 않는 인물] --> M[중립 또는 그림자 얼굴 × 기존 밝기 감소]
\`\`\`

위 흐름은 실제 코드의 선택 순서다. headless만 사용하라는 지시에 따라 실행 화면은 촬영하지 않았다. 새 후보의 시각 품질·작은 화면 가독성은 이번 테스트로 판단하지 않았다.

## 확인 및 테스트

- 최종 얼굴 테스트: **${result.assertions.toLocaleString('en-US')}개 검사 통과**. 5명·7체형 × 한/영 × 원본/프로토타입 설정에서 스테이지 1–9와 고향 분기, 중간 그림자 대사까지 **${result.fallback_lines.toLocaleString('en-US')}회 표시**의 텍스처·색조·표시 여부를 이전 코드의 선택 결과와 비교했다. 태그와 CG 공존도 검사했다.
- 테스트 이미지는 코드의 ImageTexture와 Resource.take_over_path로 메모리에만 주입했다. 후보 PNG나 임시 텍스처 파일을 제품 경로에 쓰지 않았다. 세 표정의 주인공·라이벌 선택, 무태그 복귀, 비발화자 어둡게 표시, 그림자 그림 유무, 체형 일부만 채택, 얼굴 없는 시트 폴백, 중립 얼굴보다 먼저 표정이 있는 경우를 검사했다.
- 실제 표정이 채택된 미래에는 “표정 파일이 전혀 없는 실제 에셋 상태” 비교만 명시적으로 건너뛴다. 합성 텍스처를 쓰는 표정 선택 검사는 유지되며, 합성 ID로 그림자 부재·시트 폴백도 계속 검사한다. 이번 실행에서는 파일이 없어 1,372회 비교를 모두 수행했다.
- 기존 \`test_story_*\` 8개 + 신규 얼굴 테스트 = **9개 모두 통과**. 그 뒤 마지막 테스트 보완본을 단독 재실행해 통과했다.
- 전체 \`tests/run_all.ps1\`은 기본 설정으로 **1회** 실행: 검사 스크립트 **${suitePasses.length}개 통과**(test_* 53개 + visual_preview 1개), 봇 소크 1회 포함, 종료 코드 **${suite.exit_code}**. [전체 출력](full-suite.log), [실행 시각·종료 코드](full-suite-result.json), [얼굴 테스트 원문](test_story_faces.log).
- 소크 측정: seed 1001, ${soak.players}명, 시뮬레이션 ${soak.seconds_simulated}초에 ${soak.winner} 승리, match_over=${soak.match_over}, NaN 위치 ${soak.nan_positions}개. 알려진 인증서 저장소 오류를 제외한 전체 스위트 원문 엔진 오류 ${rawSuiteErrors.length}개. 이 한 판은 실행 안정성 측정이며 사람의 난이도나 표정 가독성 측정이 아니다.

전체 스위트 마지막 두 줄:

\`\`\`text
${lastLines}
\`\`\`

첫 임포트는 샌드박스 밖 Godot 사용자 캐시 쓰기 오류로 실패로 판정했다(프로세스 종료 코드만 0). APPDATA와 LOCALAPPDATA를 TEMP의 전용 프로필로 격리한 재임포트는 종료 0, 알려진 인증서 저장소 오류 외 엔진 오류 0이었다. 두 임포트의 로그를 모두 남겼다. 프로젝트 설정은 바꾸지 않았다. 인증서 오류는 환경 소음으로 따로 기록하며 그 외 오류를 무시하지 않았다.

## 전체 대사 검토표

태그 없음은 중립이며, shadow는 얼굴 태그를 추가하지 않고 화자 종류로 자동 선택한다. 한 단어 이유는 감정 판단 근거다.

| 대사 ID | 화자 | 한국어 대사 | face | 이유 |
|---|---|---|---|---|
${table}

## 현재 상태 / 남은 작업 / 다음 권장 단계

연결·태그·자동 검증은 완료했다. 후보 채택과 실제 아트의 감정 전달 판단은 남아 있다. 리드가 위 표와 후보를 검토한 뒤 선택 파일만 채택 표의 경로로 복사하고 임포트하면 된다. [commit.ps1](commit.ps1)은 이 카드의 명시적 파일만 포함하며 실행하지 않았다. 기존 다른 카드의 미추적 파일은 포함하지 않는다.
`;
fs.writeFileSync(`${dir}/README.md`, text);
fs.writeFileSync(`${dir}/validation.json`, JSON.stringify(validation, null, 2) + '\n');
if (Object.entries(validation).some(([key, value]) => key !== 'commit_script_executed' && typeof value === 'boolean' && !value) || suite.exit_code !== 0 || rawSuiteErrors.length > 0) {
  console.error(JSON.stringify(validation, null, 2));
  process.exitCode = 1;
} else {
  console.log(JSON.stringify(validation, null, 2));
}
