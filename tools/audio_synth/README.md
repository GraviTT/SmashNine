# 첫 효과음 합성 도구 · AUD-01a

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
