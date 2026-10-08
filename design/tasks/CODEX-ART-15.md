# CODEX-ART-15 · Realm backgrounds for the 1.5x realms

- Request: 사용자 2026-10-08 "그림이 어색해지는 것은 모두 Codex에게 맡기고, 퀄리티의 문제가 있어 보이는 것들도 스스로 판단하여 보강할것." (Realms were enlarged 1.5x today, user "맵 1.5배로".)
- Unit: Builder · Lead (integrates): Claude
- Clone: `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/tester/SmashNine`, branch `codex/realm-bg-c`
- Running at the same time: Codex builders `codex/fx-1x-b`, `codex/attack-vfx-2x-a`, Codex analyst (bots). **This task does not edit product source.**
- Timeout: given in the prompt.

## Why

Realms are 1.5x bigger now (`smash-nine-prototype/scripts/GameScale.gd`, WORLD 1.5, decision D27): outer realms 1920x1080, the centre (Yggdrasil Heart) 2880x1620. The painted backgrounds (`assets/art/realm_*/bg_far.png`, `bg_mid.png`, made by CODEX-ART-01/04 at 1280x720 and 1920x1080: a 640x360 / 960x540 pixel grid shown 2x) are stretched 1.5x with nearest filtering, so their pixel blocks are uneven (some 2 px, some 3 px) and they look smeared. The camera no longer shows the whole realm, so the background also has to hold up when only part of it is on screen.

## Deliverables

For each of the 9 realms, replace `bg_far.png` and `bg_mid.png`:

| Realm folder | New size | Pixel grid (shown 2x, nearest) |
| --- | --- | --- |
| `realm_asgard`, `realm_midgard`, `realm_niflheim`, `realm_alfheim`, `realm_muspelheim`, `realm_svartalfheim`, `realm_vanaheim`, `realm_jotunheim` | **1920x1080** | 960x540 |
| `realm_center` | **2880x1620** | 1440x810 |

Keep each realm's identity, palette, layering (opaque `bg_far`, transparent edge-only `bg_mid` with a large empty middle) and the quiet low-detail combat band (now roughly y = 225..975 on outer realms) so fighters and platforms read. Use the extra area for more scenery, not a stretched copy. Check against the platform layout at the new scale: `RealmCatalog.scaled_maps(1.5)` in `smash-nine-prototype/scripts/realms/RealmCatalog.gd` (read only) gives platform rects; render a preview with the platforms drawn on top. `platform_main.png` / `platform_sub.png` stay as they are. Update each folder's `README.md` (sizes, prompts).

Generate with your image tool; post-process with Godot's Image API (scripts under `smash-nine-prototype/tests/art_preview/realm_bg_c/`); do not install packages or download files. Big inspection images go under `reports/codex-art-15/`.

Order: centre first (most play time), then Asgard, Midgard, Niflheim, Alfheim, Muspelheim, Svartalfheim, Vanaheim, Jotunheim. Each finished realm is useful on its own.

## Writable paths

`smash-nine-prototype/assets/art/realm_*/bg_far.png`, `bg_mid.png`, `README.md`; `smash-nine-prototype/tests/art_preview/realm_bg_c/**`; `reports/codex-art-15/**`.

## Report (`reports/codex-art-15/README.md`, Korean)

Per realm: old (stretched, as the game shows it now) vs new with the platform layout drawn on top, at 50% size; what a human must judge; which realms were not finished. Commit, or `reports/codex-art-15/commit.ps1` staging only the writable paths, message ending `Co-Authored-By: Codex <noreply@openai.com>`.
