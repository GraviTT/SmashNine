# CODEX-QA-12 · Independent review of the ultimate changes (routine 2026-10-08)

- Request: routine 2026-10-08 "캐릭터별 궁극기의 성능과 이펙트를 개선할것" and 사용자 "Codex를 적극 활용할것." The lead changed every ultimate tonight; this card is the second pair of eyes.
- Unit: Analyst · Lead (decides and fixes): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/builder-frey/SmashNine`, branch `codex/ult-review-12`
- **This task does not edit product source or existing tests.** It reads, measures, and reports.
- Timeout: given in the prompt.

## What changed (read these diffs: `git log --oneline 2a09dd8..HEAD`, then `git diff 2a09dd8..HEAD -- <file>`)

| Area | Files |
| --- | --- |
| Cast signal, ultimate window, 2.2x hitstop for hits in the window | `characters/common/PlayerBase.gd`, `characters/*/*Data.gd` (`ultimate_name`, `ultimate_window`) |
| Cut-in banner, white flash, screen shake | `scripts/ui/MatchHud.gd` (`show_ultimate_cutin`), `scripts/Main.gd` (`_on_ultimate_cast`, `ultimate_hit`) |
| Effect strips | `scripts/Vfx.gd`, `assets/art/vfx/*`, `scripts/Projectile.gd` (`impact_vfx`) |
| Frey · Valkyrie Descent | `characters/frey/Frey.gd`: waves 26 dmg reach 240, aftershock 10 after 0.28 s (await guarded by `action_epoch`) |
| Yuki · Grand Ward | `characters/yuki/YukiGrandWard.gd`: pulse 6, final 32, pull 240, seal art behind fighters |
| Luna · Brave Luna | `characters/luna/Luna.gd` (transform burst 14, radius 120), `LunaHeartLaser.gd` (3.4 per tick, tiled beam art) |
| Nova · Event Horizon | `characters/nova/Nova.gd`: burst 34–46, core pull 230 px / 240, **core collapse on launch** (radius 118, 18 dmg) |
| Rio · Infinity Overdrive | `characters/rio/Rio.gd`: swords 11, last sword 18 (knockback 520), circle art freed in `_clear_overdrive` |

Damage numbers are raw; the match scales fighter damage by 0.26 (`scripts/match/MatchDirector.gd`).

## Tasks

1. **Code review for bugs.** Look especially for: an await that resumes after the fighter was hit, defeated, respawned or the match restarted (Frey aftershock, Rio overdrive, Luna laser); effect nodes that never free (looping seal/core/circle sprites, beam TextureRect) when the caster dies mid-ultimate or the realm changes; Nova's collapse firing when the ultimate is cancelled; the ultimate window or 2.2x hitstop leaking into normal attacks (timer not cleared on death/respawn); hitstop stacking; the cut-in firing for fighters off screen; the plain style (F2) still drawing art. For each finding: file:line, a concrete reproduction (ideally a short headless script under your writable path that shows it), and a suggested fix (text only).
2. **Independent measurement.** Run `smash-nine-prototype/tests/analysis/lead/ult_probe.gd` on seeds the lead did not use (2001–2008; usage in its header; `--fixed-fps 60`, headless, one run at a time) and summarise with `tests/analysis/lead/ult_summary.js`. The lead's last numbers (seeds 1001–1007, damage per cast after the scale): Frey 10.2, Luna 11.5, Nova 10.0, Rio 11.1, Yuki 6.6 (before Yuki's latest bump). Say whether any ultimate is clearly off the ~12 target or clearly dominant (KO per cast, gain over normal play), and whether match length moved (soak: `tests/soak_test.gd` if present, else the probe's match time).
3. **Feel check from the captures** (optional, if time): `routine/2026-10-08-night/results/ultimates/*.png` — anything that reads badly (effect hiding fighters, unreadable timing).

## Writable paths

`reports/codex-qa-12/**`, `smash-nine-prototype/tests/analysis/codex_qa_12/**`. Everything else is read-only.

## Report (`reports/codex-qa-12/README.md`, Korean)

Findings ranked by severity (bug / balance / feel), each with evidence and a suggested fix; the measurement table next to the lead's; what you could not check. Commit, or `reports/codex-qa-12/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
