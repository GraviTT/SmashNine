# 소리 적용 (2026-10-29)

- 요청(점검 세션이 사용자 승인을 전달, 10-29): "소리 뷰어 DB `sound_picks` … 효과음 전체는 c, 예외 7종(ui_move·ui_select·ui_cancel·story_text·story_advance·victory·results)은 b, 음악 5곡은 모두 b. … 고른 WAV 77개를 OGG로 바꿔 `design/AUDIO.md`와 오디오 관리자가 기대하는 경로·이름으로 넣습니다. 음악은 반복 이음새가 깨지지 않게 하고, Godot 가져오기 설정(loop)도 맞춥니다. 효과음과 음악의 대략적인 음량 균형을 확인합니다. 소리별 최소 간격(SYS-08)은 그대로 둡니다. 웹 빌드 크기 변화도 기록합니다."
- 브랜치 `apply/sound-2026-10-29`, main `8f75113c`에서 시작. 작업 폴더 `SmashNine-units/apply/SmashNine`. main에는 합치지 않았다.
- Codex는 쓰지 않았다. 변환과 측정은 기계적인 작업이었고, 같은 PC에서 다른 세션의 Godot·Codex가 돌고 있어 테스트 타이밍이 이미 흔들렸기 때문이다.

## 한눈에

| 항목 | 결과 |
|---|---|
| 넣은 소리 | 77개 OGG(효과음 72 + 음악 5), 2.53MB. 고른 스타일 그대로(효과음 C, 예외 7종 B, 음악 B) |
| 음악 반복 | 데스크톱: 샘플 단위로 틈 없이 돈다(디코드·게임 녹음 모두 이음새 앞뒤 정렬 차 0). 웹: 엔진이 끝날 때 다시 시작하는 방식이라 한 바퀴마다 약 3~25ms 끊김 |
| 게임에서 실제 재생 | 데스크톱(실제 시작 경로 포함)과 웹 모두에서 고른 파일이 재생되는 것을 녹음·로그로 확인 |
| **발견 1 (고침)** | 게임을 켜면 오디오 관리자가 루트에 붙지 못해 **소리가 전혀 나지 않았다**(기존 결함, 파일이 없어 드러나지 않음). `AudioManager.install`을 고쳤다 |
| **발견 2 (고침)** | 파일이 생기자 종료 때 "resources still in use at exit" 오류로 run_all 7개 테스트가 실패했다. 종료 처리(`_exit_tree`)를 고쳤다 |
| **발견 3 (결정 필요)** | 효과음이 많이 겹치는 전투에서 출력이 넘친다(60초 봇 경기, 0.13% 구간, 최대 +10.1dBFS). 코드·기본값은 바꾸지 않았다 |
| 음량 균형 | 음악 −22.4dBFS 위로 전투음 +9~13dB. story_text·ui_move는 설계대로 음악보다 작다(귀로 확인할 것) |
| SYS-08 간격 | 그대로 |
| 웹 빌드 | 폴더 +2.71MB(68.6 → 71.1MiB), zip +2.26MB(38.3 → 40.4MiB) |
| 테스트 | 작업 폴더 run_all **ALL PASSED**(54개 + 봇 소크 seed 1001), 시간 초과 없음. test_audio 858개 확인 |

## 1. 고른 것 (시작할 때 한 번 읽은 스냅샷)

