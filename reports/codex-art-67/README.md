# CODEX-ART-67 결과

캐릭터 몸에 붙거나 주위를 도는 효과 20종을 새 스프라이트의 픽셀 밀도와 팔레트에 맞춘 `v1` 후보로 제작했다. 제품 경로는 건드리지 않았고 모든 결과는 `art/bakeoff/effects/` 후보와 비교판으로만 남겼다.

| 순서 | 대상 | 납품 파일 |
| --- | --- | --- |
| 1 | 공통 | `guard_bubble`, `parry_flash`, `status_stun`, `status_super_armor` |
| 2 | Frey | `frey_pursuit_mark`, `frey_spike_ring`, `frey_ult_charge` |
| 3 | Luna | `luna_star_charge`, `luna_brave_aura`, `luna_ult_transform` |
| 4 | Yuki | `yuki_seal_idle`, `yuki_seal_break`, `yuki_ult_seal` |
| 5 | Nova | `nova_momentum_trail`, `nova_shift_ready`, `nova_ult_core` |
| 6 | Rio | `rio_rune_guard`, `rio_ult_circle`, `rio_gem_sword` |

추가 조사에서 Luna의 몸 중심에 고정되는 `effects/skill/luna_moon_ring.png`도 같은 범위로 확인해 `luna_moon_ring-v1`을 함께 제작했다. `StatusIcon`이 실제로 쓰는 `ui/status/stun.png`, `super_armor.png`도 공통 후보에 포함했다.

## 확인

- 20종 모두 원본과 같은 RGBA 크기, 프레임 수, 셀 크기, 중심점과 재생 FPS를 유지했다.
- 알파는 전부 0/255, 외곽 1픽셀 투명, 모든 프레임 비어 있지 않음을 `verification.json`으로 확인했다.
- 각 비교판에서 현재/신규를 idle·busy 프레임에 1배·4배로 합성해 전 프레임과 함께 육안 확인했다. Nova와 Rio는 남녀 몸 모두 확인했다.
- 몸 앞에 그려지는 큰 효과는 중앙을 열린 형태로 정리했고, Yuki 궁극기·Nova 잔상·Rio 궁극기는 실제 코드의 뒤쪽 레이어 순서로 합성했다.
- Rio gem sword는 런타임 색조 변경을 위해 회색조 계약을 유지했다.

## 현재 제한

후보 아트만 납품했으므로 실제 게임 교체와 Godot 재생 검증은 하지 않았다. Luna 변신은 몸을 가리지 않도록 중앙 여백을 둔 만큼, 채택 전 실게임에서 그 여백의 인상이 자연스러운지 한 번 더 확인하는 편이 좋다.
