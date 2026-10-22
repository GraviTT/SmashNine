# CODEX-SYS-09 · Story dialogue expressions and shadow faces (wiring with fallback)

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 4: "대화창에 연결하는 코드까지 Codex가 쓴다".
- Candidates exist: expressions `art/bakeoff/<folder>/<stem>_face-{happy,angry,hurt}-v1.png` (ART-73, `reports/codex-art-73/README.md`) and shadow faces `art/bakeoff/<folder>/<stem>_face-shadow-v1.png` (ART-80). The user picks them in the motion viewer.
- **Goal: adopting a pick is a file copy.** Until files are copied the dialogue looks exactly as today. Do not copy any candidate into `assets/`.
- Unit: Builder (code). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/analyst/SmashNine`, branch `codex/sys-09` (from the latest main). **You are the only unit running Godot.** You write the product code; the lead reviews and merges.
- The story session is closed. This card may change `scripts/ui/StoryDialogue.gd` (the faces only) and add face tags to the line lists in `scripts/story/StoryCatalog.gd`; the story text, flow and saves do not change.

## Adoption (what the lead will copy later)
| Candidate | Copied to |
|---|---|
| `art/bakeoff/<folder>/<stem>_face-<expression>-v1.png` | `assets/art/<folder>/<stem>_face_<expression>.png` (`happy`, `angry`, `hurt`, `shadow`) |

Write this table into `assets/art/README.md` (create the section if needed).

## The code
1. `ArtSettings.character_portrait(id, body, expression := "")`: with an expression, use `<stem>_face_<expression>.png` when it exists, else today's face. Every current caller keeps today's result.
2. Lines may carry an optional face: the line lists already take an optional dictionary (`{"cg": "prologue"}`); add `{"face": "<expression>"}` the same way. `StoryDialogue` shows the speaking character (hero on the left, rival or shadow on the right) with that face; a line without a face shows the neutral face.
3. The shadow speaker: when `<stem>_face_shadow.png` exists, show it **without** the purple tint (the art is already the shadow); when it does not, today's tinted neutral. The dimming of the character who is not speaking stays.
4. **Face tags** for the hero and rival lines in `StoryCatalog._dialogue()`: read every line's text in `assets/i18n/story.csv` (Korean and English) and `design/STORY.md`, and pick `happy`, `angry`, `hurt` or none per line. Keep it sparing: a face only where the line clearly carries that feeling (a challenge → angry, a win → happy, the hero hearing their shadow → hurt, and so on). Put the full table (line id, speaker, Korean text, face, one-word reason) in the report so the user can review it.

## Tests
- `tests/test_story_faces.gd`, added to `tests/run_all.ps1`. Inject test textures in code (no candidate files):
  - a tagged hero line shows that expression; an untagged one the neutral face
  - the rival side the same, for a rival stage
  - the shadow line: the shadow face without tint when present; the tinted neutral when not
  - with no expression files at all, every line of stages 1–9 for all five heroes shows exactly today's texture and tint
  - every tag is one of `happy`, `angry`, `hurt`
- The existing story tests pass (`test_story_*`). The full suite once at the end; report its last lines.

## Output
- the code, the tags, the test, the `assets/art/README.md` section
- `reports/codex-sys-09/README.md` (Korean): what changed, the tag table, the tests, the full suite
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`, no logs over 1 MB

## Writable
`smash-nine-prototype/scripts/ArtSettings.gd` (`character_portrait`), `smash-nine-prototype/scripts/ui/StoryDialogue.gd` (the faces), `smash-nine-prototype/scripts/story/StoryCatalog.gd` (face tags in the line lists only), `smash-nine-prototype/tests/test_story_faces.gd`, `smash-nine-prototype/tests/run_all.ps1`, `smash-nine-prototype/assets/art/README.md`, `reports/codex-sys-09/**`.

Godot: `C:/Users/TH/Downloads/Godot_v4.7-stable_win64.exe/Godot_v4.7-stable_win64_console.exe`, headless only, `--import` first. Hard stop: 120 minutes.
