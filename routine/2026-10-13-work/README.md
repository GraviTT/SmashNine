# 근무 루틴 · 2026-10-13 · SmashNine — 전체 캐릭터 점검

## 지금 상태 (14:18 갱신)
- 단계: 실행 · 마무리 시작 15:38 · 기준 마감 16:08 · 최대 마감 17:08
- 지금: Codex A 3라운드(Frey attack-v2, Yuki), Codex B(Rio 여 → Nova 남·여 → Brave → Luna)
- 완료: 방법 분석, 공통 정리 도구·뷰어 후보 비교, 전체 점검(476프레임), Frey 후보 6줄(대기·walk·rising_cleave·spike·descent·tumble) + attack-v1 — 뷰어에 올림
- 막힌 것: 없음

## 사용자 지시 (원문)
> @"C:\Users\TH\Documents\AI\GameProject\CuSurvive\docs\sprite-motion-guide.md"
> 이 내용을 확인하여, 다른 게임 작업에서 효과적으로 적용중인 스프라이트 제작 방법을 분석하라.
>
> 그리고 다시 전체 캐릭터 점검을 위한 루틴에 들어간다.

"루틴에 들어간다"를 시작 지시로 받아 제안서는 아래에 남기고 13:08에 시작했다(기본 규칙: 승인 없이 시작하라는 말이 승인).

## 제안서 (시작 13:08)
| 항목 | 내용 |
| --- | --- |
| 모드·시간 | 근무(화 13:06). 기준 3시간 · 최대 4시간. 마무리 시작 15:38 · 기준 마감 16:08 · 최대 마감 17:08. Codex 15:23까지 |
| 실행 방식 | Codex 2개(기본 카드). 리드는 카드·검수·병합·기록(사용자 10-10 "Claude는 명령과 검수만") |
| 목표 | 모든 캐릭터(8체형)의 모든 동작을 D32와 CuSurvive 방식으로 점검하고, 가장 문제인 동작을 새 방식으로 다시 그린 **후보**를 뷰어에 "지금 vs 후보"로 올린다. 게임 시트 교체는 사용자가 뷰어에서 고른 뒤 |
| 변경 반영 | 작업마다 커밋, 커밋마다 `main` push |

| # | 작업 | 담당 | 예상 | 우선 | 완료 기준 · 검증 |
| --- | --- | --- | --- | --- | --- |
| 0 | 방법 분석 문서, 카드 2장, 회차 기록 | Claude | 20분 | 필수 | 커밋 |
| 1 | 공통 정리 도구 `tools/sprite_pipeline/`(CuSurvive `normalize.py`를 SmashNine 계약으로: 128칸·6열·발 y=120·배율 하나·팔레트·이진 알파·D32 ①·비교판) + 뷰어 "지금 vs 후보" | Codex A `ART-35` | ~70분 | 필수 | 합성 시험, 실제 생성본 3개 비교판, 리드가 결과·코드 확인 |
| 2 | 전체 점검: 8체형 × 기본 7줄 + 기술 줄, 모든 칸 2배 육안 + 수치, 줄마다 좋음/손질/다시 그림, 다시 그릴 12줄 우선순위와 칸별 자세 | Codex B `QA-18` | ~65분 | 필수 | 리드가 표본 3~4줄 직접 대조 |
| 3 | 우선순위 줄 다시 그리기 후보(한 동작 = 한 생성, CuSurvive 프롬프트 구조, 효과 없이, 1번 도구로 정리) | Codex A·B `ART-36a/b` | ~60분 | 필수 | 리드가 모든 칸 2~3배 육안(얼굴 하나·크기·다리), 빌더에 붙여 넣기 코드 없음 |
| 4 | 후보를 뷰어에 올림(같은 주소), 검수 기록 | Claude | 20분 | 필수 | 뷰어 게시 |
| 5 | 마무리: 기록·로드맵·AGENTS·회차 표, 보고와 배포 요청문 | Claude | 30분 | 필수 | 전체 검사 |

