# CODEX-TOOL-01 · Game clips with effects on/off, and a speed preview, in the motion viewer

- Request: 사용자 2026-10-15 "일단 기본 공격부터 진행. 이펙트 볼수 있게 on/off 추가." … "모든 스프라이트와 공격 및 모션 속도가 너무 빠르다. 기본 자세 모션처럼 각자 조절이 필요할듯 싶다."
- Unit: branch `codex/tool-01`, clone `SmashNine-units/builder-ui/SmashNine`. An effect-art unit runs in `builder-art`; you share nothing.
- The motion viewer is `tools/motion_viewer/` (`build.mjs` builds `dist/`; read `tools/motion_viewer/README.md`). It plays sheet rows at their table fps. **In the game, move rows do not play at that fps.** `PlayerBase._play_sprite_pose` stretches frames first..last to reach the last one at 2/3 of the move's duration, so the viewer shows neither the effects nor the real speed.

## Part 1 · Capture real game clips (`smash-nine-prototype/tests/capture_move_clips.gd`, windowed, not headless)
- A plain arena: one fighter standing on a floor, no bots, no monsters, no hazards, original art on. A `Camera2D` frames the fighter so the clip shows the whole effect.
- For each form: `frey`, `luna`, `luna_brave` (Luna with `transformed = true`), `yuki`, `nova` (male), `rio` (male). Effects do not depend on the body.
- For each **basic attack** (J) variant the code has, from `design/SKILLS.md`: ground J (every chain hit in sequence), `↑J`, `↓J`, air `J`, air `↑J`, air `↓J`. For air moves, start in the air at a fixed height.
- Record from the press until the fighter is idle again (+0.15 s), at 30 fps, cropped to one fixed box per character. Capture twice:
  - **fx**: as the game draws it
  - **nofx**: the same with every effect hidden each frame: every node that is not the fighter's `CharacterSprite`, the floor or the camera, including effects the fighter parents to itself
  
  The fighter's motion must be identical in both. Use the same start state and seed.
- Turn the frames into lossless animated WebP with the real frame times (Python + Pillow, codex runtime), into `art/clips/<form>/<move>-fx.webp` and `<move>-nofx.webp`, at 1× pixel scale.
- Write `art/clips/manifest.json`, with one entry per clip: form, move, input, duration in seconds, frames, file names, and the sheet row(s) it plays.
- Document the run command in `tools/motion_viewer/README.md`. Rerunning it after any skill or effect change must refresh every clip.

## Part 2 · The viewer
- `build.mjs` reads `art/clips/manifest.json`, if present, and copies the clips into `dist/`.
- Each character gets a **게임 화면** section. It lists that form's clips with the move name, input and duration, plus one **이펙트 켬/끔** toggle (default 켬) that switches every clip between fx and nofx in step.
- **Speed preview** on the stage: a per-row slider ×0.5–×1.5 (step 0.05, default ×1) that scales the playback of the selected row.
  - Show the effective fps.
  - Add a **바뀐 속도** box that lists every changed row as text the user can copy, e.g. `frey walk ×0.80 (13.3 → 10.6 fps)`.
  - The settings may persist in `localStorage` (wrap in try/catch).
- Keep the viewer's look and layout. It must work at phone width.

## Checks
- Every clip pair has the same frame count and duration. The nofx clip shows no effect pixels: compare the fx and nofx frames around the fighter.
- The viewer builds; open `dist/index.html` locally (`node tools/serve_web.js tools/motion_viewer/dist 8073`, not 8071) and check the toggle, the slider and the copy box. Close the server when done.
- Godot opens a window for the capture; run it once at a time.
- The full Godot suite still passes (`tests/run_all.ps1`). The capture script is not part of the suite.

## Output
- `smash-nine-prototype/tests/capture_move_clips.gd`
- `art/clips/**`
- the `tools/motion_viewer/` changes
- `reports/codex-tool-01/README.md` (Korean, short: what each clip shows, the capture command, sizes)
- `reports/codex-tool-01/commit.ps1`: no `git add -f`, nothing under `art/raw/`, no `__pycache__`

## Writable
`smash-nine-prototype/tests/capture_move_clips.gd`, `art/clips/**`, `tools/motion_viewer/build.mjs`, `tools/motion_viewer/index.html`, `tools/motion_viewer/README.md`, `reports/codex-tool-01/**`. Do not commit `tools/motion_viewer/dist/`. Hard stop: 100 minutes.
