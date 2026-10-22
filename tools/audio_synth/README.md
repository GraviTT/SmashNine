# 원본 오디오 합성 도구 · AUD-01 / AUD-01a / AUD-02*

## 전체 효과음 후보 · AUD-01

`sfx_all.py`는 카탈로그의 음악 이외 **72종 × 3스타일 = 216 WAV**를 완결한다. 신규 60종·180 WAV를 카드의 순서(선수 → 기술 → 몬스터 → 렐름 → 성장 → 메뉴)로 만든다. 기존 시험 12종·36 WAV는 읽기만 하고 AUD-01a SHA256과 비교한다. `synth.py`의 기존 함수와 시험 보고서는 바꾸지 않았다.

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$audioPython = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $audioPython tools/audio_synth/sfx_all.py
& $audioPython tools/audio_synth/verify_sfx_all.py
node tools/sound_viewer/build.mjs --out reports/codex-aud-01/preview
node tools/sound_viewer/verify.mjs --out reports/codex-aud-01/preview
```

전체판을 만든 후에는 `verify_sfx_all.py`를 사용한다. 아래의 과거 `verify.py`는 시험 36파일만 존재하는 폴더를 가정한 역사적 검증기다. 전체판 검증기가 시험 36개까지 함께 PCM 재현·SHA256을 재검사한다. 시험 파일을 다시 만드는 `synth.py`는 이 작업에서 실행하지 않았다.

- DSP는 numpy, WAV 입출력은 표준 라이브러리, 그림은 기존 Pillow를 사용한다. 설치·다운로드·샘플·녹음·외부 합성 모델은 없다. 시드는 ID·스타일의 SHA256에서 고정된다.
- `SPECS`는 이름·길이·RMS 목표·음색 의도이며 `render_raw()`의 명시적 분기가 각 동작의 작은 악보다. A는 배음 제한 사각·삼각파와 계단 잡음, B는 감쇠 FM과 대역 잡음, C는 FM 몸통·추가 배음·저역·순간 잡음 층을 사용한다. 실제 하드웨어 에뮬레이터는 아니다.
- 프레이는 강철·날개·밝은 종, 루나는 별 아르페지오, Brave는 별+타격 몸통, 유키는 종이 마찰+방울, 노바는 서보·에너지 펄스, 리오는 룬 공명+차원 마찰이다. 궁극기 7종(공용 포함)은 0.90~1.18초, 기술 13종(공용 포함)은 0.22~0.38초다. `victory`는 직접 작곡한 1.65초의 D-A-D-F-A-D 팡파르다. 이름은 재생 이벤트를 설명하며 피해·폭발 시각을 보증하지 않는다.
- 새 `master()`는 기본적으로 선형 게인만으로 목표 RMS를 맞춘다. 피크 한도를 넘을 때만 부호를 보존하는 거듭제곱으로 crest factor를 줄인다. 적용 지수 `crest_shape_gamma`를 기록한다. 시작 0.7ms와 끝 최대 12ms sin² 페이드, 양 끝 샘플 0. PCM 정수 한도를 내림하여 신규 파일의 실제 샘플 피크가 **−1.00015 dBFS 이하**다.
- 새 조용한 클래스: 수풀·UI 이동 −24, 대사 한 줄 −28, 대사 넘김 −23 dBFS. 기존 확인·취소 −14는 보존했다. 전체 RMS 범위는 −28~−13.5이며 같은 ID의 세 스타일은 같은 목표다. RMS는 체감 음량이나 LUFS가 아니다.
- `reports/codex-aud-01/`에 전체 216행 수치, 독립 재검증, **ID당 A/B/C 파형+스펙트로그램 한 그림(72장)**과 그룹별 음량 개요를 남긴다. 파형 ±1, STFT Hann 1024/hop128, 로그 60~22,050Hz, 고정 −80~0dBFS 색상으로 비교한다.
- `verify_sfx_all.py`는 카탈로그 완결성, 규격·목표 RMS·피크·클리핑·길이·시작·꼬리, PNG 읽기, 중복 음원 없음, **216개의 메모리 재합성과 PCM 바이트 일치**, 시험 36개의 원래 SHA256을 검사한다. 시험의 피크는 원래 정수 반올림으로 −0.999854dBFS이므로 0.0002dB 오차를 허용하고 별도로 보고한다. 신규에는 이 오차를 허용하지 않는다.

모든 음색 표현은 합성 의도다. 직접 청음·게임 내 믹스·true peak·LUFS·브라우저 디코딩은 확인하지 않았다. 리드용 결과·청음 순서는 [AUD-01 보고서](../../reports/codex-aud-01/README.md), 페이지·재게시는 [sound_viewer README](../sound_viewer/README.md)를 따른다.

## 음악 후보 · AUD-02a

`music.py`가 기존 `synth.py`의 연속 위상 발진기·대역 제한 잡음·폰트를 재사용한다. 패키지 설치·샘플·다운로드 없이 numpy/Pillow/표준 라이브러리만 쓴다. 기존 효과음 합성 결과는 바꾸지 않는다.

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$python = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $python tools/audio_synth/music.py
& $python tools/audio_synth/verify_music.py
node tools/sound_viewer/build.mjs
node tools/sound_viewer/verify.mjs
```

