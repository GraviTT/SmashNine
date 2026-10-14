# CODEX-ART-44 · Brave Luna: three design proposals (idle anchors) for the user to pick

- Request: 사용자 2026-10-14 "Luna 진행. Brave까지. 추가로, Luna가 궁극기를 사용할 때 변신하는 특별 모션이 있으면 좋겠다." The lead asked how Brave Luna should look, because today she wears Luna's outfit and only the gauntlets differ, so the transformation changes little. The user chose **"시안 3개 보고 고르기"**.
- Unit B: branch `codex/luna-44`, clone `SmashNine-units/builder-art/SmashNine`. Unit A (`CODEX-ART-43.md`: the new Luna anchor and the normal-form rows) runs at the same time in `builder-frey`. Never touch `luna-*` normal-form files.
- **Candidates only**; nothing in `smash-nine-prototype/` changes. Method D35, rules D32–D34.

## Three proposals, each a 6-frame idle (loop, 10.5 fps)
All three are the same girl as Luna:
- the same face, magenta eyes, pink hair colour, the purple bow with the gold star
- the palette family
- chibi proportions, 2.2 heads tall (D25)
- the same head size

No wand: Brave Luna fights with her fists and feet ("별빛을 주먹과 발에 압축", `Luna.md`). Gauntlets and boots are **worn armour**: armoured gloves up to the forearm and armoured boots or greaves, each with a star emblem. They are not stars held in the hands; ART-42's `luna_brave-idle-v2` read as two held white stars, which is what to avoid.

1. **`v3`, ① today's outfit + armour:** Luna's dress kept as it is, plus purple-and-gold armoured star gauntlets to the forearm and armoured boots with star knee guards. Light, bouncy fighting stance, fists up.
2. **`v4`, ② tied hair, short combat outfit:** the hair tied up into a high ponytail with the purple bow (the ponytail swings with the bounce). A short, sporty combat outfit in Luna's purples and white: sleeveless top, short skirt over shorts, a short scarf. Gauntlets and boots as ①. Fighting stance, fists up.
3. **`v5`, ③ gold-and-white starlight armour:** Luna's outfit plus gold-and-white armour pieces: a star chest plate, one shoulder guard, white-gold gauntlets and greaves, a short cape. The star clip becomes a small gold tiara-like crest. Fighting stance, fists up.

Idle pose lines (the same for all three): a light, bouncy fighting stance with feet planted and a small bounce.
1. guard
2. knees dip
3. lowest
4. rising
5. top, hair and ribbon lag
6. between 5 and 1

## How
- One generation per proposal (512-px cells, 3×2). A second only if the first fails the checks.
- Image 1 = the current `smash-nine-prototype/assets/art/luna/luna_sheet.png` idle frame 1 ×4 nearest (face, head ratio, detail).
- Image 2 = the current `luna_brave_sheet.png` idle frame 1 ×4 (stance only).
- Prompt structure and the detail style line as `reports/codex-art-37/idle/prompt.txt`. No effects: no glow halos, sparkles or auras; the gauntlets' stars are solid.
- `normalize.py --cell 128 --resample lanczos --sharpen 60 --despill auto --palette none --bg #00ff00`. One factor per proposal, chosen so that `head_scale.py --anchor smash-nine-prototype/assets/art/luna/luna_sheet.png:0` reads 0.96–1.04 (the same head as the current Luna and as the new Luna anchor unit A is making).
- Checks: head scale 0.96–1.04; border clear, 4 px margin; spill 0; detail ≥ 90; one face; two gauntlets; boots intact; look at every frame at 4×.

## Output
- `art/bakeoff/luna/luna_brave-idle-v3.png`, `-v4.png`, `-v5.png` (768×128).
- Each has a `.json` `{"note": "<시안 ①/②/③ 한 줄 설명, Korean>", "fps": 10.5, "frames": 6}`. The note is what the user reads in the viewer, so name the proposal first ("시안 ② 머리 묶음·짧은 전투복 …").
- Raw generations go to `art/raw/luna-44/` (git-ignored).
- `reports/codex-art-44/<v3|v4|v5>/`: `prompt.txt`, `compare.png` (4×, current Brave | proposal), `metrics.json`.
- `reports/codex-art-44/README.md` (Korean): the three side by side, with what each changes. Plus `commit.ps1` (no `git add -f`, nothing under `art/raw/`).

## Writable
`art/bakeoff/luna/luna_brave-idle-v3.*`, `-v4.*`, `-v5.*`, `art/raw/luna-44/**`, `reports/codex-art-44/**`. Hard stop 50 minutes.
