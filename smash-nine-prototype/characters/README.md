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

전용 투사체나 설치물은 해당 캐릭터 폴더 안에 둔다. 원본 그림 파일은 `assets/characters/<id>/`에 유지하되, 그 참조는 캐릭터 스크립트가 소유한다.

## Character Document

캐릭터 문서에는 정체성과 목표 감각, 기본 스탯과 성장, J/K/L/I 조작, 핵심 전투 흐름, 강점과 약점, 현재 구현 범위, 다음 조정 항목을 기록한다. 수치는 플레이 검증에 따라 변경될 수 있다.