- 먼저 마디별 악보 데이터(`score()`, `P`, `BATTLE`, 코드표)를 만들고 렌더한다. 각 파트는 시작 박·음·길이·강도로 기록된다. 공통 모티프는 **D5 A5 G5 E5 F5 D5**, D 도리안이다.
- 타이틀: 100 BPM, 4/4, 16마디, 38.4초. 전투: 160 BPM, 4/4, 24마디, 36초. 같은 곡의 세 스타일은 선율·베이스·리듬 악보가 같고 화성 파트는 A의 단음 아르페지오 / B·C의 짧은 코드 패드로 다르다.
- A: 펄스 선율 + 25% 펄스 화성 + 삼각파 베이스 + 계단 잡음 드럼, 모노. NES 계열 음색이며 회로·채널 제한을 정밀 재현하는 에뮬레이터는 아니다.
- B: FM 선율·베이스, 사인 배음 패드, 합성 킥·스네어, 23–89ms의 짧은 방 잔향, 스테레오.
- C: 펄스 선율, 부드러운 배음 패드, FM 베이스, 저음·잡음층을 겹친 킥·스네어, 스테레오.
- 음악은 **효과음용 `master()` 페이드를 쓰지 않는다.** 음의 릴리스와 방 잔향을 원형 버퍼에 합산하고, 마지막 D를 시작 D에 붙임줄로 연결한다. DC 제거와 일정한 게인만 적용해 전체 RMS −18 dBFS로 맞춘다. 압축·리미터·클리핑·끝 페이드가 없다.
- `reports/codex-aud-02a/`에 여섯 악보 TXT/JSON, 파형·스펙트로그램·±10ms 경계 확대 PNG, `measurements.json`을 쓴다. `verify_music.py`는 디스크 PCM의 규격·음량·마디 길이·10ms 경계·모티프를 확인하고 여섯 파일을 메모리에서 다시 합성해 바이트 단위 비교한다.
- LUFS는 측정하지 않는다. 카드에서 허용한 **RMS 대체 기준**을 사용한다. 샘플 피크이며 true peak는 미측정이다. 수치·그림 검사는 직접 청음이나 게임 내 효과음 믹스의 승인을 대신하지 않는다.

아래는 기존 효과음 전용 설명이다. 효과음 `verify.py`는 `music_*`를 제외해 음악 후보와 함께 둘 수 있다.

12개 동작 × A/B/C 3스타일, 총 36개 **후보**를 만든다. 게임 파일은 읽거나 쓰지 않는다. 모든 소리는 수식·고정 시드 잡음에서 직접 합성했으며, 샘플·음원 다운로드·외부 오디오 패키지는 사용하지 않았다.

## 실행

저장소 루트의 PowerShell에서 실행한다. 설치 작업은 없다. 무거운 프로세스는 하나씩 실행한다.

```powershell
$env:PYTHONDONTWRITEBYTECODE = '1'
$python = 'C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
& $python tools/audio_synth/synth.py
& $python tools/audio_synth/verify.py
node tools/sound_viewer/build.mjs
node tools/sound_viewer/verify.mjs
```

필요한 것은 지정 Python의 numpy·Pillow와 표준 라이브러리, Node뿐이다. DSP는 numpy로만 처리하고, Pillow는 분석 그림을 그리는 데만 사용한다. `PYTHONDONTWRITEBYTECODE=1`을 반드시 유지한다.