`picks-snapshot.json`: 소리 뷰어(https://claude.ai/artifact/BWneucCv1GHme5JX7fmUuW) DB `sound_picks`의 문서 13개를 2026-10-29 14:44 UTC에 한 번 읽었다. 모두 version 1이다.

| 문서 | 고른 것 | 적용 |
|---|---|---|
| `style` | c | 효과음 72종의 기본 |
| ui_move, ui_select, ui_cancel, story_text, story_advance, victory, results | b | 이 7종만 b |
| music_title, music_select, music_battle, music_story, music_results | b | 음악 5곡 모두 b |

## 2. 넣은 파일

| 항목 | 값 |
|---|---|
| 위치 | `smash-nine-prototype/assets/audio/sfx/<id>.ogg` 72개, `assets/audio/music/<id>.ogg` 5개(`AudioManager._load_stream`이 찾는 경로, `design/AUDIO.md`) |
| 출처 | `art/audio_bakeoff/<id>-<c|b>.wav`. id별 출처 파일과 SHA-256은 `manifest.json` |
| 변환 | ffmpeg 9.0.2 libvorbis, 품질 q6, 44.1kHz, 효과음 모노·음악 스테레오, 메타데이터 없음, bitexact(다시 돌려도 같은 바이트) |
| 크기 | 효과음 631KB, 음악 1.90MB, 합계 2.53MB(WAV 34.2MB) |
| Godot 가져오기 | 효과음 `loop=false`, 음악 `.import`만 `loop=true`·`loop_offset=0`(bpm·beat_count 0이라 파일 끝에서 처음으로 돈다). 가져오기를 두 번 돌렸고 두 번째는 오류가 없었다 |
| 코드 | 소리를 고르고 재생하는 규칙과 SYS-08 간격(`AudioCatalog.gd`의 `gap_ms`)은 그대로다. 고친 곳은 `AudioManager.gd`의 시작(`install`·`find`·`_ready`·`play_music`)과 종료(`_exit_tree`) 처리다(5장) |

## 3. 확인한 것

### 파일 자체 (`convert_audio.py` → `manifest.json`)
- 77개 모두 Ogg 마지막 페이지(EOS)의 granule이 WAV 프레임 수와 같다. 음악 길이: 타이틀 1,693,440 · 선택 1,411,200 · 전투 1,587,600 · 스토리 1,881,600 · 결과 1,270,080 프레임(38.4·32.0·36.0·42.667·28.8초, 마디 끝).
- 주의: ffmpeg로 다시 풀면 짧은 효과음 길이가 −128~+981프레임 다르게 나온다. 오디오 페이지가 하나뿐인 스트림을 ffmpeg 디코더가 잘못 읽어서 생기는 차이이고, 파일의 granule은 정확하다. 그래서 길이·정렬 판정은 아래 Godot 디코드로 했다.

### Godot가 실제로 푸는 소리 (`tests/analysis/lead/sound_apply_decode.gd` + `verify_decode.py` → `decode-check.json`)
가져온 리소스를 게임과 같은 `AudioStreamPlayback`으로 풀어 WAV와 비교했다.

| 항목 | 결과 |
|---|---|
| 시작 위치 | 77개 모두 2프레임 뒤. Godot 리샘플러가 모든 소리에 똑같이 두는 이력 2프레임이고, 소리가 잘리지는 않는다 |
| 음색 | 1/3옥타브 대역 차이 최대 1.53dB(story_advance), 잡음이 많은 휘두름·대시·수풀도 0.69dB 이하. 음량 차이 −0.32~+0.07dB |
| 파형 SNR | 효과음 14.2~38.5dB, 음악 33.6~36.4dB. 잡음 성분은 Vorbis가 파형 대신 잡음으로 다시 만들기 때문에 SNR이 낮게 나온다. 위 대역 차이가 그 경우에도 소리 색이 유지됨을 보여 준다 |
| 효과음 끝 | Godot가 반복 없는 OGG의 마지막 4~128프레임(최대 2.9ms)을 재생하지 않는다. 그 구간은 39개 소리에서 완전한 무음이고, 나머지도 피크 −41dBFS 이하 꼬리다(가장 큰 것: monster_hurt). 파일이 아니라 엔진 쪽 동작이라 그대로 두었다 |
| 음악 루프 | 5곡 모두 가져온 리소스가 `loop=true`. 끝 1초 전부터 2초를 풀면 이음새 앞뒤 정렬이 같다(2/2, 결과곡 3/3) = 틈도 겹침도 없다. AUD-02 이음새 기준(끝→처음 샘플 차 <0.01FS, 앞뒤 10ms RMS 차 <6dB, 이음새 20ms가 주변 400ms보다 12dB 넘게 낮지 않음)을 5곡 모두 통과 |

### 게임 안에서 실제 재생 — 데스크톱 (`tests/analysis/lead/sound_apply_capture.gd` + `check_capture.py` → `capture-check.json`, `capture/`)
실제 `AudioManager`로 재생하고 Master 버스를 `AudioEffectCapture`로 녹음했다. 헤드리스 Dummy 드라이버도 실시간으로 믹스하므로, 이 녹음은 게임 믹서가 낸 소리다(Music·SFX 페이더 포함, Master 페이더는 녹음 뒤에 걸림).

- **효과음 72종**은 `manager.play(id)`로 하나씩 재생했고, 모두 자기 파일 `res://assets/audio/sfx/<id>.ogg`가 재생됐다. 폴백은 없었다(`capture/capture.log`).
- **음악 5곡**은 `play_music`으로 재생했다. 모두 자기 파일, 가져온 리소스 loop 켜짐, 재생 중인 복사본 loop 켜짐, 길이가 마디 끝과 같다.
- **루프 이음새 녹음**: 끝 1초 전으로 옮겨 이음새를 넘겨 녹음했다. 5곡 모두 이음새 앞뒤 정렬 차가 0/0이다. 녹음 이득은 −4.4dB로 Music 페이더(60% = −4.44dB)와 같다. SNR은 32.5~40.1dB이고 AUD-02 기준을 통과했다. 들어 볼 파일: `capture/seam_music_<곡>.ogg`(각 약 2.3초, 1초쯤에 이음새).
- **봇 경기**(Main 장면, bots_only, seed 1001, 실시간):
  - 20초 녹음에서 16개 파일, 60초 녹음(55초 기록)에서 24개 파일이 실제로 재생됐다. 모두 자기 파일이고 폴백은 없었다.
  - 60초 녹음에서 `music_battle.ogg`가 2번 시작으로 잡혔다. 36초에서 처음으로 돈 것이다.
  - 들어 볼 파일: `capture/match_mix_output_20s.ogg`. Master 80%를 적용하고, 출력 장치처럼 ±1에서 자른 소리다.
- 효과음 녹음 음량은 "파일 + SFX 페이더"와 −1.92~+0.07dB 차이다. 짧은 소리는 50ms 창 위치에 따라 조금 낮게 잡힌다.
- **실제 시작 경로**(`tests/audio_startup_probe.gd`, 메인 장면을 인자로 주어 엔진이 게임과 같은 순서로 Main을 붙임): 관리자가 루트에 있고, `music_title.ogg`가 loop 켜진 채 재생 중(1.21초 지점)이며, Master가 받은 소리는 RMS −24.1dBFS(페이드인 포함)다. 고치기 전 코드로는 관리자가 없고 무음(−200dBFS)이었다(5장).

### 웹 빌드에서 실제 재생 (`web-check.json`)
이 브랜치 웹 빌드를 8062로 열고 내장 브라우저(Chromium)에서 웹 오디오에 훅을 건 뒤 확인했다.
- **재생 방식**: 웹은 Sample 방식이다. 모든 소리가 `AudioBufferSourceNode`로 나가고, 스트림 워클릿에는 무음만 갔다.
- **고친 빌드**: 타이틀 배경을 한 번 누르자 타이틀 음악이 시작됐다(38.4초, 2채널, 브라우저 48kHz로 변환). 메뉴를 위아래로 움직이면 ui_move(0.045초)가 두 번 재생됐다.
- **고치기 전 빌드**: 같은 조작에도 소리가 하나도 나가지 않았고, 콘솔에 `add_child` 실패 오류가 있었다.
- **웹 음악 반복**: 38.4초마다 같은 버퍼를 다시 시작했다. 다시 시작 간격으로 잰 틈은 25·3·16ms이고, 오디오 시계로 잰 틈은 10.7ms다.
  - 원인: Godot 웹 Sample 재생은 버퍼가 끝났다는 이벤트(`ended`)를 받고 나서 다시 시작한다. 데스크톱처럼 샘플 단위로 이어지지 않는다.
  - 대안: 음악 player만 스트림 재생으로 바꾸면 이음새가 정확해진다. 다만 스레드 없는 웹 빌드에서는 메인 스레드가 오디오를 믹스하므로 프레임이 끊길 때 음악이 끊길 위험이 있다. 지금은 바꾸지 않았다.

### 음량 균형 (`balance.py` → `balance.json`, 기본 설정 Master 80·음악 60·효과음 80)
음악 바닥(파일 RMS −18dBFS + 페이더 −4.44dB)은 −22.4dBFS다. 녹음에서는 −22.05dBFS였다. 효과음은 가장 큰 50ms RMS로 비교했다.

| 그룹 | 음악 위로 몇 dB |
|---|---|
| 선수(휘두름·적중·점프…) | +8.5 ~ +13.1 |
| 스킬·궁극기 | +9.8 ~ +12.6 |
| 몬스터 | +5.3 ~ +13.7 |
| 렐름 | +1.8 ~ +12.6 |
| 진행(소울·카드·결과·승리) | +4.3 ~ +9.7 |
| 메뉴·스토리 | −7.5 ~ +9.5 |

- 전투음은 음악보다 대략 9~13dB 위에 있어서 묻히지 않는다.
- 음악보다 작은 것: story_text −7.5dB, ui_move −3.5dB, story_advance −0.2dB. AUD-01 설계 목표(−28·−24·−23dBFS)대로 조용하게 만든 소리다. story_text는 RMS로는 음악 아래지만 피크는 약 +4dB 위다. **스토리 장면에서 잘 들리는지는 귀로 확인할 것.**

## 4. 발견 3: 효과음이 많이 겹치면 출력이 넘친다 (결정 필요)
- 60초 봇 경기 녹음(부동소수, 잘리기 전 값):
  - Master 페이더 뒤 기준으로 1.0을 넘은 프레임이 3,208개(0.13%)다.
  - 455번 끊겨 넘쳤고, 가장 긴 것은 136프레임(3.1ms)이다.
  - 최대값은 +10.1dBFS, 50ms RMS 최대는 +0.65dBFS(Master 전)다.
- 원인은 파일이 아니라 겹침이다. 효과음 하나하나는 피크 −1~−3dBFS로 만들어졌는데, 동시 재생은 최대 24개이고 Master에 리미터가 없다. 실제로 60초 동안 점프 54회, 착지 58회, 휘두름 51회, 피격 30회, 몬스터 피격 40회가 났다.
- 이번 작업에서는 코드도 기본값도 바꾸지 않았다.
- 선택지:
  - (가) Master에 `AudioEffectHardLimiter`를 둔다. 데스크톱에서는 가장 간단하다. 다만 웹 Sample 재생 경로(`index.js`)에는 gain 노드만 있고 효과 처리가 없어서 웹에서는 듣지 않는다.
  - (나) 동시에 재생 중인 효과음 수에 따라 새 소리의 음량을 낮춘다(`AudioManager.play`). 웹에서도 듣는다.
  - (다) 효과음 기본값이나 파일 음량을 낮춘다. 다만 넘침이 사라지려면 10dB 넘게 낮춰야 해서, 위 균형(전투음 +9~13dB)이 크게 줄어든다.
- 추천은 (나), 데스크톱에는 (가)도 함께다. 먼저 `capture/match_mix_output_20s.ogg`를 들어 보고 정하면 된다.

## 5. 고친 코드 (영역 밖: `scripts/audio/AudioManager.gd`)

### 발견 1: 게임을 켜면 소리가 전혀 나지 않았다 (`f7258fe0`)
- 증상: 게임을 켜면 `Main._ready → AudioManager.install → root.add_child`가 "Parent node is busy setting up children"으로 실패했다. 관리자가 없으니 데스크톱과 웹 모두 아무 소리도 나지 않았다.
- 드러나지 않은 이유: 파일이 없었고, 모든 테스트는 이미 준비된 루트에 Main을 붙여서 이 순서를 만나지 않았다.
- 원인: 게임 시작 때 엔진은 메인 장면을 루트보다 먼저 준비시키고, 그동안 루트는 add_child를 거부한다.
- 고침:
  - 루트가 아직 준비 전이면 관리자를 프레임 끝에 붙이고(`call_deferred`), 그 사이에는 `find()`가 이 관리자를 돌려준다(`_waiting`).
  - 그 사이 들어온 음악 요청은 `pending_music`에 두었다가 `_ready`에서(데스크톱) 또는 첫 입력에서(웹) 시작한다.
  - 같은 프레임의 효과음 요청은 버린다.
- 확인:
  - `test_audio`의 `_test_startup_path`가 `tests/audio_startup_probe.gd`를 하위 Godot로 실제 시작 순서대로 돌린다. 관리자가 루트에 있고, `music_title.ogg`가 반복 재생되며, Master RMS가 −40dBFS보다 커야 통과한다.
  - 고치기 전 코드로는 이 테스트가 add_child 오류와 무음으로 실패한다.
  - 웹에서도 고친 빌드만 소리가 난다(위 웹 확인).

### 발견 2: 종료 때 "resources still in use at exit" (`1d4e79c6`)
- 증상: 파일을 넣고 처음 돌린 run_all에서 7개 테스트가 실패했다(test_ultimates, test_match_rules, test_hazards, test_offscreen_markers, test_relocation_active, test_skill_bar, test_game_speed). 모두 종료 코드 0이었지만 끝에 `ERROR: N resources still in use at exit`가 찍혔다.
- 원인: 노드가 트리에서 빠질 때 Godot는 소리를 일시정지만 한다. 믹서 스레드는 멈춘 소리를 몇 버퍼 뒤에야 놓는다. 그 전에 엔진이 끝나면 재생 객체와 OGG 리소스가 남는다.
- 고침: `_exit_tree`에서 모든 voice·음악 player를 멈추고 한 번 150ms 기다린다(웹 제외).
- 확인: 실패했던 테스트들이 다시 깨끗이 통과했고, "ObjectDB instances leaked" 경고도 사라졌다. 이 수정을 되돌리면 test_audio·test_hazards에서 오류가 다시 난다.

## 6. 테스트

- 테스트 파일은 `tests/test_audio.gd`만 바꿨다(`run_all.ps1`은 그대로). 새 파일 `tests/audio_startup_probe.gd`는 run_all 목록에 넣지 않고 test_audio가 하위 프로세스로 돌린다.
  - 기존 훅·폴백 확인은 캐시를 "파일 없음"(null)으로 가린 채 돌린다. 예전 확인들이 원래 뜻 그대로 돈다.
  - 새로 넣은 `_test_adopted_files`(241개 확인): 77개 로드, 관리자가 폴백이 아닌 자기 파일을 고름, 음악 loop·정확한 길이, 효과음 loop 꺼짐, 훅 재생 경로, 음악 재생·전체 음량을 본다. 마지막에 전투 음악을 일부러 켜 둔 채 관리자를 해제해 종료 처리를 매번 거치게 한다.
  - 새로 넣은 `_test_startup_path`(4개 확인): 위 5장.
  - 고친 기존 확인: `_test_music`의 0.55초 고정 대기 4곳을 "페이드 트윈이 끝날 때까지(최대 3초)"로 바꿨다. PC 부하에서 6번 중 1번 "Music must reach full level" 실패를 재현했다(0.5초 트윈의 마지막 단계보다 타이머가 먼저 울리는 경쟁). 바꾼 뒤 단독 8회 연속 통과했다.
- test_audio: 858개 확인 통과(단독 3회 연속, 엔진 오류 줄 없음).
- run_all·소크(작업 폴더, 마지막 코드 `f7258fe0`): **ALL PASSED**.
  - 테스트 54개와 봇 소크 1회(seed 1001, 480초)가 모두 통과했다.
  - 소크: 경기 종료, 승자 Rio, NaN 위치 0, PvP 적중 689, 몬스터 적중 110, 위험 적중 10.
  - 시간 초과로 따로 다시 돌린 테스트는 없다.
  - 앞선 두 번: 파일만 넣은 첫 run_all에서 종료 오류로 7개가 실패했다(5장 발견 2). 종료 처리를 고친 뒤 두 번째 run_all은 ALL PASSED였다. 그 뒤 시작 처리(`f7258fe0`)를 고쳐서 마지막으로 다시 돌렸다.

## 7. 웹 빌드 크기

같은 PC, 같은 `tools/build_web.ps1`(5MiB 조각)로 만들었다. 이전 값은 게임 트리가 `8f75113c`와 같은 `4e776c87` 빌드다(`git diff 4e776c87 8f75113c -- smash-nine-prototype tools` 없음).

| | 이전 | 이후(`f7258fe0`) | 차이 |
|---|---:|---:|---:|
| `build/web` 전체 | 71,888,308 B | 74,600,440 B | +2,712,132 B |
| `index.pck`(조각 합) | 32,049,672 B | 34,761,804 B | +2,712,132 B |
| `index.wasm` | 39,509,339 B | 39,509,339 B | 0 |
| `SmashNine-web.zip` | 40,138,035 B | 42,400,077 B | +2,262,042 B |

pck 증가(2.71MB)는 OGG 합계 2.53MB에 Godot 가져오기 형식(`.oggvorbisstr`, 패킷 표)이 더해진 크기다.

## 8. 다시 만드는 방법

작업 폴더 루트에서(파이썬은 numpy가 있는 Codex 런타임, ffmpeg 9.0.2 full build):

```
python -I -B reports/apply-sound-2026-10-29/convert_audio.py <repo> <ffmpeg.exe>            # 변환 + manifest.json
godot --headless --path smash-nine-prototype --import                                       # 두 번; 음악 .import는 loop=true
godot --headless --path smash-nine-prototype -s tests/analysis/lead/sound_apply_decode.gd -- --out=<dir>
python -I -B reports/apply-sound-2026-10-29/verify_decode.py <repo> <dir>                   # decode-check.json
godot --headless --path smash-nine-prototype -s tests/analysis/lead/sound_apply_capture.gd -- --out=<cap> --match-seconds=20
godot --headless --path smash-nine-prototype -s tests/analysis/lead/sound_apply_capture.gd -- --out=<cap> --match-seconds=60 --match-only
python -I -B reports/apply-sound-2026-10-29/check_capture.py <repo> <cap>                   # capture-check.json
python -I -B reports/apply-sound-2026-10-29/balance.py <repo> <cap>                         # balance.json
godot --headless --path smash-nine-prototype -s tests/audio_startup_probe.gd res://scenes/Main.tscn
```

`capture/`의 OGG는 녹음 WAV·float를 ffmpeg로 줄인 것이다(경기 클립은 `volume=-1.94dB,aformat=s16`으로 Master 적용 후 ±1에서 자름). 녹음 원본 WAV와 float는 커서 커밋하지 않았다. 게임 녹음(`capture.json`)과 경기 녹음은 시작 처리 수정(`f7258fe0`) 전 코드로 했지만, 테스트 스크립트가 준비된 루트에 Main을 붙이는 경로라 그 수정과 관계없다.

## 9. 사람이 확인할 것

- `capture/match_mix_output_20s.ogg`: 전투 중 효과음 겹침 넘침(4장)과 음악·효과음 균형.
- `capture/seam_music_<곡>.ogg`: 1초쯤의 루프 이음새(데스크톱).
- 웹(8062)에서 음악이 한 바퀴 돌 때의 짧은 끊김(약 10~25ms)이 들리는지.
- 스토리 장면의 story_text(대사 한 줄마다 한 번)와 메뉴 ui_move가 음악에 묻히지 않는지.
