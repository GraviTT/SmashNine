# Character Architecture

이 폴더는 Smash Nine Realms의 플레이어 캐릭터 구현과 설계 문서를 함께 관리한다.

## Folder Layout

```text
characters/
  CharacterRegistry.gd
  common/
    PlayerBase.gd
    CharacterAnimation.gd
  frey/
    Frey.gd
    Frey.tscn
    FreyData.gd
    Frey.md
  yuki/
    Yuki.gd
    Yuki.tscn
    YukiData.gd
    Yuki.md
    YukiTalisman.gd
    YukiSeal.gd
    YukiGrandWard.gd
```

`PlayerBase.gd`는 이동, 점프, 플랫폼 통과, 충돌, 방어와 패링, 피격, 히트스톱, 스탯, 레벨, 리스폰 등 모든 캐릭터가 공유하는 규칙만 담당한다.

각 캐릭터의 `.gd`는 J/K/L/I 기술, 전용 타이머와 상태, 전용 오브젝트, 애니메이션 프레임 구성을 담당한다. `.tscn`은 해당 캐릭터 스크립트를 가진 생성 진입점이며, `Data.gd`는 기본 스탯과 레벨 성장치를 제공한다.

## Adding A Character

1. 캐릭터 이름의 소문자 폴더를 만든다.
2. 기존 캐릭터를 참고해 `Name.gd`, `Name.tscn`, `NameData.gd`, `Name.md`를 만든다.
3. `Name.gd`가 `res://characters/common/PlayerBase.gd`를 상속하게 한다.
4. 필요한 `perform_basic_attack`, `perform_skill_one`, `perform_skill_two`, `perform_ultimate` 훅을 구현한다.
5. 전용 상태 정리가 필요하면 `character_on_hit`, `character_on_respawn`, `character_cleanup` 훅을 구현한다.
6. `configure_character_sprite`에서 해당 캐릭터의 애니메이션만 구성한다.
7. `CharacterRegistry.gd`에 씬과 데이터 한 항목을 등록한다.
8. 선택 입력이나 전용 UI가 필요할 때만 `Main.gd`를 수정한다.

원본 스프라이트(기본값, `design/DECISIONS.md` D22·D23)는 `assets/art/<id>/<id>_sheet.png` 또는 체형별 `<id>_male_sheet.png`·`<id>_female_sheet.png`(6×7; v1 64px 칸 2배, v2 128px 칸 1배 — 로더가 시트 폭으로 구분, D25). 메인 일러스트 `<id>[_<body>]_illustration.png`, 얼굴 초상화 `<id>[_<body>]_face.png`. `configure_character_sprite` 맨 앞에서 `_configure_original_sheet("<id>")`를 부르면 공통 규격으로 잘린다(프로토타입 아트는 2026-10-07 삭제). 캐릭터 데이터의 `bodies`에 체형 목록을 적는다(여성 캐릭터는 `["female"]`, 남성 캐릭터는 `["male", "female"]`).

**배율(D27, `scripts/GameScale.gd`):** 캐릭터 스크립트의 공격 수치(판정 크기, 몸 기준 위치, 투사체 크기·속도)는 예전 1배 기준으로 적는다. `_spawn_attack`·`_spawn_sweeping_*`·`_spawn_projectile`이 COMBAT(2배)를 한 번 곱하므로 다시 곱하지 않는다. 헬퍼를 거치지 않는 전용 공격 스크립트(폭발 반경, 결계, 레이저 등)는 거기서 `GAME_SCALE.COMBAT`를 곱한다. 복귀에 쓰는 이동 거리(순간이동, 돌진)는 WORLD, 상승·낙하 속도는 JUMP_SPEED를 곱한다. 근접 타격은 `<id>_slash` 아트를 자동으로 그리고(`attack_effect_name()`으로 바꿈), 전용 아트를 그리는 기술은 그동안 `attack_art_enabled = false`로 둔다.

전용 투사체나 설치물은 해당 캐릭터 폴더 안에 둔다. 원본 그림 파일은 `assets/characters/<id>/`에 유지하되, 그 참조는 캐릭터 스크립트가 소유한다.

## Character Document

캐릭터 문서에는 정체성과 목표 감각, 기본 스탯과 성장, J/K/L/I 조작, 핵심 전투 흐름, 강점과 약점, 현재 구현 범위, 다음 조정 항목을 기록한다. 수치는 플레이 검증에 따라 변경될 수 있다.

## Growth In A Match

레벨과 경험치는 소울로 대체되었다(`design/DECISIONS.md` D4, D16). 캐릭터 문서의 "Growth per Level"은 그대로 유효하며, 소울 카드를 한 번 고를 때마다 해당 성장치가 3레벨분 적용된다. 매치 규칙(피해 배율, 회복, 궁극기 쿨다운 30초)은 `scripts/match/MatchDirector.gd`와 `PlayerBase.gd`의 공통 필드가 담당하므로 캐릭터 스크립트에서 따로 다루지 않는다.
