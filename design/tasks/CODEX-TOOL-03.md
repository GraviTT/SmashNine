# CODEX-TOOL-03 · Motion viewer: a pick button on every candidate, projectiles and portraits sections

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md` ("고를 거리가 많아짐 → 차례마다 한 화면에 모으고"). The user now has many candidates to pick: monster rows (ART-71, more coming), character motions (ART-72, more coming), defeat motions (ART-69), Rio v2 rows (ART-68), monster projectiles (ART-79) and dialogue portraits (ART-73). Today the user picks by telling the lead in chat.
- Unit: Builder (tool). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/tool-03` (from the latest main).
- Running at the same time: image units (ART-74, ART-75, ART-76, ART-77, ART-78) that will add more candidate files with the same naming; SYS-05 (sound wiring, Godot). You share no files. Do not run Godot.
- The viewer is published as a claude.ai Artifact: https://claude.ai/artifact/188Ryqb526Ue58MDf4BnbU. It already keeps adopted speeds in its database (collection `motion_speeds`). The lead republishes it; you only build and test locally.

## Read first
- `tools/motion_viewer/README.md`, `index.html`, `build.mjs`
- how the sound viewer stores picks: `tools/sound_viewer/index.html` (collection `sound_picks`) and its README
- the candidate files: `art/bakeoff/**/*-v<n>.png` + `.json` (fighter and monster rows), `art/bakeoff/monsters/*-projectile-v1.*`, `art/bakeoff/monsters/slam_shockwave-v1.*`, `art/bakeoff/<folder>/*_face-<expression>-v1.*`
- the reports that made them: `reports/codex-art-71/`, `reports/codex-art-72/`, `reports/codex-art-73/`, `reports/codex-art-79/`

## 1. A pick button on every candidate
- Every candidate shown (a fighter or monster row candidate, a projectile, a portrait) gets a **고르기** toggle and an optional short memo.
- Stored in the same database, collection `candidate_picks`, one document per candidate. Document id: `<kind>~<id>~<row>~<version>` (`kind`: `fighter`, `monster`, `projectile`, `face`). Fields: `kind`, `id`, `row`, `version`, `file` (the repo path, e.g. `art/bakeoff/monsters/mossling-idle-v1.png`), `picked` (true/false), `note`, `picked_at`.
- One subscription for the collection; one write per click. The page works without the database (shows the buttons disabled with a short Korean note).
- A **고른 것** panel at the top: every picked candidate in one list (kind, name, row, version, memo), so the user sees all choices at once. Unpicking removes it from the list.
- A candidate that is already in the game (its json says `adopted`) is not shown, as today.

## 2. New sections
- **몬스터 투사체**: each projectile strip playing at its `fps`, next to the old single image, at 1× and 3×; the shockwave too. Name in Korean (as in `reports/codex-art-79/`).
- **대화 초상화**: per form, the neutral face (the game's current one) and the three expression candidates side by side, at the dialogue size (142×164) and at full size on click.
- Existing sections, speeds and clips keep working exactly as before.

## 3. Checks
- `node tools/motion_viewer/build.mjs` builds; `dist/files.json` lists every new file; the build fails loudly if a listed file is missing.
- A Node check like `tools/sound_viewer/verify.mjs` (mock DOM, mock `claude.use("db")`; its result is `reports/codex-aud-01a/viewer-checks.json`): pick, unpick, memo, the panel, reload restores the state, the page without a database, the speeds still adopt.
- Artifact limits: one publish sends at most 255 files and 64 MB; one version holds at most 511 files and 256 MB, so the lead may publish in parts. Report the total size and file count. When `files.json` has more than 250 files or 60 MB, also write `files-1.json`, `files-2.json`, … each within those limits (sheets first).

## Output
- the changes in `tools/motion_viewer/`
- `tools/motion_viewer/README.md`: the pick collection, how the lead reads the picks (`ArtifactData list candidate_picks`), how to republish
- `reports/codex-tool-03/README.md` (Korean), the check script and its result
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no `run.log`, nothing in `dist/`

## Writable
`tools/motion_viewer/**` (not `dist/`), `reports/codex-tool-03/**`.

Hard stop: 120 minutes.
