# Xion 그림 브리프 (「이미지/스프라이트 담당」에게, 2026-11-18)

Xion(시온)은 게임에 들어가 있다(D51). 지금 그림은 임시다: Nova 여성체를 검정·은·진홍으로 다시 칠한 것(`smash-nine-prototype/assets/art/xion/`). 아래 그림이 오면 같은 이름의 파일을 바꾸기만 하면 된다.

## 캐릭터

- **이름:** Xion(시온). 여성, 성인. 체형은 여성체 하나(D22).
- **컨셉:** 건카타 총잡이. 플레이 스타일은 "중거리 견제와 암살"이다. 쌍산탄총으로 밀어내며 견제하다가, 그림자 같은 도플갱어가 적을 붙잡으면 붙어서 쏜다.
- **무기:** 양손에 **산탄총 한 자루씩**(쌍권총이 아니다). 짧은 총신, 굵은 총구.
- **외형 제안:**
  - 검은 롱코트에 은색 선. 총구 섬광과 포인트는 진홍.
  - 검정·은·진홍은 지금 로스터와 겹치지 않는다.
  - 머리·얼굴 둘레는 비운다(D48).
- **등신:** 3등신 제안(Frey·Rio와 같음, D25).
- **도플갱어:** 다른 시간선의 Xion이다(사용자 설정 2026-11-19). 따로 그리지 않는다. 게임에서는 Xion 그림을 진홍 홀로그램으로 바꿔 쓴다(단색, 반투명, 주사선).

## 필요한 것

| 파일 | 크기·형식 | 비고 |
|---|---|---|
| `xion_illustration.png` | 1024×1536 | 선택 화면 큰 그림 |
| `xion_face.png` | 256×256 | 메뉴·HUD 얼굴. 일러스트에서 잘라 낸다(CODEX-ART-08 방식) |
| `xion_sheet.png` | 128px 칸, 6열×8행(768×1024) | 줄: idle 6, walk 8(두 줄), jump 1, fall 1, attack 6, shield 6, hurt 1(`Xion.SHEET_ROWS`, Nova·Rio와 같은 틀). 발 y=120, 동작 6프레임 이상, 걷기 8프레임(D32~D35) |
| 선택: `xion_jump`·`xion_fall`·`xion_land`·`xion_victory`·`xion_defeat` | 공용 규칙(`OPTIONAL_MOTION_ROWS`) | 지금은 임시본이 있다 |

기술 동작 11줄(`xion_moves_sheet.png`, 192px 칸)과 이펙트·아이콘은 이 세션이 기본 시트가 온 뒤 Codex SKM·VFX로 만든다. 그다음 시안 월드컵(D49)에서 고른다.

## 볼 곳

- 키트: `design/SKILLS.md` Xion 절, `smash-nine-prototype/characters/xion/Xion.md`
- 임시 그림과 줄 이름: `smash-nine-prototype/assets/art/xion/README.md`
- 결정: `design/DECISIONS.md` D51
