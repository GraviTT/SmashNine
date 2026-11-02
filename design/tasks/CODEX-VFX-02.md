# CODEX-VFX-02 · Brave Luna's skill icons J, K, L show what the moves do (candidates)

- Request: the user (2026-10-25, through the check session "게임 상태 점검 및 정리"): Codex usage was reset; spend it on image work that needs no user decision. Results stay **candidates** after the checkpoint (`checkpoint-2026-10-25`, `c51a417f`) and are checked and applied later.
- Why: the 24 HUD skill icons (CODEX-ART-18, 2026-10-08) are one consistent flat pixel style, and that style stays. But three Brave Luna icons show a wand and hearts, and Brave Luna fights with armoured gauntlets and kicks:
  - `luna_brave_j.png` shows a wand with a heart. The move is **Radiant Rush**: jab, body kick, spinning kick (`design/SKILLS.md`, Brave J rows).
  - `luna_brave_k.png` shows a heart in a ring. The move is **Comet Drive**: her body dashes in one of 8 directions as a compressed star and strikes.
  - `luna_brave_l.png` shows a pink crystal. The move is **Luna Breaker**: a big spinning finishing kick (on the ground forward, in the air diagonally down).
  - `luna_brave_i.png` (Heart Laser) fits. Leave it.
- Unit: Builder (images). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/vfx-b/SmashNine`, branch `codex/vfx-02` (from the checkpoint). Another image unit (VFX-01, Rio air step) runs at the same time in `vfx-a`; you share no files.

## Read first
- `smash-nine-prototype/assets/art/skill_icons/README.md` (the contract) and all 24 icons; `reports/codex-art-18/README.md` and its contact sheets (how the set was made and what each icon means); `tests/art_preview/skill_icons_18/`.
- `design/SKILLS.md`, the Brave Luna rows (J chain, K, L).
- Brave Luna's look (D36 in `design/DECISIONS.md`): high ponytail with a purple ribbon and gold stars, purple-gold armoured gauntlets to the forearm, star knee-armour boots. Sheets: `smash-nine-prototype/assets/art/luna/luna_brave_sheet.png` and `luna_brave_moves_sheet.png` (rows `brave_combo`, `comet_drive`, `luna_breaker`), and their README.

## Spec

| Item | Value |
| --- | --- |
| Canvas | 40×40 RGBA8, one static frame, transparent background |
| Placement | the mark centred on (20,20); the HUD draws the dark rounded 48×48 slot, key badge and cooldown shade (not in the file) |
| Style | the same as the other 23 icons: flat pixel clusters of 2 px or more, a 1-px dark navy outline, no anti-aliasing, no gradients, few colours |
| Colours | Brave Luna's purple, gold and pink, plus a light accent; the set must still read beside `luna_brave_i.png` |
| J | a gauntlet fist or a kick with a short burst: quick close blows (three-hit chain) |
| K | a small star-shaped body or fist leading a short, compressed comet streak (a body dash, not a projectile like Luna's K) |
| L | a big curved kick arc with a heavy impact star (a finisher) |
| Distinct | each of the three silhouettes differs from the others and from Frey's, Rio's and Nova's icons |
| Read | must read at 1× on the slot colour `#141824` and on light grey |
| Variants | 2 per icon (a, b), clearly different takes |

## Output
- `art/bakeoff/skill_icons/luna_brave/luna_brave_<j|k|l>-<a|b>-v1.png`, each with a `.json` `{"note": "<plain Korean>", "replaces": "smash-nine-prototype/assets/art/skill_icons/luna_brave_<slot>.png", "frames": 1, "fps": 0}`.
- `reports/codex-vfx-02/board.png`: the whole 6×4 icon set like ART-18's contact sheets (1× and 4×, slot colour and light grey), once with the current Brave row and once per candidate set (a, b), so the Brave row can be judged beside the others.
- `reports/codex-vfx-02/README.md` (Korean, short): what each candidate shows, measurements (size, colours, alpha, outline), what a human should judge.
- `reports/codex-vfx-02/prompts.txt` if you generate; raw files in `art/raw/vfx-02/` (git-ignored).
- `reports/codex-vfx-02/commit.ps1`: stage only your files and this card, no `git add -f`, nothing under `art/raw/`, no `__pycache__`.

## Writable
`art/bakeoff/skill_icons/luna_brave/**`, `art/raw/vfx-02/**`, `reports/codex-vfx-02/**`. Nothing under `smash-nine-prototype/` changes. Hard stop: 60 minutes.
