# CODEX-ANALYST-03 · Review of the 2026-10-07 additions (Rio, body types, bushes, soul crystals)

- Request: 사용자 "Rio로 진행" and "더 오래 할수 있도록 아직 구현 안된 부분들을 더 추가하여 계획서를 작성" (2026-10-07, 근무 루틴 `routine/2026-10-07-work-2/`, 라운드 4). The value asked of this unit is **independent verification**: the lead wrote and tested all of this alone today.
- Unit: Analyst · Lead (fixes, decides): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/review-b`
- Running at the same time: Codex builder `codex/luna-brave-a` (image work, light). You may run headless matches; at most one Godot process at a time.
- Timeout: given in the prompt.

## Scope (the diff `3cf868d..HEAD`, product code only)

1. **Rio** (`characters/rio/Rio.gd`, `RioData.gd`, `Rio.md`, `design/CHARACTER-05.md` plan A): dimension slash teleport (`move_and_collide` test move, 200 px, once in the air), rune shield (PlayerBase hooks `character_hit_absorption` / `character_on_hit_absorbed` / `_finish_absorbed_hit`, `last_hit_absorbed`), gem-sword overdrive (aim, cancel on hit), air jumps (`base_air_jumps`, `MAX_AIR_JUMPS`).
2. **Body types** (`body_type`, `ArtSettings.original_character_sheet`, `Main._pick_body`, start screen V).
3. **Midgard bushes** (`RealmHazards` bushes, `PlayerBase.set_concealed`, `EnemyAI` notice range).
4. **Soul crystals** (`scripts/SoulCrystal.gd`, `SoulCrystalSpawner.gd`, `EnemyAI._find_target`).
5. Bot changes in `EnemyAI.gd` (Rio profile, recovery skill aim `aim_direction`, reactive skill 2).

## Questions

- Bugs: can the teleport put Rio inside terrain, past a blast line, or through a one-way platform from below into a stuck state? Do the absorb hooks leave any path (stun hit, forced launch, Yuki seal burst, environment damage, parry) inconsistent? Can concealment stay stuck on after a realm collapses, a respawn or a portal? Can crystals be broken by monsters, double-pay, or survive a collapse?
- Exploits and balance: rune shield vs. multi-hit moves and hazards; crystal farming; bush camping (by bots or a human); Rio's win share in bot matches (`tests/analysis/run_sweep.ps1` + `sweep_summary.ps1`, and `tests/analysis/duel_probe.gd -- --first=rio` = Rio vs Frey, `--first=nova` = Nova vs Rio). Note: Frey's strength is known and on hold by the user.
- For every finding: the owning component (Rule lives where? `AGENTS.md` "Code conventions") and whether the fix belongs there.

## Writable paths

| Path | For |
| --- | --- |
| `smash-nine-prototype/tests/analysis/review03/**` | probes, repro scripts |
| `reports/codex-analyst-03/**` | report, raw data |

Forbidden: product source, existing tests, `design/`, merging, pushing, installing packages, downloading files.

## Report (`reports/codex-analyst-03/README.md`, Korean)

- Findings table: severity (P0/P1/P2), component, repro (command + seed), measured vs. guessed, suggested fix and owner.
- What you checked and found fine.
- Commit, or `reports/codex-analyst-03/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