남는 시간 작업: 점검 결과의 "손질" 줄 중 규칙 위반(테두리·떨어진 픽셀)만 바로잡는 후보, 다음 회차 카드 초안.

자동화하지 않는 것: 후보 채택(사용자, 뷰어에서), 게임 시트 교체(채택 뒤), 사이트 재배포(사용자, 보고 끝 요청문).

적용 규칙
- 기본 카드 그대로(Codex 동시 2개).
- 프로젝트 카드 `routine/README.md`. **이번 회차만:** 캐릭터 동작 그림은 후보만 만들고 게임 시트를 바꾸지 않는다(사용자 판정 뒤 — CuSurvive 방식, B3 취향). 후보는 Godot 프로젝트 밖 `art/bakeoff/`.
- D32 ③(효과)은 "게임이 따로 그려 합친다"로: 기술 시트에는 캐릭터만 그린다(효과는 게임의 `attack_vfx`·`effects`).
- D32 ②(머리)는 시트 전체 배율 하나로 지키고 리드가 눈으로 확인한다(칸마다 머리를 재서 배율을 바꾸지 않는다).
- 건드리지 않을 곳: 제품 코드, 게임 시트, 경기 규칙. CuSurvive 저장소는 읽기만. 웹 조사·다운로드 없음.

판단: Claude가 정함 — 다시 그릴 줄 선택(점검 결과 기준), 후보 검수 통과 여부. 사용자에게 남김 — 후보 채택, D32 ③ 해석 확인, "후보 → 판정 → 게임" 순서를 프로젝트 규칙으로 할지.