## 합성 구조

- `synth.py`의 `<sound>_<style>(duration=..., seed=...)`가 36개의 개별 진입 함수다. 함수 안에 음정·피치 변화 시간·감쇠·변조량·레이어 비중이 명시되어 있다. UI A/B는 잡음이 없어 seed가 소리에 영향을 주지 않지만 호출 형식은 같다.
- A: 배음 수를 제한한 사각파·삼각파, 시드 고정 계단 잡음. 짧고 선명한 칩튠을 의도한다. 특정 게임기 회로의 정밀 에뮬레이션은 아니다.
- B: 연속 위상 FM, 감쇠하는 변조 깊이, 작은 피치 굴곡, 대역을 제한한 잡음. 둥근 몸통과 짧은 금속성 울림을 의도한다.
- C: 대역 잡음의 순간 타격 + 음정이 있는 몸통 + 짧은 저음 펄스. UI·점프·휘두르기는 저음 비중이 작고, 강타·착지·KO는 크다.
- 음정 이동은 주파수를 적분한 연속 위상이다. KO A의 보조음은 음계 단계를 바꾸지만 위상은 이어진다.
- 모든 잡음은 `numpy.random.default_rng(seed)`로 새로 만든다. FFT 대역 마스크를 적용한다. 시간·OS·외부 파일에 의존하는 랜덤 요소가 없다.

## 출력과 마스터 처리

1. `art/audio_bakeoff/<sound>-<a|b|c>.wav`: 44,100 Hz, PCM 16-bit, mono.
2. `master()`는 DC 평균을 제거한 뒤, 파형의 부호를 유지하는 거듭제곱으로 crest factor(피크와 평균 음량의 차이)를 조절한다. 같은 효과의 세 스타일을 RMS 목표에 맞춘다. 적용 지수는 `crest_shape_gamma`에 기록한다. 이 처리는 음색에도 영향을 주므로 청음해서 최종 선택해야 한다.
3. 시작 0.7ms, 끝 10ms에 sin² 페이드를 적용하고 첫·끝 샘플을 0으로 둔다. 피크는 −1 dBFS로 맞춘다. 하드 클리핑·랜덤 디더는 사용하지 않는다.
4. 디스크에 쓴 WAV를 다시 열어 수치를 측정한다. 소수점 반올림 전 값·SHA256은 `reports/codex-aud-01a/measurements.json`, 사람이 읽는 표는 `measurements.md`에 기록한다.
5. 파일마다 파형+스펙트로그램 PNG 하나, 스타일마다 12개를 모은 overview PNG 하나를 만든다. 파형은 ±1 고정 축, 스펙트로그램은 Hann 1024 / hop 128, 60–22,050 Hz 로그 축, −80–0 dBFS 고정 색상이다. 그림마다 자동 대비를 바꾸지 않는다.

| 효과 | 길이 s | A/B/C 공통 RMS 목표 dBFS |
|---|---:|---:|
| hit_light | 0.18 | −13.5 |
| hit_heavy | 0.34 | −13.5 |
| swing | 0.21 | −15.0 |
| jump | 0.17 | −14.0 |
| land | 0.12 | −14.0 |
| guard | 0.21 | −14.0 |
| parry | 0.34 | −14.0 |
| hurt | 0.23 | −13.5 |
| ko | 0.78 | −16.0 |
| portal | 1.02 | −16.0 |
| ui_select | 0.10 | −14.0 |
| ui_cancel | 0.10 | −14.0 |

## 검증 범위

`verify.py`는 납품 WAV를 별도로 열어 형식·피크·RMS·길이·클리핑·양 끝·시작 지연·마지막 1ms를 확인한다. 다시 합성한 PCM과 파일의 PCM을 바이트 단위로 비교한다. 보고된 SHA256도 대조한다. 같은 효과의 A/B/C RMS 최대–최소 차이는 3dB 이하를 요구한다(카드의 ±3dB보다 엄격한 기준).

RMS는 파일 전체 샘플의 제곱평균 제곱근이며 지각 음량 점수는 아니다. 피크는 샘플 피크다. 끝 샘플 0·낮은 끝부분 진폭은 절단 클릭을 수치로 점검하는 기준이며, 실제 귀로 무클릭을 확정한 것은 아니다. 사용자 청음·게임 내 중첩 재생 검사는 후속 단계다.
