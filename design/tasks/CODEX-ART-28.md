# CODEX-ART-28 · Frey row touch-ups, per-character hit sparks, status icons over fighters

- Request: same run as CODEX-ART-23..27 (사용자 2026-10-10 "코덱스 한도 소모를 위해, 코덱스에 이미지, 스프라이트 생성 명령 내릴것."; "Claude는 명령과 검수만"). Follows CODEX-ART-23 (merged `c793a91`).
- Unit: Builder (images + wiring) · Clone `SmashNine-units/builder-art/SmashNine`, branch `codex/fx-28`
- Running at the same time: `codex/moves-26` (Nova/Yuki/Rio move sheets, art only) and `codex/monsters-ui-27` (MatchHud, monsters). You do not touch their files. Headless Godot only, unique `--log-file` per run.
- Read first: `reports/codex-art-23/README.md`, `characters/common/PlayerBase.gd` (`_spawn_hit_effect`, `_spawn_hit_slash`, the ultimate armor and hitstun code), `assets/art/effects/README.md`, `assets/art/ui/README.md` (status icons from ART-25 in `ui/status/`).

## 1. Frey move rows (lead review, required, short)
- `frey_moves_sheet.png` `descent` frame 3 still reads as a mass of hair and cape seen from behind, and `descent` 4–5 and `spike_followup` 4 are drawn visibly smaller than idle. Redraw those cells at the idle body size, face or sword direction visible. Keep edge_audit at 0 (`tests/art_preview/moves_23/edge_audit.gd`), feet/centre rules as before; before/after sheet.

## 2. Per-character hit sparks (required)
- One hit spark strip per attacker: `assets/art/effects/hit/<id>_hit.png` for frey, luna, luna_brave, nova, rio, yuki (same frame layout and size class as `effects/hit_spark.png`; colours and motif from each fighter's attack art in `assets/art/attack_vfx/`; no text). A strong-hit variant per fighter is welcome if time allows.
- Wire in `PlayerBase._spawn_hit_effect` (and `_spawn_hit_slash` if it helps): use the attacker's strip when it exists, else today's common `hit_spark`. Visual only. Test `tests/test_hit_sparks.gd` (art per attacker, fallback without; fails on the old code).

## 3. Status icons over fighters (required)
- Show the ART-25 icons above a fighter while the state lasts: super armor (ultimate armor timer), stun (hazard/quake stun or hitstun from a stun attack), shield break if such a state exists. Small (24 px art, drawn at the fighter's art scale), bobbing gently, never over the name/HP. Visual only, wired in `PlayerBase` (a helper node); fallback: nothing. Extend the test.

## Verify and report
- Contact sheets in `tests/art_preview/fx_28/`; `run_all.ps1 -SkipSoak` (or the same list with unique logs) passes apart from the known certificate line.
- Writable: `assets/art/frey/frey_moves_sheet.png` (+ README), `assets/art/effects/hit/**`, `assets/art/effects/README.md` (append), `characters/common/PlayerBase.gd` (hit effect + status icon code only), `tests/test_hit_sparks.gd`, `tests/art_preview/fx_28/**`, `reports/codex-art-28/**`. Keep image-gen originals named `*_source.png`.
- Hard stop 55 minutes after you start. Report `reports/codex-art-28/README.md` (Korean) + `commit.ps1` (writable paths only, message ending `Co-Authored-By: Codex <noreply@openai.com>`).