## 기록 (시간순)
- 13:06 호출. 13:08 시작(시계). CuSurvive 지침과 정리 도구 README 읽음, 분석 문서 작성.
- 13:15 커밋 `aae3495` push(분석 문서, 카드 ART-35 · QA-18, 지시문 `CODEX-2026-10-13.prompt.md`). 클론: builder-art `codex/pipeline-35`, analyst `codex/inspect-18`(옛 클론의 추적 안 된 파일과 충돌해 강제 전환). 13:16 Codex A(ART-35, high, 75분)·B(QA-18, high, 70분) 실행.
- 13:23 Codex A(ART-35) 끝(7분, CuSurvive 도구 이식): `tools/sprite_pipeline/`(normalize·prepare_raw·make_palette·시험 3, 8체형 팔레트), 뷰어 "지금 vs 후보"(같은 프레임 번호·배율·가이드로 나란히, 타일에 "후보 N"), 예시 후보 `art/bakeoff/luna/luna-walk-v1.png`. 리드 검수: `normalize.py`의 배율 코드 직접 확인 — 시트 전체에 배율 하나(`fixed:`/`height:`), 칸에 안 들어가면 줄이지 않고 "다시 생성" 오류로 멈춤, 머리 배율 없음. 로컬 브라우저에서 Luna walk 후보 비교 화면 확인(콘솔 오류 0). 병합 `5f83693`.
- 13:25 Codex A 2차(ART-36 A, xhigh, 80분): Frey 기준 대기(새로 그려 배율 정하기) → spike_followup · descent · tumble 후보, 남으면 walk · attack. B 점검 결과를 기다리지 않고 사용자가 이미 지적한 줄부터.
- 13:29 Codex B(QA-18) 끝(13분): 16장 119줄 476프레임, 1px 빈 테두리 476/476, 4px 여백 실패 1(Frey descent F4), Rio 기본 시트 반투명 픽셀(idle·jump·fall·hurt 줄의 원본 부드러운 가장자리). 줄마다 판정과 다시 그릴 12줄. 핵심: **ART-34 새 걷기가 대기보다 작아 대기→걷기에서 몸이 줄어듦**(Frey 높이 82~96 vs 대기 100, Rio 여 −47%) — 칸마다 머리에 맞춘 배율 때문(CuSurvive가 경고한 함정). Frey spike_followup은 "손질", tumble "좋음". 리드 검수: Rio 여 기술 시트 2배 접촉판 직접 대조 — air_slash F4(작은 몸 + 떨어진 머리카락 조각), plunge F5(조각), low_sweep 크기, dimension_slash F3 번진 실루엣, infinity_overdrive에 효과(보석검)가 그려져 있음 — 보고와 일치. 병합 `fcaaa7f`.
- 13:30 A는 이미 Frey 기준 대기를 만든 상태라 다시 시작하지 않음(Frey 우선 줄 walk·rising_cleave·attack은 다음 A 라운드). 카드 B 파트 = 점검 우선순위(Rio 여 walk·air_slash·plunge → Nova 남·여 vector_side → Brave combo → Luna attack·Yuki talisman_side), 커밋 `33ef62e`. 13:31 Codex B(ART-36 B, xhigh, 105분) 실행.
- 13:45 Codex A(ART-36 A 1차) 끝(20분): Frey 기준 대기(높이 100 기준 배율 0.1876) + spike_followup · descent · tumble 후보. 리드 검수(overview 2배): 기준 대기는 지금 대기와 생김새·크기 같음(채택해 기준으로), spike는 동작·크기 좋고 떨어진 점만 지우면 됨, descent · tumble은 몸 전체가 기준의 약 80% — **생성할 때마다 그린 크기가 달라 기준 배율을 그대로 쓰면 안 됨**. 시트마다 배율 하나를 얼굴이 가장 잘 보이는 칸의 머리를 기준 대기에 맞춰 정하게 함(칸마다 아님). 병합 `7c78d80`(보고서 22MB, 원본 생성 그림 포함 — 다시 정리할 때 필요). 파이프라인 예시였던 Luna walk 후보는 지금 걷기를 다시 정리한 사본이라 지움.
- 13:47 Codex A 2라운드(xhigh, 90분): descent · tumble 시트 배율 다시, spike 점 제거(`--min-component` 추가), 새 후보 Frey walk · rising_cleave · attack. 13:47 뷰어 갱신(Frey 후보 4개).
- 14:16 Codex A 2라운드 끝(29분): spike_followup-v2(`--min-component 21`로 점 제거, 도구에 옵션 추가·시험 4/4), descent-v2·tumble-v2(시트 배율 0.235 — 얼굴이 가장 잘 보이는 칸의 머리를 기준 대기에 맞춤), 새 walk-v1(`height:100`, 0.266)·rising_cleave-v1(0.27)·attack-v1(0.219). 리드 검수(overview 2배, 모든 칸): 모든 칸 얼굴 하나, 머리 크기 기준 대기와 같음, descent·tumble 크기 바로잡힘, walk는 대기 크기 그대로 다리 교대(대기→걷기 축소 없음), rising_cleave 상승감 있음, attack-v1은 J3가 넓은 베기가 아니라 높이 든 자세라 약함. 병합 `45399ab`. 대체된 v1 3개(spike·descent·tumble)는 후보에서 뺌. 14:17 A 3라운드(attack-v2 수평 J3 + Yuki 기준 대기·talisman_side, 65분). 뷰어 갱신(Frey 후보 7개).
- 14:22 Codex B(ART-36 B 1차) 끝(51분): Rio 여 idle·walk·plunge, Nova 남·여 idle·vector_side, Brave idle·brave_combo 후보 9개(41프레임). Rio air_slash는 두 번 생성 모두 칸에 안 들어가 제외. Brave는 공용 팔레트가 보라·청록을 잃어 지금 시트에서 뽑은 96색 팔레트를 씀. 리드 검수: B의 검수판이 축소돼 있어 직접 2배 비교판(지금 대기 + 후보)을 만들어 모든 칸 확인 — 기준 대기 4개(Rio 여·Nova 남·여·Brave)는 지금 대기와 크기·생김새 같음, Nova vector_side 둘 다 좋음(Nova 여는 발밑 점), **Rio walk·Brave combo는 머리가 기준의 약 85%, Rio plunge는 약 70%**로 작음, 얼굴은 모두 하나. 병합 `f58334a`(보고서 41MB — 원본 생성 그림, 다음엔 줄이게 함).
- 14:24 Codex B 2라운드(xhigh, 57분): walk·plunge·combo 시트 배율 다시(머리를 기준에 맞춘 시트 배율 하나), Nova 여 점 제거, Rio air_slash 재시도, 남으면 Luna 기준 대기 + attack.
- 14:33 Codex A 3라운드 끝(16분): Frey attack-v2, Yuki idle-v1·talisman_side-v1. 리드 검수(직접 2배 비교판): Yuki 기준 대기는 지금 대기와 같은 크기(기준으로 채택), talisman_side는 동작 좋으나 머리 약 85%, **Frey attack-v2는 생성 그림에서 칼끝이 옆 칸으로 넘어가 잘린 조각이 남고 몸도 작음**(정리 도구가 생성 단계의 칸 넘침을 못 잡음). 병합 `e584991`. 14:35 A 4라운드(45분): 도구에 생성 칸 넘침 검사, Frey attack-v3 다시 생성, Yuki talisman 배율 다시.
- 14:44 Codex B 2라운드 끝(20분): Rio 여 walk-v2·air_slash-v2(조밀한 자세로 다시 생성, 칸에 들어감)·plunge-v2(다시 생성), Brave combo-v2, Nova 여 vector_side-v2(점 35px 제거), Luna idle-v1(기준)·attack-v1. 리드 검수(직접 2배 비교판, 기준 대기 옆): 크기를 다시 맞춘 줄 모두 기준과 머리 크기 같음, plunge-v2 F3~F5는 4배로 확대해 얼굴 하나씩 확인(숙인 머리가 겹쳐 보였던 것), Brave combo F3 오른쪽 여백 3px(1px 테두리 규칙은 통과). 병합 `66334f8`, 대체된 v1 4개 뺌.
- 14:45 점검의 "다시 그림" 6줄(Frey walk·rising_cleave·descent, Rio 여 walk·air_slash·plunge)은 모두 후보가 나옴. 나머지 "손질" 판정 대부분은 이펙트가 캐릭터 그림에 박힌 것(효과 분리 필요) — 다음 회차 몫. B 3라운드(30분): Nova 남 jump·fall·shield를 이펙트 없이.

