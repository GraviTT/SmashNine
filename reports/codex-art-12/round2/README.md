# CODEX-ART-12 Round 2 결과

## 완료 범위

요청된 공격 프레임 9개만 수정했다. 순서는 Rio female r4c0~r4c3, Frey r4c2~r4c3, Luna r4c3, Nova female r4c1~r4c2이다. 기존 몸체는 그대로 두고, 원본에서 잘린 부분을 수동 위치·색상 마스크로 이웃 포즈와 분리해 최근접 보간으로 합성했다.

| 프레임 | 측정된 문제와 처리 | 확대 전후 비교 |
|---|---|---|
| Rio female r4c0 | 원본 공격 행 위로 넘어간 검날/빛 조각을 밝은 은색·청색만 선별했다. 이전 행의 어두운 부츠는 제외했다. 결과 바운드 `(25,7) 73x114`, 여백 7px. | [3x 비교](before_after/rio_female_r4c0_before_after_3x.png) |
| Rio female r4c1 | 원본 x=238 왼쪽의 저명도 남색 머리카락·망토만 복원했다. 밝은 이웃 참격은 제외했다. 결과 `(9,34) 108x87`, 여백 7px. | [3x 비교](before_after/rio_female_r4c1_before_after_3x.png) |
| Rio female r4c2 | 원본 x=450 왼쪽의 저명도 남색 머리카락·망토만 복원했다. 결과 `(10,37) 110x84`, 여백 7px. | [3x 비교](before_after/rio_female_r4c2_before_after_3x.png) |
| Rio female r4c3 | 원본 x=661 왼쪽의 남색 망토/머리카락을 복원하고 이웃의 청색 참격은 제외했다. 결과 `(16,55) 108x66`, 여백 4px. | [3x 비교](before_after/rio_female_r4c3_before_after_3x.png) |
| Frey r4c2 | 누락된 수평 검과 청색 참격을 복원했다. 몸체/검 배율은 유지하고 셀을 넘는 참격만 폭 54px로 줄였다. 결과 `(26,34) 95x87`, 여백 7px. | [3x 비교](before_after/frey_r4c2_before_after_3x.png) |
| Frey r4c3 | 왼쪽 남색 망토와 오른쪽 아래 은색 검날을 따로 분리해 보충했다. 결과 `(27,30) 76x91`, 여백 7px. | [3x 비교](before_after/frey_r4c3_before_after_3x.png) |
| Luna r4c3 | 마지막 포즈 오른쪽의 완드와 분리된 별빛을 복원했다. 결과 `(29,42) 92x79`, 여백 7px. | [3x 비교](before_after/luna_r4c3_before_after_3x.png) |
| Nova female r4c1 | 오른쪽으로 이어지는 청록/금색 에너지 부분만 복원하고 다음 포즈의 어두운 몸체는 제외했다. 결과 `(22,42) 99x79`, 여백 7px. | [3x 비교](before_after/nova_female_r4c1_before_after_3x.png) |
| Nova female r4c2 | y=890 아래쪽의 포즈 2 청록/금색 에너지 꼬리만 왼쪽에 복원해 겹친 포즈 1의 팔을 제외했다. 결과 `(7,42) 116x79`, 여백 5px. | [3x 비교](before_after/nova_female_r4c2_before_after_3x.png) |

## 육안 판단

- Rio는 저명도 남색만 머리카락/망토로 판단했고, 밝은 청색은 이웃 참격으로 판단해 제외했다.
- Frey r4c2의 큰 청색 효과는 원본 비율 그대로면 셀을 넘으므로, 카드 지시대로 몸체가 아니라 효과만 축소했다.
- Luna r4c3 왼쪽 머리카락의 직선 경계는 [원본 접촉 구간 4x](inspection/luna_r4c2_c3_overlap_4x.png)에도 존재한다. 이웃 포즈의 보라색 참격을 섞지 않기 위해 그대로 유지했다.
- Nova r4c2는 두 포즈의 에너지 픽셀이 원본에서 실제로 접촉하므로, 아래쪽 에너지 꼬리만 해당 포즈로 판단했다.

공격 행 전체 크기/위치 비교:

- [Rio female 공격 행 2x](rows/rio_female_attack_after_2x.png)
- [Frey 공격 행 2x](rows/frey_attack_after_2x.png)
- [Luna 공격 행 2x](rows/luna_attack_after_2x.png)
- [Nova female 공격 행 2x](rows/nova_female_attack_after_2x.png)

## 검증

- `verify.gd`: **PASS** — 대상 9개 변경, 대상 외 159개 셀 픽셀 동일.
- 대상 9개: 이진 알파, 최소 4px 여백, 발 y=120 모두 통과.
- 대상 9개 모두 시작 시점의 불투명 픽셀을 0개 제거했고 기존 RGB를 전부 보존했다. 즉 몸체는 움직이거나 다시 그리지 않고 누락 픽셀만 추가했다.
- `frame_audit.gd`: Rio 대상 4개, Frey 대상 2개, Nova 대상 2개는 플래그 0.
- Luna r4c3은 `box_left` 하나가 남지만 위 확대 원본에서도 같은 직선 머리카락 경계가 확인된다. 새로 복원한 오른쪽 완드/별빛에는 `cut`, `box_right`, `margin` 플래그가 없다.
- 감사 결과의 나머지 플래그는 이번 대상이 아닌 기존 프레임이다.
- `tests/test_sprite_frames.gd`: **PASS** — 8개 시트, 184개 프레임. 기존 `KNOWN_CUT` 중 Rio 4개, Frey r4c3, Nova female 2개는 이제 잘림으로 판정되지 않는다는 안내가 출력됐다. 기존 테스트 수정은 금지 범위라 목록 자체는 변경하지 않았다.
- `apply_fixes.gd` 재실행 전후 4개 시트의 SHA-256이 모두 동일해 결정적 재생성을 확인했다.
- 모든 Godot 실행에서 알려진 샌드박스 인증서 저장소 오류 한 줄만 발생했고, 그 외 `SCRIPT ERROR`, `Parse Error`, `ERROR`는 최종 실행에 없었다.

세부 자료: [verification.txt](verification.txt), [target_measurements.csv](target_measurements.csv), [frame_audit.csv](audit/frame_audit.csv), [적용 로그](apply_log.txt).

## 사람이 최종 판단할 항목

1. Rio r4c0의 위쪽 검빛/입자 모양이 의도한 공격 궤적으로 읽히는지.
2. Frey r4c2에서 셀에 맞게 축소한 청색 참격이 충분히 강하게 보이는지.
3. Luna r4c3의 원본 자체 왼쪽 머리카락 직선 경계를 허용할지.
4. Nova r4c1~r4c2의 접촉한 청록 에너지 흐름이 연속 동작으로 자연스러운지.

## 미완료

요청된 9개 프레임 중 미완료 프레임은 없다.
