# CODEX-AUD-01a · Sound, trial batch: 12 core effects in 3 styles, and a listening page

- Request: 사용자 2026-10-22 "추천대로 시작해줘" — plan `reports/codex-quality-plan-2026-10-22.md`, track 1.
- The game is silent today: there are no sound files and no audio code.
- This trial decides the direction before about 60 effects and the music are made.
- Unit: Builder (sound + a page). Clone `C:/Users/TH/Documents/AI/GameProject/SmashNine-units/auditor/SmashNine`, branch `codex/aud-01a` (from the latest main).
- Running at the same time: ART-71 (monsters) in builder-art, ART-72 (character motions) in builder-frey. You share no files.
- **Original sound only.** Synthesize everything yourself with Python and numpy (`C:/Users/TH/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe`).
  - No downloads, no samples, no installs. This follows the project's original-art rule.
- **Candidates only.** Nothing under `smash-nine-prototype/` changes. Game wiring comes in a later card.
- **The lead (Claude) cannot hear.** Leave numbers and pictures that let it check your work: peak, RMS, length, and a waveform + spectrogram PNG per file. The user judges the sound itself.

## The twelve sounds

| Id | Sound | Length |
|---|---|---|
| `hit_light` | a quick J hit | 0.12–0.25 s |
| `hit_heavy` | a launcher or finisher hit | 0.25–0.45 s |
| `swing` | a sword or limb whoosh | 0.15–0.25 s |
| `jump` | a take-off | 0.12–0.2 s |
| `land` | feet on the floor | 0.08–0.15 s |
| `guard` | a hit on the guard | 0.15–0.25 s |
| `parry` | a perfect parry, bright | 0.25–0.4 s |
| `hurt` | the struck fighter's grunt-free impact body | 0.15–0.3 s |
| `ko` | a fighter knocked out | 0.6–0.9 s |
| `portal` | the Q portal | 0.8–1.2 s |
| `ui_select` | menu confirm | 0.05–0.12 s |
| `ui_cancel` | menu back | 0.05–0.12 s |

## Three styles (each sound in all three)
- **A, chiptune**: square, triangle and noise channels, NES/GB-like, crisp.
- **B, 16-bit**: FM-ish tones with a little pitch bend, SNES/Genesis-like, warmer.
- **C, layered arcade**: a noise transient, a pitched body and a short sub thump for weight.

It fits the pixel art, but hits must feel punchy.

## Format and checks
- WAV, 44.1 kHz, 16-bit, mono. Peak −1 dBFS, no clipping, silence trimmed (≤ 5 ms lead-in), a short fade-out with no click.
- Similar loudness across a set: RMS within ±3 dB for the same sound class. Measure it.
- Deterministic: one function per sound and style with its parameters, fixed seeds.
- Files: `art/audio_bakeoff/<id>-<style>.wav` (`<style>` is `a`, `b` or `c`).
- Measurements: `reports/codex-aud-01a/measurements.json` (peak dBFS, RMS dBFS, length, clipped samples). Pictures: `reports/codex-aud-01a/<id>-<style>.png`.

## The listening page
- `tools/sound_viewer/build.mjs` (Node, as `tools/motion_viewer/build.mjs`) writes `tools/sound_viewer/dist/index.html` plus the WAVs from `art/audio_bakeoff/`. `dist` is git-ignored; add it to `.gitignore`'s list only if it is not covered.
- The page:
  - one card per sound, with its three candidates side by side
  - a play button, length, and a one-line Korean note on what each style tries
  - a "전체 재생" button that plays the three in a row
  - dark theme like the motion viewer
  - works at phone width
- An **adopt button per sound**: the chosen style goes to the artifact database collection `sound_picks`, one document per sound id.
  - Copy the pattern of the motion viewer's speed adoption in `tools/motion_viewer/index.html`: `claude.use("db")`, `onSnapshot`. Hide the buttons when the database is missing.
  - Fields: `sound`, `style`, `note`, `adopted_at`.
- `tools/sound_viewer/README.md` (Korean): how to rebuild, how to republish (the lead publishes the Artifact), how the picks are read.

## Output
- `tools/audio_synth/` (the synth code and a README in Korean), the WAVs, the page source, the measurements and pictures.
- `reports/codex-aud-01a/README.md` (Korean): per style, what it is and how loud.
- `commit.ps1`: only your files, no `git add -f`, no `__pycache__`.

## Writable
`tools/audio_synth/**`, `tools/sound_viewer/**`, `art/audio_bakeoff/**`, `reports/codex-aud-01a/**`, `.gitignore` (one line for `tools/sound_viewer/dist/`, only if needed).

Hard stop: 120 minutes.