## 결과
| 작업 | 만든 것 | 확인 · 커밋 |
| --- | --- | --- |
| 방법 분석 | `reports/sprite-method-analysis-2026-10-13.md` — CuSurvive의 "한 동작 = 한 생성 + 시트 전체에 같은 정리 + 뷰어 판정 뒤 게임" 방식과 SmashNine 실패 원인 대조, 적용 목록 | `aae3495` |
| ART-35 정리 도구 | `tools/sprite_pipeline/`(normalize: 128칸·6열·발 y=120·공중 높이 보존·시트 배율 하나·팔레트·이진 알파·1px 테두리·4px 여백 보고·**칸에 안 들어가면 줄이지 않고 실패**·생성 칸 넘침 실패·`--min-component`; prepare_raw; make_palette 8체형; 시험 5/5) + 뷰어 "지금 vs 후보" | 리드가 배율 코드·실패 동작 확인, 로컬 브라우저 확인. `5f83693`, `6b1a499` |
| QA-18 전체 점검 | 8체형 16장 119줄 476프레임, 줄마다 판정, 다시 그림 6줄 · 손질 대부분은 이펙트가 그림에 박힘, Rio 기본 시트 반투명 가장자리, ART-34 걷기의 대기→걷기 축소 | 리드가 Rio 여 기술 시트로 대조(일치). `fcaaa7f` |
| ART-36 후보 | `art/bakeoff/` — 캐릭터마다 새 기준 대기(Frey · Rio 여 · Nova 남·여 · Brave · Luna · Yuki) + Frey walk · rising_cleave · spike_followup · descent · tumble · attack, Rio 여 walk · air_slash · plunge, Nova 남·여 vector_side, Brave combo, Luna attack, Yuki talisman_side, Nova 남 jump · fall · shield(이펙트 없이) | 리드가 모든 칸을 2배(필요하면 4배)로 직접 확인 — 얼굴 하나, 기준 대기와 같은 머리 크기, 칼·팔다리 온전. 크기가 작은 후보 7번, 칼 잘림 1번, 점 2번을 되돌려 고침. 게임 시트는 그대로 |

