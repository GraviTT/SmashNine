# CODEX-SYS-01 · Monster ecology: a behaviour per realm monster, elites, spawn pacing

- Request: 사용자 2026-10-22 (취침 루틴): "전체 몬스터와 맵, 맵 구조, 메인 화면과 결과 화면, 캐릭터 선택 창, 그 외 캐릭터와 관련되지 않은 요소들을 시스템적으로 강화 할 취침루틴을 실행해볼것. 일단 취침 루틴이니 루틴동안 나올 요소들은 자동 허가로 진행."
- Unit: Builder (code) · Lead: Claude (reviews, merges, measures)
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/sys-01`
- Read first: `scripts/RealmMonster.gd`, `scripts/RealmMonsterSpawner.gd`, `scripts/realms/RealmCatalog.gd` (each realm's `"monsters"` skins), `scripts/Main.gd` (`_create_realm_monster_spawner`, director phases), `scripts/match/MatchDirector.gd` (phase names and signals; read only), `scripts/EnemyAI.gd` (how bots pick and hit monsters; read only), `design/DECISIONS.md` D7 (monsters are soul sources, not the main threat), `assets/art/monsters/README.md`.
- Running at the same time: Codex unit `codex/sys-02` (title, character select, results screens in `scripts/ui/`) and the lead (realm hazards for Alfheim and Svartalfheim in `scripts/realms/RealmHazards.gd`). Do not edit those.
- Timeout: given in the prompt.

## Today

Every realm has two monster skins (`"monsters": {"melee": ..., "ranged": ...}`), but there are only two behaviours: `mossling` (walk and bite) and `ember_imp` (fireball). Eighteen skins, two ways to act. Four monsters per playable realm, refilled; no elites.

## Make

1. **One archetype per skin.** A small data-driven behaviour layer (new `scripts/monsters/` files are fine) with these archetypes, each with a visible wind-up (flash, glow or ground mark) before it hits:

| Archetype | What it does | Skins |
| --- | --- | --- |
| bite | today's mossling | mossling |
| charge | wind-up, then a straight rush along the floor; stops at ledges | asgard_aegis_ram, muspelheim_magma_boar |
| leap | hops onto the target in an arc | niflheim_glacier_wolf, alfheim_moon_stag, vanaheim_vine_hound (its hit roots: short `control_slow`) |
| slam | slow, telegraphed ground slam with a short shockwave on both sides | jotunheim_rune_golem, yggdrasil_root_guardian |
| shell | rolls at the target; takes half damage from the front while rolling | svartalfheim_gear_beetle |
| bolt | straight projectile (today's fireball) | ember_imp, niflheim_frost_owl (hit slows), jotunheim_storm_wisp |
| lob | arcing projectile | midgard_rooftop_slinger, vanaheim_seed_sprite (three-seed fan) |
| swoop | flies at a height, dives at the target, climbs back | asgard_runic_raven, svartalfheim_cog_drone (drops a bomb instead of diving) |
| blink | short teleport next to the target, then a small burst | alfheim_moon_moth |
| homing | slow orb that turns toward the target | yggdrasil_root_oracle |

   Keep D7: regular monsters never ring a fighter out by themselves (knockback no higher than today's 140/110 except elites), damage per hit 5–9.
2. **Elites (realm guardians).** At most one per playable realm at a time, first from the second match phase on, then every 70–90 s while none is alive. An elite is a bigger (×1.35) version of one of the realm's skins with ×3 HP, a gold crown/aura marker and name ("Elite Rune Golem"), uses its archetype with a longer telegraph and ×1.5 damage, knockback up to 320, and gives ×4 souls. Announce it once through the existing match message ("An elite Rune Golem rises in Jotunheim").
3. **Spawn pacing.** Keep four per realm while exploring; three once the central brawl starts (so fighters meet each other); a defeated slot refills after 12–18 s instead of at once. Read the phase through a provider the spawner is given (edit `Main._create_realm_monster_spawner` only for that), not by editing `MatchDirector`.
4. **Readability.** Monster HP bars show only after the first hit (and for elites always). A defeated monster plays its hurt frame, fades and drops a small soul burst at its feet.
5. **Bots keep working.** Do not change `EnemyAI.gd`. Keep every monster property and method it reads (`state`, `hp`, `is_realm_active`, `last_attacker`, `last_hit_frame`, `defeated` signal, ...). An elite counts as a monster for bots.

## Tests and checks

- New `tests/test_monster_ecology.gd` (add it to `tests/run_all.ps1` after `test_realm_monsters`): each archetype acts (a charge moves, a leap leaves the floor, a slam spawns its shockwave, a projectile archetype fires its projectile type, the moth blinks, the shell halves frontal damage while rolling), the wind-up comes before the hit, an elite spawns in the second phase with ×3 HP and ×4 souls, regular monster knockback never exceeds 140, refill waits 12–18 s.
- `tests/test_realm_monsters.gd` and the whole `tests/run_all.ps1` pass ("ALL PASSED"; the certificate-store ERROR is known noise). Run the soak seeds 1001–1003 before and after and report monster hits, defeats by monster, match length.
- In-game text in English.

Writable: `smash-nine-prototype/scripts/RealmMonster.gd`, `smash-nine-prototype/scripts/RealmMonsterSpawner.gd`, `smash-nine-prototype/scripts/monsters/**`, `smash-nine-prototype/scripts/realms/RealmCatalog.gd` (monster entries only), `smash-nine-prototype/scripts/Main.gd` (`_create_realm_monster_spawner` only), `smash-nine-prototype/tests/test_monster_ecology.gd`, `smash-nine-prototype/tests/run_all.ps1` (one entry), `reports/codex-sys-01/**`. Report `reports/codex-sys-01/README.md` (Korean): the archetype table as built, elite rules, the soak before/after, what is not done. Commit, or `reports/codex-sys-01/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