## 이번 결정
- **"루틴에 들어간다"를 시작 지시로** 받아 제안서는 기록에만 두고 시작(기본 규칙: 승인 없이 시작하라는 말이 승인).
- **후보만, 게임 시트는 그대로**(이번 회차 규칙): 그림 느낌은 사용자 몫이고, 지난 주 바로 넣은 그림이 문제를 일으켰음(머리 두 개, 걷기 축소).
- **D32 ②를 "시트 배율 하나"로**: 기준 대기 배율을 그대로 쓰면 생성마다 그린 크기가 달라 작아짐(descent·tumble·Rio walk·Brave combo 약 70~85%) → 시트마다 배율 하나를, 얼굴이 가장 잘 보이는 칸의 머리를 기준 대기에 맞춰 정함(칸마다 아님). 칸마다 머리를 재는 방식은 쓰지 않음(ART-33·34·CuSurvive 모두 실패).
- **D32 ③을 "게임이 따로 그린다"로**: 후보에는 이펙트를 그리지 않음(기술 이펙트 그림은 게임에 이미 있음).
- **점검을 기다리지 않고 Frey부터**(A): 사용자가 이미 지적한 줄이라 먼저 시작해 Codex를 쉬게 하지 않음.
- **대체된 후보는 뺌**(v1 → v2·v3, git 기록에는 남음): 뷰어에서 지금 그림과 가장 나은 후보만 비교하게.
- **Rio 기본 시트의 반투명 가장자리는 손대지 않음**: 원본 v2 그림의 부드러운 경계라 보기에는 문제없고, 하드 알파로 바꾸면 거칠어질 수 있어 사람 판단.
- 리드가 Codex 숫자 대신 **직접 2배 비교판**(지금 대기 또는 새 기준 대기 + 후보)을 만들어 검수 — B 검수판이 축소돼 있어 얼굴을 볼 수 없었음.

## 남은 것
- 점검 "손질" 줄 대부분(이펙트가 그림에 박힌 Luna·Brave·Nova·Yuki 기술 줄, 방어 줄) — 이펙트 없이 다시 그리기. Rio 남(기준 대기부터), 몬스터 18종 점검.
- 채택된 후보를 게임에 넣는 작업(사용자 채택 뒤): 바뀌는 줄만 교체·나머지 줄 그대로, 기본 시트 4px 여백(Brave combo F3·Frey attack-v3 F3은 1~3px — 기술 시트로 갈 때는 1px 규칙만), 기준 대기와 지금 대기 중 무엇을 쓸지.
- 보고서 용량: 이번 회차 `reports/codex-art-36a`·`36b`가 원본 생성 그림 포함 약 100MB — 다음부터 원본은 git 밖(`work/` 같은 무시 폴더)에 두게 지시문에 넣을 것.
- Rio 기본 시트 반투명 가장자리(idle·jump·fall·hurt) — 하드 알파로 맞출지 사람 판단.

## 돌아와서 할 일
- **모션 뷰어에서 후보 고르기**: https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU — "후보 N" 배지가 붙은 줄을 누르면 지금 그림과 후보가 나란히 재생됨. 캐릭터마다 새 `idle`(기준 대기)도 후보. 채택할 줄을 알려 주시면 그 줄만 게임 시트에 넣음.
- **정할 것**: ① "후보 → 뷰어 판정 → 게임" 순서를 프로젝트 규칙으로 할지, ② D32 ③을 "게임이 따로 그린다"로 확정할지(그러면 손질 줄의 박힌 이펙트를 다음 회차에 빼고 다시 그림), ③ Rio 기본 시트 반투명 가장자리.
- **배포**: 보고 끝의 Codex 배포 요청문(이번 회차는 게임 시트 변경이 없지만, 지난 배포 뒤 게임이 많이 바뀌었음).
